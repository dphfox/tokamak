--!strict
--Licensed from @dphfox/tokamak under MIT

local doesMatch = require("doesMatch")

local incompleteProve = false

local function prove(
	x: any
)
	if incompleteProve then
		incompleteProve = false
		error("The last prove() call was incomplete.")
	end
	incompleteProve = true
	return {
		holds = function()
			incompleteProve = false
			assert(x == true, "Proof did not hold true")
		end,
		matches = function(
			y: any,
			options: doesMatch.Options?
		)
			incompleteProve = false
			assert(doesMatch(x, y, options or {}), "Structures did not match")
		end,
		throws = function(
			substring: string?
		)
			incompleteProve = false
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