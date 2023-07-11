-- Welcome to Pulsar.

PulsarLib:Include("core/sh_functional")
PulsarLib:Include("core/sh_logging")
PulsarLib:Include("core/sh_modules")
PulsarLib:Include("core/sh_addons")

PulsarLib.ERROR = PulsarLib.Logging.Levels.ERROR
PulsarLib.INFO = PulsarLib.Logging.Levels.INFO
PulsarLib.WARNING = PulsarLib.Logging.Levels.WARNING
PulsarLib.DEBUG = PulsarLib.Logging.Levels.DEBUG

PulsarLib:IncludeDir("helpers")

PulsarLib.Logging.Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")