--!strict
--Licensed from @dphfox/tokamak under MIT

export type Options = {
	deepMatchObjects: boolean?
}

local function doesMatch(
	x: any, 
	y: any,
	options: Options
): boolean
	local type = typeof(x)
	if type ~= "table" then
		return x == y
	elseif typeof(y) ~= "table" then
		return false
	-- If something has a metatable, assume it is an object and fall back to
	-- shallow equality.
	elseif not options.deepMatchObjects and getmetatable(x) ~= nil then
		return x == y
	end
	for k, v in x do
		if not doesMatch(v, y[k], options) then
			return false
		end
	end
	for k, v in y do
		if not doesMatch(v, x[k], options) then
			return false
		end
	end
	return true
end

return doesMatch