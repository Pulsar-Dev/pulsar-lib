PulsarLib.Modules = PulsarLib.Modules or {}
PulsarLib.Modules.Loaded = PulsarLib.Modules.Loaded or {}

file.CreateDir("pulsarlib/modules")

local emptyFunc = function() end

function PulsarLib.Modules.LoadModule(module, version, callback)
	callback = callback or emptyFunc

	local logger = PulsarLib.Logging:Get("ModuleLoader")

	if not PulsarLib.Modules.AddonsReadyToLoad then
		logger:Debug("Waiting for addons to be ready to load")
		hook.Add("PulsarLib.Modules.AddonsReadyToLoad", "PulsarLib.Modules.LoadModule." .. module, function()
			logger:Debug("Addons are ready to load")
			hook.Remove("PulsarLib.Modules.AddonsReadyToLoad", "PulsarLib.Modules.LoadModule." .. module)
			PulsarLib.Modules.LoadModule(module, version, callback)
		end)
		return
	end


	if not module then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (no module specified)")
		hook.Run("PulsarLib.Module.FailedLoad", module, "no module specified")
		callback(false)
		return nil
	end

	if not version then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (no version specified)")
		callback(false)
		hook.Run("PulsarLib.Module.FailedLoad", module, "no version specified")
		return nil
	end

	if PulsarLib.Modules.Loaded[module] == version or PulsarLib.Modules.Loaded[module] == "DEV" then
		logger:Debug("Module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "') is already loaded")
		hook.Run("PulsarLib.Module.Loaded", module, version)
		callback(true)
		return
	end

	PulsarLib.Modules.DownloadMetadata(function(mainMetaSuccess)
		if not mainMetaSuccess then
			logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to download metadata)")
			hook.Run("PulsarLib.Module.FailedLoad", module, "unable to download metadata")
			callback(false)
			return
		end

		PulsarLib.Modules.ModuleExists(module, function(exists, moduleMetaData)
			if not exists then
				logger:Error("Unable to load module '", logger:Highlight(module), "' (module does not exist)")
				hook.Run("PulsarLib.Module.FailedLoad", module, "module does not exist")
				callback(false)
				return
			end

			local moduleFolder = moduleMetaData.folder
			if not moduleFolder then
				logger:Warning("Module '", logger:Highlight(module), "' does not have a folder specified. It is recommend to add one to aid during development.")
			end

			if file.IsDir("addons/" .. moduleFolder, "GAME") then
				logger:Fatal("Module '", logger:Highlight(module), "' is already installed as an addon. You must remove it from the addons folder to continue loading the module correctly.")
				logger:Fatal("If you are developing this module, you can ignore this warning.")

				PulsarLib.Modules.GetLoadData(module, function(success, loadData)
					if not success then
						logger:Error("Unable to load dev module '", logger:Highlight(module), "' from addons folder. (unable to get load data)")
						callback(false)
						hook.Run("PulsarLib.Module.FailedLoad", module, "unable to get dev load data")
						return
					end

					local loadHook = loadData.hook
					local global = loadData.global

					if _G[global] then
						logger:Debug("Dev Module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "') is already loaded")
						callback(true)
						hook.Run("PulsarLib.Module.Loaded", module, version)
						return
					end

					logger:Debug("Waiting for dev module '", logger:Highlight(module), "' to load using hook '", logger:Highlight(loadHook), "'")

					hook.Add(loadHook, "PulsarLib.Modules.LoadModule." .. module, function()
						logger:Debug("Dev Module '", logger:Highlight(module), "' has loaded using hook '", logger:Highlight(loadHook), "'")

						hook.Remove(loadHook, "PulsarLib.Modules.LoadModule." .. module)

						PulsarLib.Modules.Loaded[module] = "DEV"
						hook.Run("PulsarLib.Module.Loaded", module, version)

						callback(true)
					end)
				end)

				return
			end

			PulsarLib.Modules.GetVersionData(module, version, function(success, versionData)
				if not success and version ~= "latest" then
					logger:Error("Unable to load module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "' does not exist)")
					callback(false)
					return
				end

				if version == "latest" then
					version = moduleMetaData.latest
				end

				if not version then
					logger:Error("Unable to load module '", logger:Highlight(module), "' (no version specified)")
					hook.Run("PulsarLib.Module.FailedLoad", module, "no version specified")
					callback(false)
					return
				end

				if PulsarLib.Modules.Loaded[module] then
					if PulsarLib.Modules.Loaded[module] == version then
						logger:Debug("Module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "') is already loaded")
						hook.Run("PulsarLib.Module.Loaded", module, version)
						callback(true)
						return
					elseif PulsarLib.Modules.Loaded[module] > version then
						logger:Error("Unable to load module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "' is older than the currently loaded version) Please contact support.")
						hook.Run("PulsarLib.Module.FailedLoad", module, "version is older than the currently loaded version")
						callback(false)
						return
					end
				end

				PulsarLib.Modules.GetDependencies(module, version, function(dependenciesSuccess, dependencies)
					if not dependenciesSuccess then
						logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to get dependencies)")
						hook.Run("PulsarLib.Module.FailedLoad", module, "unable to get dependencies")
						callback(false)
						return
					end

					local totalDependencies = table.Count(dependencies)
					local loadedDependencies = 0

					local function loadMainModule()
						local modulePath = "pulsarlib/modules/" .. module .. "/versions/" .. version .. "/"
						local gmaPath = "data/" .. modulePath .. module .. ".gma.txt"

						PulsarLib.Modules.DownloadModule(module, version, function(downloadSuccess)
							if not downloadSuccess then
								logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to download module)")
								hook.Run("PulsarLib.Module.FailedLoad", module, "unable to download module")
								callback(false)
								return
							end

							local mountSuccess, mountedFiles = game.MountGMA(gmaPath)
							if not mountSuccess then
								logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to mount GMA)")
								hook.Run("PulsarLib.Module.FailedLoad", module, "unable to mount GMA")
								callback(false)
								return
							end

							if mountSuccess then
								for _, autorunFile in ipairs(mountedFiles) do
									if string.StartWith(autorunFile, "lua/autorun/") and string.EndsWith(autorunFile, ".lua") then
										autorunFile = string.sub(autorunFile, 5)
										if string.StartWith(autorunFile, "lua/autorun/server/") then
											include(autorunFile)
										elseif string.StartWith(autorunFile, "lua/autorun/client/") then
											AddCSLuaFile(autorunFile)
										else
											include(autorunFile)
											AddCSLuaFile(autorunFile)
										end
									end
								end
							end

							logger:Debug("Loaded module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "')")
							hook.Run("PulsarLib.Module.Loaded", module, version)

							for k, v in pairs(mountedFiles) do
								logger:Debug("Mounted file '", logger:Highlight(v), "'")
							end

							PulsarLib.Modules.Loaded[module] = version
							callback(true)
						end)
					end

					if totalDependencies > 0 then
						for dependency, dependencyVersion in pairs(dependencies) do
							if not PulsarLib.Modules.Loaded[dependency] or PulsarLib.Modules.Loaded[dependency] ~= dependencyVersion then
								PulsarLib.Modules.LoadModule(dependency, dependencyVersion, function(loadModuleSuccess)
									if not loadModuleSuccess then
										PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (unable to load dependency '", logger:Highlight(dependency), "')")
										hook.Run("PulsarLib.Module.FailedLoad", module, "unable to load dependency")
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
	end)
end

hook.Add("Think", "PulsarLib.Modules.DownloadMetadata", function()
	hook.Remove("Think", "PulsarLib.Modules.DownloadMetadata")

	http.Fetch("https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master/README.md", function(body)
		file.Write("pulsarlib/modules/readme.txt", body)
	end)

	PulsarLib.Modules.DownloadMetadata()
	PulsarLib.Modules.AddonsReadyToLoad = true
	hook.Run("PulsarLib.Modules.AddonsReadyToLoad")
end)