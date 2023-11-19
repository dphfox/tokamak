--!strict
--Licensed from @dphfox/tokamak under MIT

export type Error = {
	type: "Error",
	raw: string,
	message: string,
	trace: string
}

local function parseError(err: string)
	return {
		type = "Error",
		raw = err,
		message = string.gsub(err, "^.+:%d+:%s*", ""),
		trace = debug.traceback(nil, 2)
	}
end

return parseError