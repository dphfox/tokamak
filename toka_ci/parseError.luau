--!strict
--Licensed from @dphfox/tokamak under MIT

local process = require("@lune/process")

export type Error = {
	type: "Error",
	raw: string,
	message: string,
	trace: string,
	source: string,
	lineNum: number
}

local function parseError(err: string): Error
	local trace = debug.traceback(nil, 5)
	trace = string.gsub(trace, `%[string "(.-)"%]`, "%1")
	-- TODO: what if `process.cwd` has regex chars?
	trace = string.gsub(trace, process.cwd, "")
	trace = string.gsub(trace, "%s+$", "")
	
	local source, lineNum = debug.info(5, "sl")
	return {
		type = "Error",
		raw = err,
		message = string.gsub(err, "^.+:%d+:%s*", ""),
		trace = trace,
		source = source,
		lineNum = lineNum
	}
end

return parseError