PulsarLib.Modules = PulsarLib.Modules or {}
PulsarLib.Modules.Loaded = PulsarLib.Modules.Loaded or {}

file.CreateDir("pulsarlib/modules")

function PulsarLib.Modules.LoadModule(module, version, callback)
    if not module then
        PulsarLib.Logging:Error("Unable to load module" .. module .. "(no module specified)")
        return nil
    end

    if not version then
        PulsarLib.Logging:Error("Unable to load module" .. module .. "(no version specified)")
        return nil
    end

    PulsarLib.Modules.ModuleExists(module, function(exists, moduleMetaData)
        if not exists then
            PulsarLib.Logging:Error("Unable to load module " .. module .. " (module does not exist)")
            callback(false)
            return
        end

        PulsarLib.Modules.GetVersionData(module, version, function(success, versionData)
            if not success and version ~= "latest" then
                PulsarLib.Logging:Error("Unable to load module " .. module .. " (version " .. version .. " does not exist)")
                callback(false)
                return
            end

            if version == "latest" then
                version = moduleMetaData.latest
            end

            if not version then
                PulsarLib.Logging:Error("Unable to load module " .. module .. " (no version specified)")
                callback(false)
                return
            end

            if PulsarLib.Modules.Loaded[module] then
                if PulsarLib.Modules.Loaded[module] == version then
                    PulsarLib.Logging:Debug("Module " .. module .. " (version " .. version .. ") is already loaded")
                    callback(true)
                    return
                elseif PulsarLib.Modules.Loaded[module] > version then
                    PulsarLib.Logging:Error("Unable to load module " .. module .. " (version " .. version .. " is older than the currently loaded version) Please contact the module developer to update the module.")
                    callback(false)
                    return
                end
            end

            PulsarLib.Modules.GetDependencies(module, version, function(dependenciesSuccess, dependencies)
                if not dependenciesSuccess then
                    PulsarLib.Logging:Error("Unable to load module " .. module .. " (unable to get dependencies)")
                    callback(false)
                    return
                end

                local totalDependencies = table.Count(dependencies)
                local loadedDependencies = 0

                local function loadMainModule()
                    local modulePath = "pulsarlib/modules/" .. module .. "/versions/" .. version .. "/"
                    local gmaPath = "data/" .. modulePath .. module .. ".gma"

                    PulsarLib.Modules.DownloadModule(module, version, function(downloadSuccess)
                        if not downloadSuccess then
                            PulsarLib.Logging:Error("Unable to load module " .. module .. " (unable to download module)")
                            callback(false)
                            return
                        end

                        local mountSuccess, _ = game.MountGMA(gmaPath)
                        if not mountSuccess then
                            PulsarLib.Logging:Error("Unable to load module " .. module .. " (unable to mount GMA)")
                            callback(false)
                            return
                        end

                        PulsarLib.Logging:Debug("Loaded module " .. module .. " (version " .. version .. ")")
                        PulsarLib.Modules.Loaded[module] = version
                        callback(true)
                    end)
                end

                if totalDependencies > 0 then
                    for dependency, dependencyVersion in pairs(dependencies) do
                        if not PulsarLib.Modules.Loaded[dependency] or PulsarLib.Modules.Loaded[dependency] ~= dependencyVersion then
                            PulsarLib.Modules.LoadModule(dependency, dependencyVersion, function(loadModuleSuccess)
                                if not loadModuleSuccess then
                                    PulsarLib.Logging:Error("Unable to load module " .. module .. " (unable to load dependency " .. dependency .. ")")
                                    callback(false)
                                    return
                                end

                                loadedDependencies = loadedDependencies + 1
                                if loadedDependencies == totalDependencies then
                                    loadMainModule()
                                end
                            end)
                        else
                            loadedDependencies = loadedDependencies + 1
                            if loadedDependencies == totalDependencies then
                                loadMainModule()
                            end
                        end
                    end
                else
                    loadMainModule()
                end
            end)
        end)
    end)
end

hook.Add("Think", "PulsarLib.Modules.DownloadMetadata", function()
    hook.Remove("Think", "PulsarLib.Modules.DownloadMetadata")
    PulsarLib.Modules.DownloadMetadata()
    http.Fetch("https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master/README.md", function(body)
        file.Write("pulsarlib/modules/readme.txt", body)
    end)
end)