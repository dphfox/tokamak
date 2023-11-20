--!strict
--Licensed from @dphfox/tokamak under MIT

local Types = require("Types")

type GraphObject = Types.GraphObject

local methods = {}
local methods_mt = {__index = methods}

local function GraphObject(props: {
	name: string,
	validator: () -> ()
}): GraphObject
	local self = {}
	self.type = "GraphObject"
	self.name = props.name
	self.valid = false
	self.lastVisibleDifference = nil
	self.validator = props.validator
	self.using = {} :: {[GraphObject]: true}
	self.users = {} :: {[GraphObject]: true}
	return setmetatable(self, methods_mt) :: any
end

function methods.use(
	self: GraphObject,
	upstream: GraphObject
)
	self.using[upstream] = true
	upstream.users[self] = true
end

function methods.unuseAll(
	self: GraphObject
)
	for using in self.using do
		using.users[self] = nil
	end
	table.clear(self.using)
end

function methods.invalidate(
	self: GraphObject
)
	if self.valid then
		self.valid = false
		for user in self.users do
			user:invalidate()
		end
	end
end

function methods.validate(
	self: GraphObject
)
	if not self.valid then
		local visiblyDifferent = self.validator()
		if visiblyDifferent or self.lastVisibleDifference == nil then
			self.lastVisibleDifference = os.clock()
		end
		self.valid = true
	end
end

function methods.destroy(
	self: GraphObject
)
	assert(next(self.users) == nil, `Object is still in use, so can't be destroyed (ID: destroyedInUse)`)
	self:unuseAll()
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("GraphObject")

	local function alwaysVisiblyDifferent()
		return true
	end

	test("constructor - returns correct data structure", function(
		prove: (any) -> any
	)
		local thing = GraphObject {
			name = "Joseph",
			validator = alwaysVisiblyDifferent
		}

		prove(thing).matches({
			type = "GraphObject",
			name = "Joseph",
			valid = false,
			lastVisibleDifference = nil,
			validator = alwaysVisiblyDifferent,
			users = {},
			using = {}
		}, {
			deepMatchObjects = true
		})

		thing:destroy()
	end)

	test(":use() - connects used objects", function(
		prove: (any) -> any
	)
		local upstream = GraphObject {
			name = "upstream",
			validator = alwaysVisiblyDifferent
		}
		local main = GraphObject {
			name = "main",
			validator = alwaysVisiblyDifferent
		}
		main:use(upstream)

		prove(upstream.users).matches({[main] = true})

		main:destroy()
		upstream:destroy()
	end)

	test(":invalidate() - a single object", function(
		prove: (any) -> any
	)
		local obj = GraphObject {
			name = "obj",
			validator = alwaysVisiblyDifferent
		}
		obj:validate()

		obj:invalidate()

		prove(obj.valid == false).holds()
	end)

	test(":invalidate() - can be called multiple times with no change", function(
		prove: (any) -> any
	)
		local obj = GraphObject {
			name = "obj",
			validator = alwaysVisiblyDifferent
		}
		obj:validate()

		obj:invalidate()
		obj:invalidate()
		obj:invalidate()
		
		prove(obj.valid == false).holds()
	end)

	test(":invalidate() - downstream objects transitively", function(
		prove: (any) -> any
	)
		local obj = GraphObject {
			name = "obj",
			validator = alwaysVisiblyDifferent
		}
		obj:validate()
		local downstream1 = GraphObject {
			name = "downstream1",
			validator = alwaysVisiblyDifferent
		}
		downstream1:validate()
		downstream1:use(obj)
		local downstream2 = GraphObject {
			name = "downstream2",
			validator = alwaysVisiblyDifferent
		}
		downstream2:validate()
		downstream2:use(downstream1)
		
		obj:invalidate()

		prove(downstream1.valid == false).holds()
		prove(downstream2.valid == false).holds()
	end)

	test(":invalidate() - does not stop using upstream objects", function(
		prove: (any) -> any
	)
		local upstream = GraphObject {
			name = "upstream",
			validator = alwaysVisiblyDifferent
		}
		local main = GraphObject {
			name = "main",
			validator = alwaysVisiblyDifferent
		}
		main:use(upstream)
		main:validate()

		main:invalidate()

		prove(main.using).matches({[upstream] = true})
		prove(upstream.users).matches({[main] = true})
	end)

	test(":validate() - performs trivial validation", function(
		prove: (any) -> any
	)
		local called = false
		local obj = GraphObject {
			name = "obj",
			validator = function()
				called = true
			end
		}

		obj:validate()
		
		prove(called).holds()
		prove(obj.valid == true).holds()
	end)

	test(":validate() - can be called multiple times without change", function(
		prove: (any) -> any
	)
		local calledTimes = 0
		local obj = GraphObject {
			name = "obj",
			validator = function()
				calledTimes += 1
			end
		}

		obj:validate()
		obj:validate()
		obj:validate()
		
		prove(calledTimes == 1).holds()
	end)

	test(":validate() - records the last visible difference", function(
		prove: (any) -> any
	)
		local returnVisiblyDifferent = false
		local obj = GraphObject {
			name = "obj",
			validator = function()
				return returnVisiblyDifferent
			end
		}

		-- The first run must always be visibly different, even
		-- if the validator returns otherwise.
		local previousTime = obj.lastVisibleDifference
		obj:validate()
		prove(obj.lastVisibleDifference ~= previousTime).holds()

		previousTime = obj.lastVisibleDifference
		obj:invalidate()
		obj:validate()
		prove(obj.lastVisibleDifference == previousTime).holds()

		previousTime = obj.lastVisibleDifference
		returnVisiblyDifferent = true
		obj:invalidate()
		obj:validate()
		prove(obj.lastVisibleDifference > previousTime).holds()
	end)

	test(":unuseAll() - unuses all used objects", function(
		prove: (any) -> any
	)
		local upstream1 = GraphObject {
			name = "upstream1",
			validator = alwaysVisiblyDifferent
		}
		local upstream2 = GraphObject {
			name = "upstream2",
			validator = alwaysVisiblyDifferent
		}
		local upstream3 = GraphObject {
			name = "upstream3",
			validator = alwaysVisiblyDifferent
		}
		local main = GraphObject {
			name = "main",
			validator = alwaysVisiblyDifferent
		}
		main:use(upstream1)
		main:use(upstream2)
		main:use(upstream3)
		main:unuseAll()

		prove(upstream1.users).matches({})
		prove(upstream2.users).matches({})
		prove(upstream3.users).matches({})
		prove(main.using).matches({})

		main:destroy()
		upstream1:destroy()
		upstream2:destroy()
		upstream3:destroy()
	end)

	test(":destroy() - calls :unuseAll()", function(
		prove: (any) -> any
	)
		local upstream1 = GraphObject {
			name = "upstream1",
			validator = alwaysVisiblyDifferent
		}
		local upstream2 = GraphObject {
			name = "upstream2",
			validator = alwaysVisiblyDifferent
		}
		local upstream3 = GraphObject {
			name = "upstream3",
			validator = alwaysVisiblyDifferent
		}
		local main = GraphObject {
			name = "main",
			validator = alwaysVisiblyDifferent
		}
		main:use(upstream1)
		main:use(upstream2)
		main:use(upstream3)
		main:destroy()

		prove(upstream1.users).matches({})
		prove(upstream2.users).matches({})
		prove(upstream3.users).matches({})

		upstream1:destroy()
		upstream2:destroy()
		upstream3:destroy()
	end)

	test(":destroy() - fails when users still present", function(
		prove: (any) -> any
	)
		local main = GraphObject {
			name = "main",
			validator = alwaysVisiblyDifferent
		}
		local downstream = GraphObject {
			name = "downstream",
			validator = alwaysVisiblyDifferent
		}
		downstream:use(main)
		
		prove(function()
			main:destroy()
		end).throws("destroyedInUse")
		
		downstream:destroy()
		main:destroy()
	end)
end

return GraphObject