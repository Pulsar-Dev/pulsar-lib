PulsarLib = PulsarLib or {}
PulsarLib.Modules = PulsarLib.Modules or {}
PulsarLib.Modules.Modules = PulsarLib.Modules.Modules or {}

function PulsarLib.Modules.Scan()
    local files, folders = file.Find("pulsar_lib/modules/*", "LUA")

    for k, v in ipairs(files) do
        local name = string.StripExtension(v)

        PulsarLib.Modules.Modules[name] = {
            name = name,
            path = "pulsar_lib/modules/" .. v,
            type = "file"
        }
    end

    for k, v in ipairs(folders) do
        PulsarLib.Modules.Modules[v] = {
            name = v,
            path = "pulsar_lib/modules/" .. v,
            type = "folder"
        }
    end
end

function PulsarLib.Modules.Fetch(module)
    return PulsarLib.Modules.Modules[module] or nil
end

local excludeList = {
    ["includes"] = true
}

local function replaceIncludes(str, moduleLuaPath)
    local newStr = ""
    for line in str:gmatch("[^\r\n]+") do
        local includeMatch = line:match("^%s*include%((.+)%)")
        if includeMatch then
            local exclude = false
            for k, _ in pairs(excludeList) do
                if line:find(k) then
                    exclude = true
                    break
                end
            end

            if not exclude then
                line = line:gsub(includeMatch, "\"" .. moduleLuaPath .. "\" .. " .. includeMatch)
            end
        end

        local AddCSLuaFileMatch = line:match("^%s*AddCSLuaFile%((.+)%)")
        if AddCSLuaFileMatch then
            local exclude = false
            for k, _ in pairs(excludeList) do
                if line:find(k) then
                    exclude = true
                    break
                end
            end

            if not exclude then
                line = line:gsub(AddCSLuaFileMatch, "\"" .. moduleLuaPath .. "\" .. " .. AddCSLuaFileMatch)
            end
        end

        newStr = newStr .. line .. "\n"
    end

    return newStr
end

function PulsarLib.Modules.Load(module)
    PulsarLib.Logging.Info("Loading module: " .. module.name)
    if module.type ~= "folder" then
        PulsarLib:Include(module.path)
    end

    local files, folders = file.Find(module.path .. "/lua/autorun/*", "LUA")
    local autoruns = {}
    autoruns.Server = {}
    autoruns.Client = {}
    autoruns.Shared = {}

    for k, v in pairs(files) do
        local path = module.path .. "/lua/autorun/" .. v
        autoruns.Shared[v] = path
    end

    for k, v in pairs(folders) do
        if v == "server" then
            local serverFiles, _ = file.Find(module.path .. "/lua/autorun/server/*", "LUA")

            for k2, v2 in pairs(serverFiles) do
                local path = module.path .. "/lua/autorun/server/" .. v2
                autoruns.Server[v2] = path
            end
        elseif v == "client" then
            local clientFiles, _ = file.Find(module.path .. "/lua/autorun/client/*", "LUA")

            for k2, v2 in pairs(clientFiles) do
                local path = module.path .. "/lua/autorun/client/" .. v2
                autoruns.Client[v2] = path
            end
        end
    end

    local moduleLuaPath = module.path .. "/lua/"

    for k, v in pairs(autoruns.Shared) do
        local fileData = file.Read(v, "LUA")
        local newAutorun = replaceIncludes(fileData, moduleLuaPath)
        RunString(newAutorun)
        PulsarLib.Logging:Get("Loader").Debug("Loaded shared autorun: " .. v)
    end

    for k, v in pairs(autoruns.Server) do
        if not SERVER then return end
        local fileData = file.Read(v, "LUA")
        local newAutorun = replaceIncludes(fileData, moduleLuaPath)
        RunString(newAutorun)
        PulsarLib.Logging:Get("Loader").Debug("Loaded server autorun: " .. v)
    end

    for k, v in pairs(autoruns.Client) do
        local fileData = file.Read(v, "LUA")
        local newAutorun = replaceIncludes(fileData, moduleLuaPath)
        RunString(newAutorun)
        PulsarLib.Logging:Get("Loader").Debug("Loaded client autorun: " .. v)
    end

end

function PulsarLib.Modules.LoadAll()
    for k, v in pairs(PulsarLib.Modules.Modules) do
        PulsarLib.Modules.Load(v)
    end
end

PulsarLib.Modules.Scan()
PulsarLib.Modules.LoadAll()