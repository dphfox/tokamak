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
		using = {},
		users = {}
	}, methods_mt)
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
			using = {},
			users = {}
		})
	end)

	test(":destroy() - disconnects used objects", function(prove)
		local upstream = GraphObject {
			name = "upstream"
		}
		local main = GraphObject {
			name = "main"
		}
		table.insert(upstream.users, main)
		table.insert(main.using, upstream)
		main:destroy()

		prove(main.using).matches({})
		prove(upstream.users).matches({})
	end)

	test(":destroy() - fails when users still present", function(prove)
		local main = GraphObject {
			name = "main"
		}
		local downstream = GraphObject {
			name = "downstream"
		}
		table.insert(main.users, downstream)
		table.insert(downstream.using, main)
		
		prove(function()
			main:destroy()
		end).throws("destroyedInUse")
		downstream:destroy()
		main:destroy()
	end)
end

return GraphObject