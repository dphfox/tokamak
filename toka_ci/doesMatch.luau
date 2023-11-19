--!strict
--Licensed from @dphfox/tokamak under MIT

local function doesMatch(
	x: any, 
	y: any
): boolean
	local type = typeof(x)
	if type ~= "table" then
		return x == y
	elseif typeof(y) ~= "table" then
		return false
	end
	for k, v in x do
		if not doesMatch(v, y[k]) then
			return false
		end
	end
	for k, v in y do
		if not doesMatch(v, x[k]) then
			return false
		end
	end
	return true
end

return doesMatch