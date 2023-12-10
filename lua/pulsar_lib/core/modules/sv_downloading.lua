PulsarLib.Modules = PulsarLib.Modules or {}

local baseURL = "https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master"

local emptyFunc = function() end

function PulsarLib.Modules.DownloadMetadata(callback)
    callback = callback or emptyFunc

    PulsarLib.Logging:Debug("Downloading module metadata")
    HTTP({
        url = baseURL .. "/metadata.json",
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write("pulsarlib/modules/metadata.json", body)
                PulsarLib.Logging:Debug("Downloaded module metadata")
                callback(true)
            else
                PulsarLib.Logging:Error("Failed to download metadata: " .. code)
                callback(false)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download metadata: " .. reason)
            callback(false)
        end
    })
end

function PulsarLib.Modules.GetMetadata(callback)
    callback = callback or emptyFunc

    if not file.Exists("pulsarlib/modules/metadata.json", "DATA") then
        PulsarLib.Modules.DownloadMetadata(function(success)
            if not success then
                callback(false)
                return
            end

            local metadata = file.Read("pulsarlib/modules/metadata.json", "DATA")
            callback(true, util.JSONToTable(metadata))
        end)
        return
    end

    local metadata = file.Read("pulsarlib/modules/metadata.json", "DATA")
    if not metadata then
        return {}
    end

    metadata = util.JSONToTable(metadata)

    callback(true, metadata)
    return metadata
end


function PulsarLib.Modules.DownloadModuleMetaData(name, callback)
    callback = callback or emptyFunc

    local metadata = PulsarLib.Modules.GetMetadata()

    if not metadata[name] then
        PulsarLib.Logging:Error("Module " .. name .. " does not exist")
        callback(false)
        return nil
    end

    if not file.IsDir("pulsarlib/modules/" .. name, "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name)
    end

    if file.Exists("pulsarlib/modules/" .. name .. "/metadata.json", "DATA") then
        PulsarLib.Logging:Debug("Module metadata for " .. name .. " already exists")
        callback(true)
        return
    end

    local moduleDataURL = baseURL .. metadata[name] .. "/metadata.json"
    HTTP({
        url = moduleDataURL,
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write("pulsarlib/modules/" .. name .. "/metadata.json", body)
                PulsarLib.Logging:Debug("Downloaded module metadata for " .. name)
                callback(true)
            else
                PulsarLib.Logging:Error("Failed to download module metadata for " .. name .. ": " .. code)
                callback(false)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download module metadata for " .. name .. ": " .. reason)
            callback(false)
        end
    })
end

function PulsarLib.Modules.GetModuleMetaData(name, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.DownloadModuleMetaData(name, function(success)
        if not success then
            callback(false)
            return
        end

        local metadata = file.Read("pulsarlib/modules/" .. name .. "/metadata.json", "DATA")
        callback(true, util.JSONToTable(metadata))
    end)
end

function PulsarLib.Modules.ModuleExists(name, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetModuleMetaData(name, function(success, moduleMetaData)
        if not success then
            callback(false)
            return
        end

        callback(true, moduleMetaData)
    end)
end

function PulsarLib.Modules.GetVersionsData(name, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetModuleMetaData(name, function(success, moduleMetaData)
        if not success then
            callback(false)
            return
        end

        if not moduleMetaData then
            callback(false)
            return
        end

        callback(true, moduleMetaData.versions)
    end)

end

function PulsarLib.Modules.GetLatestVersion(name, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetModuleMetaData(name, function(success, moduleMetaData)
        if not success then
            callback(false)
            return
        end

        if not moduleMetaData then
            callback(false)
            return
        end

        callback(true, moduleMetaData.latest)
    end)
end

function PulsarLib.Modules.GetVersionData(name, version, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetVersionsData(name, function(success, versionsData)
        if not success then
            callback(false)
            return
        end

        if not versionsData or not versionsData[version] then
            callback(false)
            return
        end

        callback(true, versionsData[version])
    end)
end

function PulsarLib.Modules.GetDependencies(name, version, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetVersionData(name, version, function(success, versionData)
        if not success then
            callback(false)
            return
        end

        callback(true, versionData.dependencies)
    end)
end


function PulsarLib.Modules.DownloadModule(name, version, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetModuleMetaData(name, function(success, moduleMetaData)
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
            callback(true)
            return
        end

        HTTP({
            url = gmaDownloadURL,
            method = "GET",
            success = function(code, body, headers)
                if code == 200 then
                    file.Write(gmaPath, body)
                    PulsarLib.Logging:Debug("Downloaded module " .. name .. " version " .. version)
                    callback(true)
                else
                    PulsarLib.Logging:Error("Failed to download module " .. name .. " version " .. version .. ": " .. code)
                    callback(false)
                end
            end,
            failed = function(reason)
                PulsarLib.Logging:Error("Failed to download module " .. name .. " version " .. version .. ": " .. reason)
                callback(false)
            end
        })
    end)
end
