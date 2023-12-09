PulsarLib.Modules = PulsarLib.Modules or {}

file.CreateDir("pulsarlib/modules")

http.Fetch("https://raw.githubusercontent.com/Pulsar-Dev/pulsar-lib-modules/master/README.md", function(body)
    file.Write("pulsarlib/modules/readme.txt", body)
end)

function PulsarLib.Modules.LoadModule(module, version)
    if not module then
        PulsarLib.Logging:Error("Unable to load module" .. module .. "(no module specified)")
        return nil
    end

    if not version then
        PulsarLib.Logging:Error("Unable to load module" .. module .. "(no version specified)")
        return nil
    end

    if not PulsarLib.Modules.ModuleExists(module) then
        return nil
    end

    if not PulsarLib.Modules.GetModuleVersionData(module, version) and version ~= "latest" then
        PulsarLib.Logging:Error("Unable to load module " .. module .. " (version " .. version .. " does not exist)")
        return nil
    end

    if version == "latest" then
        version = PulsarLib.Modules.GetLatestVersion(module)
    end

    if not version then
        PulsarLib.Logging:Error("Unable to load module " .. module .. " (no version specified)")
        return nil
    end

    local modulePath = "pulsarlib/modules/" .. module .. "/versions/" .. version .. "/"
    local gmaPath = "data/" .. modulePath .. module .. ".gma"

    local success, mounted = game.MountGMA(gmaPath)
    print(success, mounted)
end


PulsarLib.Modules.LoadModule("pixel-ui", "latest")