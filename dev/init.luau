--!strict
--Licensed from @dphfox/tokamak under MIT

if not _G.BUNDLE then
	_G.TokaCI = require("../toka_ci")
end

local Tokamak = {
	GraphObject = require("./GraphObject")
}

if not _G.BUNDLE then
	_G.TokaCI.present()
end

return Tokamak