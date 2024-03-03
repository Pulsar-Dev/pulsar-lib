PulsarLib.Modules = PulsarLib.Modules or {}
local baseURL = "https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master"
local emptyFunc = function() end
local logger = PulsarLib.Logging:Get("ModuleLoader")

--- Downloads the global metadata for all modules.
--- @param callback? fun(success: boolean) The function to call when the metadata has been downloaded.
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

--- Gets the global metadata for all modules.
--- @param callback function The function to call when the metadata has been retrieved.
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
    local metadata = util.JSONToTable(metadata)
    callback(true, metadata)
    return metadata
end

--- Downloads the metadata for a specific module.
--- @param name string The name of the module to download the metadata for.
--- @param callback function The function to call when the metadata has been downloaded.
function PulsarLib.Modules.DownloadModuleMetaData(name, callback)
    callback = callback or emptyFunc
    local metadata = PulsarLib.Modules.GetMetadata()
    if not metadata or not metadata[name] then
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

    if not file.Exists("pulsarlib/modules/" .. name .. "/metadata.json", "DATA") then
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
    else
        callback(true)
    end
end

--- Gets the metadata for a specific module.
--- @param name string The name of the module to get the metadata for.
--- @param callback function The function to call when the metadata has been retrieved.
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

--- Checks if a module exists.
--- @param name string The name of the module to check for.
--- @param callback function The function to call when the check has been completed.
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

--- Gets the load data for a module.
--- @param name string The name of the module to get the load data for.
--- @param callback function The function to call when the load data has been retrieved.
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