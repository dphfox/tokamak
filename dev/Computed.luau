--!strict
--Licensed from @dphfox/tokamak under MIT

local GraphObject = require("GraphObject")
local Types = require("Types")

local methods = {}
local methods_mt = {__index = methods}

local function Computed<T>(props: {
	name: string,
	processor: (Types.Use) -> T
}): Types.Computed<T>
	local self = {}
	self.type = "StateObject"
	self.name = props.name
	self.graph = GraphObject {
		name = props.name,
		validator = function()
			-- Because this validator and the use callback function cyclically
			-- depend on each other, this doesn't type check, so we skip the
			-- checks here and manually guarantee they exist.
			local processor = (self :: any).processor
			local useCallback = (self :: any).useCallback
			self.cachedValue = processor(useCallback)
		end
	}
	self.processor = props.processor
	self.cachedValue = nil :: T?
	self.useCallback = function<T>(
		maybeState: Types.CanBeState<T>
	): T
		if typeof(maybeState) == "table" and maybeState.type == "StateObject" then
			self.graph:use(maybeState.graph)
			return maybeState:peek()
		else
			return maybeState :: T
		end
	end
	return setmetatable(self, methods_mt) :: any
end

function methods.peek<T>(
	self: Types.Computed<T>
): T
	self.graph:validate()
	-- This is inherently unsafe; we are upholding this contract ourselves.
	return self.cachedValue :: T
end

function methods.destroy<R, W>(
	self: Types.Value<R, W>
)
	self.graph:destroy()
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("Computed")
	local Value = require("Value")

	test("constructor - returns correct data structure", function(
		prove: (any) -> any
	)
		local function processor()
			return 5
		end

		local thing = Computed {
			name = "Stephen",
			processor = processor
		}

		prove(thing).matches({
			type = "StateObject",
			name = "Stephen",
			graph = thing.graph,
			processor = processor,
			cachedValue = nil,
			useCallback = thing.useCallback
		}, {
			deepMatchObjects = true
		})

		prove(typeof(thing.graph) == "table").holds()
		prove(thing.graph.type == "GraphObject").holds()

		prove(typeof(thing.useCallback) == "function").holds()

		thing:destroy()
	end)

	test(":peek() - returns value from processor", function(
		prove: (any) -> any
	)
		local thing = Computed {
			name = "Stephen",
			processor = function()
				return 5
			end
		}

		prove(thing:peek() == 5).holds()

		thing:destroy()
	end)

	test(":peek() - provides a peeking function", function(
		prove: (any) -> any
	)
		local upstream = Value {
			name = "Stephen Sr.",
			initialValue = 5
		}
		local main = Computed {
			name = "Stephen",
			processor = function(use: Types.Use)
				return use(upstream)
			end
		}

		prove(main:peek() == 5).holds()

		main:destroy()
		upstream:destroy()
	end)

	test(":peek() - does not process more than once", function(
		prove: (any) -> any
	)
		local count = 0
		local main = Computed {
			name = "Stephen",
			processor = function(_: Types.Use)
				count += 1
				return 5
			end
		}

		main:peek()
		main:peek()
		main:peek()

		prove(count == 1).holds()

		main:destroy()
	end)

	test(":peek() - updates with upstream objects", function(
		prove: (any) -> any
	)
		local upstream = Value {
			name = "Stephen Sr.",
			initialValue = 5
		}
		local main = Computed {
			name = "Stephen",
			processor = function(use: Types.Use)
				return use(upstream)
			end
		}

		prove(main:peek() == 5).holds()
		upstream:set(25)
		prove(main:peek() == 25).holds()

		main:destroy()
		upstream:destroy()
	end)

	test(":peek() - updates downstream objects", function(
		prove: (any) -> any
	)
		local upstream = Value {
			name = "Stephen Sr.",
			initialValue = 5
		}
		local main = Computed {
			name = "Stephen",
			processor = function(use: Types.Use)
				return use(upstream)
			end
		}
		local downstream = Computed {
			name = "Stephen Jr.",
			processor = function(use: Types.Use)
				return use(main)
			end
		}

		prove(downstream:peek() == 5).holds()
		upstream:set(25)
		prove(downstream:peek() == 25).holds()

		downstream:destroy()
		main:destroy()
		upstream:destroy()
	end)

	test(":peek() - doesn't update downstream given similar values", function(
		prove: (any) -> any
	)
		local numRuns = 0
		local upstream = Value {
			name = "Stephen Sr.",
			initialValue = 5
		}
		local main = Computed {
			name = "Stephen",
			processor = function(use: Types.Use)
				return use(upstream) :: any > 0
			end
		}
		local downstream = Computed {
			name = "Stephen Jr.",
			processor = function(use: Types.Use)
				numRuns += 1
				return use(main)
			end
		}

		prove(downstream:peek() == true).holds()
		prove(numRuns == 1).holds()

		upstream:set(25)
		
		prove(downstream:peek() == true).holds()
		prove(numRuns == 1).holds()

		downstream:destroy()
		main:destroy()
		upstream:destroy()
	end)

	test(":destroy() - destroys the graph object", function(
		prove: (any) -> any
	)
		local upstream = GraphObject {
			name = "upstream",
			validator = function() end
		}
		local thing = Computed {
			name = "Stephen",
			processor = function()
				return 5
			end
		}
		thing.graph:use(upstream)
		thing:destroy()

		prove(upstream.users).matches({})

		upstream:destroy()
	end)
end

return Computed