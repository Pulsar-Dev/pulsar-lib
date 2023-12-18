PulsarLib.Modules = PulsarLib.Modules or {}

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
        PulsarLib.Logging:Error("Module '", logger:Highlight(name), "' does not exist")
        callback(false)
        return nil
    end

    if not file.IsDir("pulsarlib/modules/" .. name, "DATA") then
        file.CreateDir("pulsarlib/modules/" .. name)
    end

    local moduleDataURL = baseURL .. metadata[name] .. "/metadata.json"

    local function downloadData()
        HTTP({
            url = moduleDataURL,
            method = "GET",
            success = function(code, body, headers)
                if code == 200 then
                    file.Write("pulsarlib/modules/" .. name .. "/metadata.json", body)
                    PulsarLib.Logging:Debug("Downloaded module metadata for '", logger:Highlight(name), "'")
                    callback(true)
                else
                    PulsarLib.Logging:Error("Failed to download module metadata for '", logger:Highlight(name), "': '", logger:Highlight(code), "'")
                    callback(false)
                end
            end,
            failed = function(reason)
                PulsarLib.Logging:Error("Failed to download module metadata for '", logger:Highlight(name), "': '", logger:Highlight(reason), "'")
                callback(false)
            end
        })
    end

    if not file.Exists("pulsarlib/modules/" .. name .. "/metadata.json", "DATA") then
        http.Fetch(moduleDataURL, function(body, size, headers, code)
            if code == 200 then
                local oldMetadata = file.Read("pulsarlib/modules/" .. name .. "/metadata.json", "DATA")
                if oldMetadata == body then
                    PulsarLib.Logging:Debug("Module metadata for '", logger:Highlight(name), "' is up to date")
                    callback(true)
                    return
                end

                downloadData()
            else
                PulsarLib.Logging:Error("Failed to download module metadata for '", logger:Highlight(name), "': '", logger:Highlight(code), "'")
                callback(false)
            end
        end)
    else
        callback(true)
    end
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