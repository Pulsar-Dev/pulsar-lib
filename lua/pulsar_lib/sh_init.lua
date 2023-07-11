-- Welcome to Pulsar.

PulsarLib:Include("core/sh_functional")
PulsarLib:Include("core/sh_logging")
PulsarLib:Include("core/sh_modules")

PulsarLib:IncludeDir("lang")

PulsarLib.ERROR = PulsarLib.Logging.Levels.ERROR
PulsarLib.INFO = PulsarLib.Logging.Levels.INFO
PulsarLib.WARNING = PulsarLib.Logging.Levels.WARNING
PulsarLib.DEBUG = PulsarLib.Logging.Levels.DEBUG

PulsarLib:IncludeDir("helpers")

PulsarLib.Logging.Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")

PulsarLib.ModuleTable = {
    ["PulsarLib"] = {
        Hook = "PulsarLib.Loaded",
        Global = PulsarLib
    },
    ["pixelui"] = {
        Hook = "PIXEL.UI.FullyLoaded",
        Global = PIXEL.UI
    },
    ["gm_express"] = {
        Hook = false,
        Global = false
    }
}

local function loadAddons()
    PulsarLib:Include("core/sh_addons")
    hook.Run("PulsarLib.AddonsLoaded")
end

hook.Add("PulsarLib.ModulesLoaded", "PulsarLib.LoadAddons", loadAddons)

if PulsarLib.ModulesLoaded then
    loadAddons()
end