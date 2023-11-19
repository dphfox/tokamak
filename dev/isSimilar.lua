--!strict
--Licensed from @dphfox/tokamak under MIT

local function isSimilar(x: any, y: any): boolean
	local type = typeof(x)
	if typeof(y) ~= type then
		return false
	elseif x ~= x and y ~= y then
		return true
	elseif type == "table" then
		return false
	else
		return x == y
	end
end

if not _G.BUNDLE then
	local test = _G.TokaCI.group("isSimilar")
	
	test("equality for primitive types", function(
		prove: (any) -> any
	)
		prove(isSimilar(1, 1)).holds()
		prove(isSimilar("hello", "hello")).holds()
		prove(isSimilar(true, true)).holds()
		prove(isSimilar(nil, nil)).holds()
		
		prove(not isSimilar(1, 10)).holds()
		prove(not isSimilar("hello", "world")).holds()
		prove(not isSimilar(true, false)).holds()
		prove(not isSimilar(nil, 2)).holds()
	end)

	test("never true for table types", function(
		prove: (any) -> any
	)
		prove(not isSimilar({}, {})).holds()
		prove(not isSimilar({1, 2, 3}, {1, 2, 3})).holds()
		prove(not isSimilar({1}, {})).holds()
	end)

	test("always true for NaN", function(
		prove: (any) -> any
	)
		prove(isSimilar(0/0, 0/0)).holds()
	end)
end

return isSimilar