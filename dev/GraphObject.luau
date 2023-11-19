--!strict
--Licensed from @dphfox/tokamak under MIT

local methods = {}
local methods_mt = {__index = methods}

local function GraphObject(props: {
	name: string
})
	return setmetatable({
		type = "GraphObject",
		name = props.name,
		valid = false,
		using = {} :: {GraphObject},
		users = {} :: {GraphObject}
	}, methods_mt)
end

export type GraphObject = typeof(GraphObject({ name = "" }))

function methods:use(
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

function methods:invalidate()
	self.valid = false
	for _, user in self.users do
		user:invalidate()
	end
end

function methods:destroy()
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
		local thing = GraphObject {
			name = "Joseph"
		}

		prove(thing).matches({
			type = "GraphObject",
			name = "Joseph",
			valid = false,
			using = {},
			users = {}
		}, {
			deepMatchObjects = true
		})

		thing:destroy()
	end)

	test(":use() - connects used objects", function(prove)
		local upstream = GraphObject {
			name = "upstream"
		}
		local main = GraphObject {
			name = "main"
		}
		main:use(upstream)

		prove(main.using).matches({upstream})
		prove(upstream.users).matches({main})

		main:destroy()
		upstream:destroy()
	end)

	test(":invalidate() - a single object", function(prove)
		local obj = GraphObject {
			name = "obj"
		}
		obj.valid = true

		obj:invalidate()

		prove(obj.valid == false).holds()
	end)

	test(":invalidate() - downstream objects transitively", function(prove)
		local obj = GraphObject {
			name = "obj"
		}
		obj.valid = true
		local downstream1 = GraphObject {
			name = "downstream1"
		}
		downstream1.valid = true
		downstream1:use(obj)
		local downstream2 = GraphObject {
			name = "downstream2"
		}
		downstream2.valid = true
		downstream2:use(downstream1)
		
		obj:invalidate()

		prove(downstream1.valid == false).holds()
		prove(downstream2.valid == false).holds()
	end)

	test(":destroy() - disconnects used objects", function(prove)
		local upstream = GraphObject {
			name = "upstream"
		}
		local main = GraphObject {
			name = "main"
		}
		main:use(upstream)
		main:destroy()

		prove(main.using).matches({})
		prove(upstream.users).matches({})

		main:destroy()
		upstream:destroy()
	end)

	test(":destroy() - fails when users still present", function(prove)
		local main = GraphObject {
			name = "main"
		}
		local downstream = GraphObject {
			name = "downstream"
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