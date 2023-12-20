PulsarLib.Modules = PulsarLib.Modules or {}
PulsarLib.Modules.Loaded = PulsarLib.Modules.Loaded or {}

file.CreateDir("pulsarlib/modules")

local emptyFunc = function() end

function PulsarLib.Modules.LoadModule(module, version, callback)
	callback = callback or emptyFunc

	local logger = PulsarLib.Logging:Get("ModuleLoader")

	if not module then
		PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (no module specified)")
		callback(false)
		return nil
	end

	if not version then
		PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (no version specified)")
		callback(false)
		return nil
	end

	PulsarLib.Modules.DownloadMetadata(function(mainMetaSuccess)
		if not mainMetaSuccess then
			PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (unable to download metadata)")
			callback(false)
			return
		end

		PulsarLib.Modules.ModuleExists(module, function(exists, moduleMetaData)
			if not exists then
				PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (module does not exist)")
				callback(false)
				return
			end

			local moduleFolder = moduleMetaData.folder
			if not moduleFolder then
				PulsarLib.Logging:Warning("Module '", logger:Highlight(module), "' does not have a folder specified. It is recommend to add one to aid during development.")
			end

			if file.IsDir("addons/" .. moduleFolder, "GAME") then
				PulsarLib.Logging:Fatal("Module '", logger:Highlight(module), "' is already installed as an addon. You must remove it from the addons folder to continue loading the module correctly.")
				PulsarLib.Logging:Fatal("If you are developing this module, you can ignore this warning.")

				PulsarLib.Modules.GetLoadData(module, function(success, loadData)
					if not success then
						PulsarLib.Logging:Error("Unable to load dev module '", logger:Highlight(module), "' from addons folder. (unable to get load data)")
						callback(false)
						return
					end

					local loadHook = loadData.hook
					local global = loadData.global

					if _G[global] then
						PulsarLib.Logging:Debug("Dev Module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "') is already loaded")
						callback(true)
						return
					end

					PulsarLib.Logging:Debug("Waiting for dev module '", logger:Highlight(module), "' to load using hook '", logger:Highlight(loadHook), "'")

					hook.Add(loadHook, "PulsarLib.Modules.LoadModule." .. module, function()
						PulsarLib.Logging:Debug("Dev Module '", logger:Highlight(module), "' has loaded using hook '", logger:Highlight(loadHook), "'")

						hook.Remove(loadHook, "PulsarLib.Modules.LoadModule." .. module)

						PulsarLib.Modules.Loaded[module] = "DEV"

						callback(true)
					end)
				end)

				return
			end

			PulsarLib.Modules.GetVersionData(module, version, function(success, versionData)
				if not success and version ~= "latest" then
					PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "' does not exist)")
					callback(false)
					return
				end

				if version == "latest" then
					version = moduleMetaData.latest
				end

				if not version then
					PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (no version specified)")
					callback(false)
					return
				end

				if PulsarLib.Modules.Loaded[module] then
					if PulsarLib.Modules.Loaded[module] == version then
						PulsarLib.Logging:Debug("Module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "') is already loaded")
						callback(true)
						return
					elseif PulsarLib.Modules.Loaded[module] > version then
						PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "' is older than the currently loaded version) Please contact support.")
						callback(false)
						return
					end
				end

				PulsarLib.Modules.GetDependencies(module, version, function(dependenciesSuccess, dependencies)
					if not dependenciesSuccess then
						PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (unable to get dependencies)")
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
								PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (unable to download module)")
								callback(false)
								return
							end

							local mountSuccess, mountedFiles = game.MountGMA(gmaPath)
							if not mountSuccess then
								PulsarLib.Logging:Error("Unable to load module '", logger:Highlight(module), "' (unable to mount GMA)")
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

							PulsarLib.Logging:Debug("Loaded module '", logger:Highlight(module), "' (version '", logger:Highlight(version), "')")

							for k, v in pairs(mountedFiles) do
								PulsarLib.Logging:Debug("Mounted file '", logger:Highlight(v), "'")
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
end)