--!strict
--Licensed from @dphfox/tokamak under MIT

if not _G.BUNDLE then
	_G.TokaCI = require("../toka_ci")
end

local Tokamak = {
	GraphObject = require("GraphObject"),
	Value = require("Value"),
	Computed = require("Computed")
}

if not _G.BUNDLE then
	local test = _G.TokaCI.group("Integration testing")
	local Types = require("Types")

	-- https://github.com/dphfox/Fusion/issues/270
	test("new objects downstream of invalid objects don't see inconsistent values", function(
		prove: (any) -> any
	)
		local A = Tokamak.Value {
			name = "A",
			initialValue = false
		}
		local B = Tokamak.Computed {
			name = "B",
			processor = function(use: Types.Use)
				return use(A)
			end
		}
		local didDseeBsayAwasFalse = false
		local C = Tokamak.Computed {
			name = "C",
			processor = function(use: Types.Use)
				if use(A) then
					local D = Tokamak.Computed {
						name = "D",
						processor = function(use: Types.Use): boolean?
							if use(B) == false then
								didDseeBsayAwasFalse = true
							end
							return use(B)
						end
					}
					return use(D)
				end
				return nil
			end
		}

		prove(C:peek() == nil).holds()
		prove(B:peek() == false).holds()
		prove(A:peek() == false).holds()

		prove(B.graph.valid).holds()
		prove(C.graph.valid).holds()

		A:set(true)

		prove(not B.graph.valid).holds()
		prove(not C.graph.valid).holds()

		-- We make sure to validate C first, so its processor function runs
		-- before B's processor function runs. This means D is created before
		-- B has run, exposing the possibility of reading a stale value.
		prove(C:peek() == true).holds()
		prove(B:peek() == true).holds()
		prove(A:peek() == true).holds()

		prove(not didDseeBsayAwasFalse).holds()
	end)

	_G.TokaCI.present()
end

return Tokamak