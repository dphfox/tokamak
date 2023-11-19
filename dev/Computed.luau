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

	-- https://github.com/dphfox/Fusion/issues/270
	test("new objects downstream of invalid objects don't see inconsistent values", function(
		prove: (any) -> any
	)
		local A = Value {
			name = "A",
			initialValue = false
		}
		local B = Computed {
			name = "B",
			processor = function(use: Types.Use)
				return use(A)
			end
		}
		local didDseeBsayAwasFalse = false
		local C = Computed {
			name = "C",
			processor = function(use: Types.Use)
				if use(A) then
					local D = Computed {
						name = "D",
						processor = function(use: Types.Use): boolean?
							if use(B) == false then
								didDseeBsayAwasFalse = true
							end
							return use(B)
						end
					}
					return use(D)
				end
				return nil
			end
		}

		prove(C:peek() == nil).holds()
		prove(B:peek() == false).holds()
		prove(A:peek() == false).holds()

		A:set(true)

		-- We make sure to validate C first, so its processor function runs
		-- before B's processor function runs. This means D is created before
		-- B has run, exposing the possibility of reading a stale value.
		prove(C:peek() == true).holds()
		prove(B:peek() == true).holds()
		prove(A:peek() == true).holds()

		prove(not didDseeBsayAwasFalse).holds()
	end)
end

return GraphObject