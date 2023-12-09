PulsarLib.Modules = PulsarLib.Modules or {}

local baseURL = "https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master"

function PulsarLib.Modules.DownloadMetadata()
    HTTP({
        url = baseURL .. "/metadata.json",
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write("pulsarlib/modules/metadata.json", body)
                PulsarLib.Logging:Debug("Downloaded metadata")
            else
                PulsarLib.Logging:Error("Failed to download metadata: " .. code)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download metadata: " .. reason)
        end
    })
end

function PulsarLib.Modules.GetMetadata()
    if not file.Exists("pulsarlib/modules/metadata.json", "DATA") then
        PulsarLib.Modules.DownloadMetadata()
        return {}
    end

    local metadata = file.Read("pulsarlib/modules/metadata.json", "DATA")
    if not metadata then
        return {}
    end

    return util.JSONToTable(metadata)
end


function PulsarLib.Modules.DownloadModuleMetaData(name)
    local metadata = PulsarLib.Modules.GetMetadata()

    if not metadata[name] then
        PulsarLib.Logging:Error("Module " .. name .. " does not exist")
        return nil
    end

    if not file.IsDir("pulsarlib/modules/" .. name, "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name)
    end

    local moduleDataURL = baseURL .. metadata[name] .. "/metadata.json"
    HTTP({
        url = moduleDataURL,
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write("pulsarlib/modules/" .. name .. "/metadata.json", body)
                PulsarLib.Logging:Debug("Downloaded module metadata for " .. name)
            else
                print(moduleDataURL)
                PulsarLib.Logging:Error("Failed to download module metadata for " .. name .. ": " .. code)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download module metadata for " .. name .. ": " .. reason)
        end
    })
end

function PulsarLib.Modules.GetModuleMetaData(name)
    if not file.Exists("pulsarlib/modules/" .. name .. "/metadata.json", "DATA") then
        PulsarLib.Modules.DownloadModuleMetaData(name)
        return nil
    end

    local metadata = file.Read("pulsarlib/modules/" .. name .. "/metadata.json", "DATA")
    if not metadata then
        return nil
    end

    return util.JSONToTable(metadata)
end

function PulsarLib.Modules.ModuleExists(name)
    local moduleMetaData = PulsarLib.Modules.GetModuleMetaData(name)
    if not moduleMetaData then
        return false
    end

    return true
end

function PulsarLib.Modules.GetVersionsData(name)
    local moduleMetaData = PulsarLib.Modules.GetModuleMetaData(name)
    if not moduleMetaData then
        return nil
    end

    return moduleMetaData.versions
end

function PulsarLib.Modules.GetLatestVersion(name)
    local versionsData = PulsarLib.Modules.GetModuleMetaData(name)
    if not versionsData then
        return nil
    end

    return versionsData.latest
end

function PulsarLib.Modules.GetModuleVersionData(name, version)
    local versionsData = PulsarLib.Modules.GetVersionsData(name)
    if not versionsData then
        return nil
    end

    return versionsData[version]
end


function PulsarLib.Modules.DownloadModule(name, version)
    local moduleMetaData = PulsarLib.Modules.GetModuleMetaData(name)
    if not moduleMetaData then
        PulsarLib.Logging:Error("Module " .. name .. " does not exist")
        return
    end

    if version == "latest" then
        version = moduleMetaData.latest
    end

    local versionsData = moduleMetaData.versions
    if not versionsData[version] then
        PulsarLib.Logging:Error("Module " .. name .. " does not have version " .. version)
        return
    end

    if not file.IsDir("pulsarlib/modules/" .. name .. "/versions", "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name .. "/versions")
    end

    if not file.IsDir("pulsarlib/modules/" .. name .. "/versions/" .. version, "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name .. "/versions/" .. version)
    end

    local versionData = versionsData[version]
    local gmaDownloadURL = versionData.file

    local gmaName = string.Split(gmaDownloadURL, "/")[#string.Split(gmaDownloadURL, "/")]
    local gmaPath = "pulsarlib/modules/" .. name .. "/versions/" .. version .. "/" .. gmaName

    if file.Exists(gmaPath, "DATA") then
        PulsarLib.Logging:Debug("Module " .. name .. " version " .. version .. " already exists")
        return
    end

    HTTP({
        url = gmaDownloadURL,
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write(gmaPath, body)
                PulsarLib.Logging:Debug("Downloaded module " .. name .. " version " .. version)
            else
                PulsarLib.Logging:Error("Failed to download module " .. name .. " version " .. version .. ": " .. code)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download module " .. name .. " version " .. version .. ": " .. reason)
        end
    })
end
