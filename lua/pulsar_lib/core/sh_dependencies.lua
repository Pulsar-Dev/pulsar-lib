PulsarLib = PulsarLib or {}
PulsarLib.Dependency = PulsarLib.Dependency or setmetatable({
	stored = {}
}, {__index = PulsarLib})

PulsarLib.Dependency.Failed = {
	Modules = {},
	Addons = {}
}


function PulsarLib.Dependency.Loaded(dependency)
	PulsarLib.Logging:Debug("Dependency loaded: ", PulsarLib.Logging:Highlight(dependency))
	if not PulsarLib.Addons or not PulsarLib.Addons.WaitingForDeps then return end
	for k, v in pairs(PulsarLib.Addons.WaitingForDeps) do
		for k2, v2 in pairs(v.Dependencies) do
			if k2 == dependency then
				PulsarLib.Addons.WaitingForDeps[k2] = nil

				v:Load()
			end
		end
	end
end

function PulsarLib.Dependency.VariableExists(var)
	if not var then return false end
	local parts = {}
	for part in string.gmatch(var, "([^%.]+)") do
		table.insert(parts, part)
	end

	local result = _G
	for _, part in ipairs(parts) do
		result = result[part]
	end

	return result or false
end

hook.Add("PlayerFullLoad", "PulsarLib.WarnOwners", function(ply)
	if not ply:IsSuperAdmin() then return end
	for k, v in pairs(PulsarLib.Dependency.Failed) do
		for k2, v2 in pairs(v) do
			PulsarLib.Notify(ply, v2.Client or "An unknown PulsarLib Addon/Module has failed to load. Check server console for more information", 60)
		end
	end
end)

concommand.Add("pulsarlib_dumperrors", function(ply, cmd)
	if not ply and not ply:IsSuperAdmin() then return end

	local logger = PulsarLib.Logging
	local installedAddons
	local installedModules
	local externalWorkshopAddons
	local externalFolderAddons
	local defaultSourceAddons = {-- A table full of addons that for some reason come packed in source engine
		["checkers"] = true,
		["chess"] = true,
		["common"] = true,
		["go"] = true,
		["hearts"] = true,
		["spades"] = true,
	}


	for i = 1, #PulsarLib.Addons.Registered do
		installedAddons = (installedAddons or "") .. PulsarLib.Addons.Registered[i] .. (PulsarLib.Addons.Registered[i + 1] and ", " or "")
	end

	for i = 1, #PulsarLib.Modules.Registered do
		installedModules = (installedModules or "") .. PulsarLib.Modules.Registered[i] .. (PulsarLib.Modules.Registered[i + 1] and ", " or "")
	end

	local engineAddons = engine.GetAddons()
	for i = 1, #engineAddons do
		local addon = engineAddons[i]
		if addon.mounted and addon.wsid ~= "0" then
			externalWorkshopAddons = (externalWorkshopAddons or "") .. addon.title .. " (" .. addon.wsid .. ")" .. (engineAddons[i + 1] and ", " or "")
		end
	end

	local _, folderAddons = file.Find("addons/*", "GAME")
	for i = 1, #folderAddons do
		local addon = folderAddons[i]
		if not defaultSourceAddons[addon] then
			externalFolderAddons = (externalFolderAddons or "") .. addon .. (folderAddons[i + 1] and ", " or "")
		end
	end

	logger:Critical("PulsarLib Dependency Errors:")
	logger:Critical("	Addons: ")
	for k, v in pairs(PulsarLib.Dependency.Failed.Addons) do
		logger:Critical("		" .. k .. " - " .. v.Server)
	end
	logger:Critical("	Modules: ")
	for k, v in pairs(PulsarLib.Dependency.Failed.Modules) do
		logger:Critical("		" .. k .. " - " .. v.Server)
	end
	logger:Critical("-----------------------------")
	logger:Critical("PulsarLib addons installed to server:")
	logger:Critical(installedAddons or "----none")
	logger:Critical("-----------------------------")
	logger:Critical("PulsarLib modules installed to server:")
	logger:Critical(installedModules or "----none")
	logger:Critical("-----------------------------")
	logger:Critical("External workshop addons:")
	logger:Critical(externalWorkshopAddons)
	logger:Critical("-----------------------------")
	logger:Critical("External folder addons:")
	logger:Critical(externalFolderAddons)
end)