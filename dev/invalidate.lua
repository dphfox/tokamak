--!strict
--Licensed from @dphfox/tokamak under MIT

local GraphObject = require("GraphObject")

local function invalidate(
	upstream: GraphObject.GraphObject
)
	upstream.valid = false
	for _, user in upstream.users do
		invalidate(user)
	end
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("invalidate")

	test("invalidates a single object", function(prove)
		local obj = GraphObject {
			name = "obj"
		}
		obj.valid = true

		invalidate(obj)

		prove(obj.valid == false).holds()
	end)

	test("invalidates downstream objects transitively", function(prove)
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
		
		invalidate(obj)

		prove(downstream1.valid == false).holds()
		prove(downstream2.valid == false).holds()
	end)
end

return invalidate