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
	print("destroying", self.name)
end

if not _G.BUNDLE then
	local try = _G.TokaCI.test("GraphObject")

	try("constructor", function(prove)
		local thing = GraphObject {
			name = "Joseph"
		}

		prove(thing).matches({
			type = "GraphObject",
			name = "Josepddh",
			using = {},
			users = {}
		})
	end)
end

return GraphObject