local json = require("lib.json")

local defaults = require("settingsDefaults")
local util = require("util")

local path = "settings.json"

local settings = {}

local settingsFunctions = {}

function settingsFunctions.resetAll()
	for sectionName, sectionSettings in pairs(defaults) do
		settings[sectionName] = sectionSettings
	end
end

local function copy(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = v
	end
	return r
end

function settingsFunctions.resetSection(name)
	settings[name] = copy(defaults[name])
end

function settingsFunctions.resetSingle(name, name2)
	settings[name][name2] = defaults[name][name2]
end

function settingsFunctions.load()
	local str = love.filesystem.read(path)
	if not str then
		settingsFunctions.resetAll()
		return
	end

	local decoded = util.safeJsonDecode(str)
	if not decoded then
		settingsFunctions.resetAll()
		return
	end

	-- settings (the table returned from this file) will have been saved locally
	-- but assume no code will have saved any values from that table.
	-- I.e. all code must write settings.foo.bar when getting.

	for k, v in pairs(defaults) do
		if not decoded[k] then
			settings[k] = copy(v)
			goto continue
		else
			settings[k] = {}
		end

		for k2, v2 in pairs(v) do
			local val = decoded[k][k2]
			if val == nil then
				val = v2
			end
			settings[k][k2] = val
		end

	    ::continue::
	end
end

function settingsFunctions.save()
	love.filesystem.write(path, json.encode(settings))
end

-- E.g. settings("load")
-- To avoid iterating over such functions
return setmetatable(settings, {
	__call = function(_, name, ...)
		return settingsFunctions[name](...)
	end
})
