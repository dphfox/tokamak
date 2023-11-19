--!strict
--Licensed from @dphfox/tokamak under MIT

local fs = require("@lune/fs")

local parseError = require("parseError")

local function getLineSource(
	err: parseError.Error
): string?
	local lineContent: string? = nil
	pcall(function()
		-- HACK: this is all very fragile
		local file = string.gsub(err.source, `%[string "(.-)"%]`, "%1")
		if string.lower(string.sub(file, -5, -1)) ~= ".luau" then
			file ..= ".luau"
		end
		local fileContent = fs.readFile(file)
		lineContent = string.split(fileContent, "\n")[err.lineNum]
	end)
	return lineContent
end

return getLineSource