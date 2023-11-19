--!strict
--Licensed from @dphfox/tokamak under MIT

local doesMatch = require("doesMatch")

local function prove(
	x: any
)
	local message = `Did not prove line {debug.info(2, "l")}`
	return {
		holds = function()
			assert(x == true, message)
		end,
		matches = function(y: any)
			assert(doesMatch(x, y), message)
		end

	}
end

return prove