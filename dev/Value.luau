--!strict
--Licensed from @dphfox/tokamak under MIT

local noop = require("noop")
local GraphObject = require("GraphObject")
local Types = require("Types")

local methods = {}
local methods_mt = {__index = methods}

local function Value<W>(props: {
	name: string,
	initialValue: W
}): Types.Value<W, W>
	return setmetatable({
		type = "StateObject",
		name = props.name,
		graph = GraphObject {
			name = props.name,
			validator = noop
		},
		value = props.initialValue
	}, methods_mt) :: any
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
	self.value = newValue
end

function methods.destroy<R, W>(
	self: Types.Value<R, W>
)
	self.graph:destroy()
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("Value")

	test("constructor - returns correct data structure", function(prove: (any) -> any)
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

		prove(thing.graph.type == "GraphObject").holds()

		thing:destroy()
	end)

	test(":peek() - returns initial value", function(prove: (any) -> any)
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}

		prove(thing:peek() == 5).holds()

		thing:destroy()
	end)

	test(":set() - changes the value returned by :peek()", function(prove: (any) -> any)
		local thing = Value {
			name = "Emily",
			initialValue = 5
		}

		thing:set(25)
		prove(thing:peek() == 25).holds()

		thing:destroy()
	end)

	test(":destroy() - destroys the graph object", function(prove: (any) -> any)
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

return GraphObject