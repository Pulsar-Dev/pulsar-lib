PulsarLib.Modules = PulsarLib.Modules or {}
PulsarLib.Modules.Loaded = PulsarLib.Modules.Loaded or {}

file.CreateDir("pulsarlib/modules")

local emptyFunc = function() end

function PulsarLib.Modules.LoadModule(module, version, callback)
	callback = callback or emptyFunc

	local logger = PulsarLib.Logging:Get("ModuleLoader")

	if not module then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (no module specified)")
		callback(false)
		return nil
	end

	if not version then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (no version specified)")
		callback(false)
		return nil
	end

	if PulsarLib.Modules.Loaded[module] then
		logger:Error("Unable to load module '", logger:Highlight(module), "' (module already loaded)")
		callback(true)
		return nil
	end

	PulsarLib.Modules.GetLoadData(module, function(success, loadData)
		if not success then
			logger:Error("Unable to load module '", logger:Highlight(module), "' (unable to get load data)")
			callback(false)
			return nil
		end

		local loadHook = loadData.hook
		local globalVar = loadData.global

		if _G[globalVar] then
			logger:Debug("Module '", logger:Highlight(module), "' is already loaded")
			callback(true)
			return nil
		end

		logger:Debug("Waiting for module '", logger:Highlight(module), "' to load using hook '", logger:Highlight(loadHook), "'")

		hook.Add(loadHook, "PulsarLib.Modules.LoadModule." .. module, function()
			logger:Debug("Module '", logger:Highlight(module), "' has loaded")

			hook.Remove(loadHook, "PulsarLib.Modules.LoadModule." .. module)

			PulsarLib.Modules.Loaded[module] = true

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
end)