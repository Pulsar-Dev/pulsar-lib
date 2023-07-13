-- Welcome to Pulsar.

PulsarLib.ModuleTable = {
    ["PulsarLib"] = {
        Hook = "PulsarLib.Loaded",
        Global = PulsarLib, -- This dont have to be a string, as we know the addon is loaded.
        Loaded = true
    },
    ["pixelui"] = {
        Hook = "PIXEL.UI.FullyLoaded",
        Global = "PIXEL" -- This must be a string, as chances are the addon hasn't loaded yet.
    },
    ["gm_express"] = {
        Hook = false,
        Global = false
    }
}

PulsarLib:Include("core/sh_functional")
PulsarLib:Include("core/sh_logging")
PulsarLib:Include("core/sh_dependencies")
PulsarLib:Include("core/sh_modules")
PulsarLib:Include("core/sql/sv_sql")

PulsarLib:IncludeDir("lang")

PulsarLib.ERROR = PulsarLib.Logging.Levels.ERROR
PulsarLib.INFO = PulsarLib.Logging.Levels.INFO
PulsarLib.WARNING = PulsarLib.Logging.Levels.WARNING
PulsarLib.DEBUG = PulsarLib.Logging.Levels.DEBUG

PulsarLib:IncludeDir("helpers")

PulsarLib.Logging.Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")

local function loadAddons()
    PulsarLib:Include("core/sh_addons")
    hook.Run("PulsarLib.AddonsLoaded")
end

hook.Add("PulsarLib.ModulesLoaded", "PulsarLib.LoadAddons", loadAddons)

if PulsarLib.ModulesLoaded then
    loadAddons()
end