--!strict
--Licensed from @dphfox/tokamak under MIT

local process = require("@lune/process")

export type Error = {
	type: "Error",
	raw: string,
	message: string,
	trace: string
}

local function parseError(err: string): Error
	local trace = debug.traceback(nil, 5)
	trace = string.gsub(trace, `%[string "{process.cwd}(.-)"%]`, "%1")
	trace = string.gsub(trace, "%s+$", "")
	return {
		type = "Error",
		raw = err,
		message = string.gsub(err, "^.+:%d+:%s*", ""),
		trace = trace
	}
end

return parseError