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

--[[
    Dont load PulsarLib (or its addons) below version 2024.03.21. 
    Versions below this will not be able to write .gma files which PulsarLib and its addons REQUIRE to load modules.
--]]
if VERSION < 240321 then
    for i = 1, 10 do
        PulsarLib.Logging:Fatal("PulsarLib is NOT loading due to your servers version being too old. Please update your server.")
    end

    return
end

PulsarLib:IncludeDir("core/modules")
PulsarLib:Include("core/sql/sv_sql")
PulsarLib:Include("core/sql/sv_migrations")
PulsarLib:Include("core/sh_addons")
PulsarLib:IncludeDir("lang")
PulsarLib:IncludeDirRecursive("helpers")
PulsarLib:IncludeDirRecursive("kv")

PulsarLib.Logging:Info("Successfully Loaded!")
hook.Run("PulsarLib.Loaded")
PulsarLib.Loaded = true