--!strict
--Licensed from @dphfox/tokamak under MIT

local TokaCI = {}

local prove = require("prove")
local parseError = require("parseError")

local testResults = {}

function TokaCI.test(
	group: string
)
	return function(
		title: string,
		attemptor: (prove: typeof(prove)) -> ()
	)
		local testInfo = {
			title = title,
			ok = true
		}
		xpcall(attemptor, function(raw)
			local err = parseError(raw)
			print("Oopsie!", err.message)
		end, prove)
	end
end

function TokaCI.present()
	print("some tests were done!")
end

return TokaCI