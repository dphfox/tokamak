--!strict
--Licensed from @dphfox/tokamak under MIT

local doesMatch = require("doesMatch")

local function prove(
	x: any
)
	return {
		holds = function()
			assert(x == true, "Proof did not hold true")
		end,
		matches = function(
			y: any
		)
			assert(doesMatch(x, y), "Structures did not match")
		end,
		throws = function(
			substring: string?
		)
			assert(typeof(x) == "function", "prove().throws() can only be called on a function")
			local didThrow = false
			xpcall(x, function(err)
				didThrow = substring == nil or string.find(err, substring, 1, true) ~= nil
			end)
			assert(didThrow, `Did not throw {substring or "any errors"}`)
		end
	}
end

return prove