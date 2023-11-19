--!strict
--Licensed from @dphfox/tokamak under MIT

local noop = require("noop")
local isSimilar = require("isSimilar")
local GraphObject = require("GraphObject")
local Types = require("Types")

local methods = {}
local methods_mt = {__index = methods}

local function Value<W>(props: {
	name: string,
	initialValue: W
}): Types.Value<W, W>
	local self = {}
	self.type = "StateObject"
	self.name = props.name
	self.graph = GraphObject {
		name = props.name,
		validator = noop
	}
	-- Because value objects never have dependencies, they're always valid and
	-- should never be left invalid after any operation, becaues their value is
	-- always well known.
	self.graph:validate()
	self.value = props.initialValue
	return setmetatable(self, methods_mt) :: any
end

function methods.peek<R, W>(
	self: Types.Value<R, W>
): R | W
	return self.value
end

function methods.set<R, W>(
	self: Types.Value<R, W>,
	newValue: W
)
	if isSimilar(self.value, newValue) then
		return
	end
	self.value = newValue
	-- This invalidates transitively down, but then restores our own valid
	-- status, because value objects aren't ever invalid.
	self.graph:invalidate()
	self.graph:validate()
end

function methods.destroy<R, W>(
	self: Types.Value<R, W>
)
	self.graph:destroy()
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("Value")

	test("constructor - returns correct data structure", function(
		prove: (any) -> any
	)
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}

		prove(thing).matches({
			type = "StateObject",
			name = "Emily",
			graph = thing.graph,
			value = 5
		}, {
			deepMatchObjects = true
		})

		prove(typeof(thing.graph) == "table").holds()
		prove(thing.graph.type == "GraphObject").holds()

		thing:destroy()
	end)

	test(":peek() - returns initial value", function(
		prove: (any) -> any
	)
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}

		prove(thing:peek() == 5).holds()

		thing:destroy()
	end)

	test(":set() - changes the value returned by :peek()", function(
		prove: (any) -> any
	)
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}

		thing:set(25)
		prove(thing:peek() == 25).holds()

		thing:destroy()
	end)

	test(":set() - invalidates downstream", function(
		prove: (any) -> any
	)
		local main = Value {
			name = "Emily",
			initialValue = 5
		}
		local downstream = GraphObject {
			name = "downstream",
			validator = function() end
		}
		downstream:use(main.graph)
		downstream:validate()

		main:set(25)
		prove(not downstream.valid).holds()

		downstream:destroy()
		main:destroy()
	end)

	test(":set() - does not invalidate given a similar value", function(
		prove: (any) -> any
	)
		local main = Value {
			name = "Emily",
			initialValue = 5
		}
		local downstream = GraphObject {
			name = "downstream",
			validator = function() end
		}
		downstream:use(main.graph)
		downstream:validate()

		main:set(5)
		prove(downstream.valid).holds()

		downstream:destroy()
		main:destroy()
	end)

	test(":destroy() - destroys the graph object", function(
		prove: (any) -> any
	)
		local upstream = GraphObject {
			name = "upstream",
			validator = function() end
		}
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}
		thing.graph:use(upstream)
		thing:destroy()

		prove(upstream.users).matches({})

		upstream:destroy()
	end)
end

return Value