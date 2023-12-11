-- Welcome to Pulsar.

PulsarLib.ModuleTable = {
    ["PulsarLib"] = {
        Hook = "PulsarLib.Loaded",
        Global = PulsarLib, -- This dont have to be a string, as we know the addon is loaded or loading.
        Loaded = true
    },
    ["pixelui"] = {
        Hook = "PIXEL.UI.FullyLoaded",
        Requires = "PIXEL.UI.PulsarFork", -- This is a string, as we dont know if the addon is loaded or not.
        Global = "PIXEL" -- This must be a string, as chances are the addon hasn't loaded yet.
    },
    ["gm_express"] = {
        Hook = false,
        Global = false
    },
    ["updatr"] = {
        Hook = "Updatr.FullyLoaded",
        Global = "Updatr"
    }
}

PulsarLib:Include("core/sh_functional")
PulsarLib:Include("core/sh_logging")
PulsarLib:Include("core/sh_notify")
PulsarLib:IncludeDir("core/modules")
PulsarLib:Include("core/sh_addons")
PulsarLib:Include("core/sql/sv_sql")

PulsarLib:IncludeDir("lang")
PulsarLib:IncludeDir("helpers")

PulsarLib.Logging:Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")
