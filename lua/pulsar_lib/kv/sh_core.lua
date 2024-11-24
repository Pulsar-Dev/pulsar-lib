PulsarLib = PulsarLib or {}
PulsarLib.KV = PulsarLib.KV or {}

---@enum PulsarKVState
PulsarLib.KV.State = {
    SERVER = 0, -- Server Only
    CLIENT = 1, -- Client Only
    SHARED = 2, -- Shared between server and client
    LOCAL = 3 -- Local Client Only (stored in clients cl.db)
}

---@enum PulsarKVType
PulsarLib.KV.Type = {
    STRING = 0,
    NUMBER = 1,
    BOOL = 2,
    TABLE = 3,
    VECTOR = 4,
    ANGLE = 5,
    COLOR = 6,
}

PulsarLib.KV.TypeConverts = {
    [PulsarLib.KV.Type.STRING] = function(value) return value end,
    [PulsarLib.KV.Type.NUMBER] = function(value) return tonumber(value) end,
    [PulsarLib.KV.Type.BOOL] = function(value) return tobool(value) end,
    [PulsarLib.KV.Type.TABLE] = function(value) return util.JSONToTable(value) end,
    [PulsarLib.KV.Type.VECTOR] = function(value) return util.StringToType(value, "Vector") end,
    [PulsarLib.KV.Type.ANGLE] = function(value) return util.StringToType(value, "Angle") end,
    [PulsarLib.KV.Type.COLOR] = function(value) return string.ToColor(value) end
}

--- Converts a value to its correct type
--- @param value string The value to convert
--- @param type PulsarKVType The type to convert to
--- @return any The converted value
function PulsarLib.KV.ConvertType(value, type)
    return PulsarLib.KV.TypeConverts[type](value)
end

-- if not CLIENT then return end

-- local function testPrint(value)
--     print(type(value), " - ", value)
-- end

-- local testTable = {
--     ["string"] = "test value",
--     ["number"] = 123,
--     ["bool"] = true,
--     ["table"] = {1, 2, 3},
--     ["vector"] = Vector(1, 2, 3),
--     ["angle"] = Angle(1, 2, 3),
--     ["color"] = Color(255, 255, 255)
-- }

-- PulsarKV.Insert("string", "test value", PulsarKV.State.CLIENT, PulsarKV.Type.STRING, print, print)
-- PulsarKV.Insert("number", 123, PulsarKV.State.CLIENT, PulsarKV.Type.NUMBER, print, print)
-- PulsarKV.Insert("bool", true, PulsarKV.State.CLIENT, PulsarKV.Type.BOOL, print, print)
-- PulsarKV.Insert("table", testTable, PulsarKV.State.CLIENT, PulsarKV.Type.TABLE, print, print)
-- PulsarKV.Insert("vector", Vector(1, 2, 3), PulsarKV.State.CLIENT, PulsarKV.Type.VECTOR, print, print)
-- PulsarKV.Insert("angle", Angle(1, 2, 3), PulsarKV.State.CLIENT, PulsarKV.Type.ANGLE, print, print)
-- PulsarKV.Insert("color", Color(255, 255, 255), PulsarKV.State.CLIENT, PulsarKV.Type.COLOR, print, print)

-- PulsarKV.Fetch("string", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("number", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("bool", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("table", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("vector", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("angle", PulsarKV.State.CLIENT, testPrint, print)
-- PulsarKV.Fetch("color", PulsarKV.State.CLIENT, testPrint, print)

-- PulsarKV.Delete("string", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("number", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("bool", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("table", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("vector", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("angle", PulsarKV.State.CLIENT)
-- PulsarKV.Delete("color", PulsarKV.State.CLIENT)

-- PulsarKV.FetchAll(PulsarKV.State.CLIENT, function(data)
--     for k, v in pairs(data) do
--         print("---")
--         if v.type == PulsarKV.Type.TABLE then
--             PrintTable(v.value)
--         else
--             testPrint(v.value)
--         end
--     end
-- end)