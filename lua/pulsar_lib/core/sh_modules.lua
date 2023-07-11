PulsarLib = PulsarLib or {}
PulsarLib.Modules = PulsarLib.Modules or setmetatable({
	stored = {}
}, {__index = PulsarLib})

local excludeList = { -- A list of folders that shouldn't be replaced in `include` and `AddCSLuaFile` functions
	["includes"] = true
}

local modules = PulsarLib.Modules
modules.Modules = modules.Modules or {}

function modules:Scan()
	local files, folders = file.Find("pulsar_lib/modules/*", "LUA")

	for k, v in ipairs(files) do
		local name = string.StripExtension(v)

		self.Modules[name] = {
			name = name,
			path = "pulsar_lib/modules/" .. v,
			type = "file"
		}
	end

	for k, v in ipairs(folders) do
		self.Modules[v] = {
			name = v,
			path = "pulsar_lib/modules/" .. v,
			type = "folder"
		}
	end

	PulsarLib.Logging.Info("Scanned modules. Found " .. #files .. " files and " .. #folders .. " folders.")
	return self.Modules
end

function modules:Fetch(module)
	module = self.Modules[module]

	if not module then
		PulsarLib.Logging.Error("Attempted to fetch module that doesn't exist.")
		return
	end

	return module
end

function modules:FetchAll()
	return self.Modules
end

local function updateLuaPaths(str, moduleLuaPath)
	local newStr = ""
	for line in str:gmatch("[^\r\n]+") do
		local match = line:match("^%s*include%((.+)%)") or line:match("^%s*AddCSLuaFile%((.+)%)")
		if match then
			local exclude = false
			for k, _ in pairs(excludeList) do
				if line:find(k) then
					exclude = true
					break
				end
			end

			if not exclude then
				line = line:gsub(match, "\"" .. moduleLuaPath .. "\" .. " .. match)
			end
		end

		newStr = newStr .. line .. "\n"
	end

	return newStr
end

function modules:Load(module)
	module = istable(module) and module or self:Fetch(module)

	PulsarLib.Logging.Info("Loading module: " .. module.name)

	if module.type ~= "folder" then
		PulsarLib:Include(module.path)
	end

	local files, folders = file.Find(module.path .. "/lua/autorun/*", "LUA")


	local moduleLuaPath = module.path .. "/lua/"

	for k, v in pairs(files) do
		local path = module.path .. "/lua/autorun/" .. v
		local fileData = file.Read(path, "LUA")
		local newAutorun = updateLuaPaths(fileData, moduleLuaPath)
		RunString(newAutorun)
		PulsarLib.Logging:Get("Loader").Debug("Loaded shared autorun: " .. path)
	end

	for k, v in pairs(folders) do
		if v == "server" then
			if not SERVER then continue end
			local serverFiles, _ = file.Find(module.path .. "/lua/autorun/server/*", "LUA")

			for k2, v2 in pairs(serverFiles) do
				local path = module.path .. "/lua/autorun/server/" .. v2
				local fileData = file.Read(path, "LUA")
				local newAutorun = updateLuaPaths(fileData, moduleLuaPath)
				RunString(newAutorun)
				PulsarLib.Logging:Get("Loader").Debug("Loaded server autorun: " .. path)
			end
		elseif v == "client" then
			local clientFiles, _ = file.Find(module.path .. "/lua/autorun/client/*", "LUA")

			for k2, v2 in pairs(clientFiles) do
				local path = module.path .. "/lua/autorun/client/" .. v2
				local fileData = file.Read(path, "LUA")
				local newAutorun = updateLuaPaths(fileData, moduleLuaPath)
				RunString(newAutorun)
				PulsarLib.Logging:Get("Loader").Debug("Loaded client autorun: " .. path)
			end
		end
	end
end

function modules:LoadAll()
	for k, v in pairs(self:FetchAll()) do
		self:Load(k)
	end
end

PulsarLib.Modules:Scan()
PulsarLib.Modules:LoadAll()