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
		hook.Run("PulsarLib.Module.FailedLoad", module, "no version specified")
		callback(false)
		return nil
	end

	if PulsarLib.Modules.Loaded[module] == version or PulsarLib.Modules.Loaded[module] == "DEV" then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (module already loaded)")
		hook.Run("PulsarLib.Module.Loaded", module, version)
		callback(true)
		return nil
	end

	PulsarLib.Modules.GetLoadData(module, function(success, loadData)
		if not success then
			logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to get load data)")
			hook.Run("PulsarLib.Module.FailedLoad", module, "unable to get load data")
			callback(false)
			return nil
		end

		local loadHook = loadData.hook
		local globalVar = loadData.global

		if _G[globalVar] then
			logger:Debug("Module '", logger:Highlight(module), "' is already loaded")
			PulsarLib.Modules.Loaded[module] = true
			hook.Run("PulsarLib.Module.Loaded", module, version)
			callback(true)
			return nil
		end

		logger:Debug("Waiting for module '", logger:Highlight(module), "' to load using hook '", logger:Highlight(loadHook), "'")

		hook.Add(loadHook, "PulsarLib.Modules.LoadModule." .. module, function()
			logger:Debug("Module '", logger:Highlight(module), "' has loaded")

			hook.Remove(loadHook, "PulsarLib.Modules.LoadModule." .. module)

			PulsarLib.Modules.Loaded[module] = true

			hook.Run("PulsarLib.Module.Loaded", module, version)

			callback(true)
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