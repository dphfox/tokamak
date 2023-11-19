--!strict
--Licensed from @dphfox/tokamak under MIT

local process = require("@lune/process")
local fs = require("@lune/fs")

if process.args[1] == nil then
	error("Argument 1 should configure the type of build.")
end

local buildType = process.args[1]
local darkluaConfig = `darklua_{buildType}.json`
assert(fs.isFile(darkluaConfig), `{buildType} is not a recognised type of build.`)

local srcDir = "dev"
local outDir = `out/{buildType}`

print(`Clearing out old build at {outDir}...`)
pcall(fs.removeDir, outDir)

do
	print(`Performing build with {darkluaConfig}...`)
	local result = process.spawn(
		"darklua", 
		{
			"process", `{srcDir}/init.luau`, `{outDir}/init.luau`,
			"--config", darkluaConfig
		},
		{
			stdio = "forward"
		}
	)
	assert(result.ok, "Build unsuccessful - aborting.")
end