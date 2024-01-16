PulsarLib.Modules = PulsarLib.Modules or {}
if not reqwest and not CHTTP then
    local suffix = ({"osx64", "osx", "linux64", "linux", "win64", "win32"})[(system.IsWindows() and 4 or 0) + (system.IsLinux() and 2 or 0) + (jit.arch == "x86" and 1 or 0) + 1]
    local fmt = "lua/bin/gm" .. (CLIENT and "cl" or "sv") .. "_%s_%s.dll"
    local function installed(name)
        if file.Exists(string.format(fmt, name, suffix), "GAME") then return true end
        if jit.versionnum ~= 20004 and jit.arch == "x86" and system.IsLinux() then return file.Exists(string.format(fmt, name, "linux32"), "GAME") end
        return false
    end

    if installed("reqwest") then require("reqwest") end
    if not reqwest and installed("chttp") then require("chttp") end
end

local HTTP = reqwest or CHTTP or HTTP
local baseURL = "https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master"
local emptyFunc = function() end
local logger = PulsarLib.Logging:Get("ModuleLoader")

function PulsarLib.Modules.DownloadMetadata(callback)
    callback = callback or emptyFunc

    PulsarLib.Logging:Debug("Downloading global metadata")
    HTTP({
        url = baseURL .. "/metadata.json",
        method = "GET",
        success = function(code, body, headers)
            if code == 200 then
                file.Write("pulsarlib/modules/metadata.json", body)
                PulsarLib.Logging:Debug("Downloaded global metadata")

                callback(true)
            else
                PulsarLib.Logging:Error("Failed to download metadata: '", logger:Highlight(code), "'")
                callback(false)
            end
        end,
        failed = function(reason)
            PulsarLib.Logging:Error("Failed to download metadata: '", logger:Highlight(reason), "'")
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
    if not metadata then return {} end
    metadata = util.JSONToTable(metadata)
    callback(true, metadata)
    return metadata
end

function PulsarLib.Modules.DownloadModuleMetaData(name, callback)
    callback = callback or emptyFunc
    local metadata = PulsarLib.Modules.GetMetadata()
    if not metadata[name] then
        PulsarLib.Logging:Error("Module '", logger:Highlight(name), "' does not exist")
        callback(false)
        return nil
    end

    if not file.IsDir("pulsarlib/modules/" .. name, "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name)
    end
    local moduleDataURL = baseURL .. metadata[name] .. "/metadata.json"
    local lastMetaTimesCookie = cookie.GetString("pulsarlib_last_meta_times", "{}")
    local lastMetaTimes = util.JSONToTable(lastMetaTimesCookie)
    if (lastMetaTimes[name] and lastMetaTimes[name] > os.time() - (60 * 5)) and file.Exists("pulsarlib/modules/" .. name .. "/metadata.json", "DATA") then -- 5 mins
        PulsarLib.Logging:Debug("Using cached module metadata for '", logger:Highlight(name), "' as it is less than 5 minutes old")
        callback(true)
        return
    end

    http.Fetch(moduleDataURL, function(body, size, headers, code)
        if code == 200 then
            file.Write("pulsarlib/modules/" .. name .. "/metadata.json", body)
            PulsarLib.Logging:Debug("Downloaded module metadata for '", logger:Highlight(name), "'")
            lastMetaTimesCookie = cookie.GetString("pulsarlib_last_meta_times", "{}")
            lastMetaTimes = util.JSONToTable(lastMetaTimesCookie)
            lastMetaTimes[name] = os.time()
            cookie.Set("pulsarlib_last_meta_times", util.TableToJSON(lastMetaTimes))
            callback(true)
        else
            PulsarLib.Logging:Error("Failed to download module metadata for '", logger:Highlight(name), "': '", logger:Highlight(code), "'")
            callback(false)
        end
    end)
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
            PulsarLib.Logging:Error("Module '", logger:Highlight(name), "' does not exist")
            return
        end

        if version == "latest" then version = moduleMetaData.latest end
        local versionsData = moduleMetaData.versions
        if not versionsData[version] then
            PulsarLib.Logging:Error("Module '", logger:Highlight(name), "' does not have version '", logger:Highlight(version), "'")
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

        if not gmaDownloadURL:match("^https?://") then
            gmaDownloadURL = baseURL .. "/" .. name .. "" .. gmaDownloadURL
        end

        local gmaName = string.Split(gmaDownloadURL, "/")[#string.Split(gmaDownloadURL, "/")]
        local gmaPath = "pulsarlib/modules/" .. name .. "/versions/" .. version .. "/" .. gmaName .. ".txt"

        if file.Exists(gmaPath, "DATA") then
            PulsarLib.Logging:Debug("Module '", logger:Highlight(name), "' version '", logger:Highlight(version), "' already exists")
            callback(true)
            return
        end

        HTTP({
            url = gmaDownloadURL,
            method = "GET",
            success = function(code, body, headers)
                if code == 200 then
                    file.Write(gmaPath, body)
                    PulsarLib.Logging:Debug("Downloaded module '", logger:Highlight(name), "' version '", logger:Highlight(version), "'")
                    callback(true)
                else
                    PulsarLib.Logging:Error("Failed to download module '", logger:Highlight(name), "' version '", logger:Highlight(version), "': '", logger:Highlight(code), "'")
                    callback(false)
                end
            end,
            failed = function(reason)
                PulsarLib.Logging:Error("Failed to download module '", logger:Highlight(name), "' version '", logger:Highlight(version), "': '", logger:Highlight(reason), "'")
                callback(false)
            end
        })
    end)
end

function PulsarLib.Modules.GetLoadData(name, callback)
    callback = callback or emptyFunc

    PulsarLib.Modules.GetModuleMetaData(name, function(success, moduleMetaData)
        if not success then
            callback(false)
            return
        end

        callback(true, {
            hook = moduleMetaData["load-hook"],
            global = moduleMetaData["global-var"]
        })
    end)
end