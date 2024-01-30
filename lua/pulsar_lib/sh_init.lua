-- Welcome to PulsarLib.

PulsarLib.AdminUserGroups = {
    ["owner"] = true,
    ["Owner"] = true,
    ["superadmin"] = true,
    ["SuperAdmin"] = true,
    ["Super Admin"] = true,
}

PulsarLib:Include("core/sh_functional")
PulsarLib:Include("core/sh_logging")
PulsarLib:Include("core/sh_notify")
PulsarLib:IncludeDir("core/modules")
PulsarLib:Include("core/sql/sv_sql")
PulsarLib:Include("core/sql/sv_migrations")
PulsarLib:Include("core/config/sv_config")
PulsarLib:Include("core/sh_addons")
PulsarLib:IncludeDir("lang")
PulsarLib:IncludeDirRecursive("helpers")

PulsarLib.Logging:Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")
