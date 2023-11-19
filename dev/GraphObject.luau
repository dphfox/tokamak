--!strict
--Licensed from @dphfox/tokamak under MIT

local methods = {}
local methods_mt = {__index = methods}

local function GraphObject(props: {
	name: string,
	validator: () -> ()
})
	return setmetatable({
		type = "GraphObject",
		props = props,
		valid = false,
		using = {} :: {GraphObject},
		users = {} :: {GraphObject}
	}, methods_mt)
end

export type GraphObject = typeof(GraphObject({
	name = "",
	validator = function() end
}))

function methods.use(
	self: GraphObject,
	upstream: GraphObject
)
	-- This check is excluded from the bundle because it would introduce linear
	-- complexity to what should be a constant-time option, but it is still
	-- useful to catch double-adds during development.
	if not _G.BUNDLE then
		assert(table.find(self.using, upstream) == nil, "Cannot use the same graph object twice (ID: objectUsedTwice)")
		assert(table.find(upstream.users, self) == nil, "Cannot use the same graph object twice (ID: objectUsedTwice)")
	end
	table.insert(self.using, upstream)
	table.insert(upstream.users, self)
end

function methods.invalidate(
	self: GraphObject
)
	if self.valid then
		self.valid = false
		for _, using in self.using do
			local index = table.find(using.users, self)
			if index ~= nil then
				table.remove(using.users, index)
			end
		end
		table.clear(self.using)
		for _, user in self.users do
			user:invalidate()
		end
	end
end

function methods.validate(
	self: GraphObject
)
	if not self.valid then
		self.props.validator()
		self.valid = true
	end
end

function methods.destroy(
	self: GraphObject
)
	assert(#self.users == 0, `Object is still in use by {#self.users} others, so can't be destroyed (ID: destroyedInUse)`)
	for _, using in self.using do
		local index = table.find(using.users, self)
		if index ~= nil then
			table.remove(using.users, index)
		end
	end
	table.clear(self.using)
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("GraphObject")

	test("constructor - returns correct data structure", function(prove)
		local function validator()
			-- do nothing, intentionally
		end

		local thing = GraphObject {
			name = "Joseph",
			validator = validator
		}

		prove(thing).matches({
			type = "GraphObject",
			props = {
				name = "Joseph",
				validator = validator
			},
			valid = false,
			users = {},
			using = {}
		}, {
			deepMatchObjects = true
		})

		thing:destroy()
	end)

	test(":use() - connects used objects", function(prove)
		local upstream = GraphObject {
			name = "upstream",
			validator = function() end
		}
		local main = GraphObject {
			name = "main",
			validator = function() end
		}
		main:use(upstream)

		prove(upstream.users).matches({main})

		main:destroy()
		upstream:destroy()
	end)

	test(":invalidate() - a single object", function(prove)
		local obj = GraphObject {
			name = "obj",
			validator = function() end
		}
		obj:validate()

		obj:invalidate()

		prove(obj.valid == false).holds()
	end)

	test(":invalidate() - can be called multiple times with no change", function(prove)
		local obj = GraphObject {
			name = "obj",
			validator = function() end
		}
		obj:validate()

		obj:invalidate()
		obj:invalidate()
		obj:invalidate()
		
		prove(obj.valid == false).holds()
	end)

	test(":invalidate() - downstream objects transitively", function(prove)
		local obj = GraphObject {
			name = "obj",
			validator = function() end
		}
		obj:validate()
		local downstream1 = GraphObject {
			name = "downstream1",
			validator = function() end
		}
		downstream1:validate()
		downstream1:use(obj)
		local downstream2 = GraphObject {
			name = "downstream2",
			validator = function() end
		}
		downstream2:validate()
		downstream2:use(downstream1)
		
		obj:invalidate()

		prove(downstream1.valid == false).holds()
		prove(downstream2.valid == false).holds()
	end)

	test(":invalidate() - stops using upstream objects", function(prove)
		local upstream = GraphObject {
			name = "upstream",
			validator = function() end
		}
		local main = GraphObject {
			name = "main",
			validator = function() end
		}
		main:use(upstream)
		main:validate()

		main:invalidate()

		prove(main.using).matches({})
		prove(upstream.users).matches({})
	end)

	test(":validate() - calls the validator function", function(prove)
		local called = false
		local obj = GraphObject {
			name = "obj",
			validator = function()
				called = true
			end
		}

		obj:validate()
		
		prove(called).holds()
	end)

	test(":validate() - can be called multiple times without change", function(prove)
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

	test(":destroy() - disconnects used objects", function(prove)
		local upstream = GraphObject {
			name = "upstream",
			validator = function() end
		}
		local main = GraphObject {
			name = "main",
			validator = function() end
		}
		main:use(upstream)
		main:destroy()

		prove(upstream.users).matches({})

		main:destroy()
		upstream:destroy()
	end)

	test(":destroy() - fails when users still present", function(prove)
		local main = GraphObject {
			name = "main",
			validator = function() end
		}
		local downstream = GraphObject {
			name = "downstream",
			validator = function() end
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