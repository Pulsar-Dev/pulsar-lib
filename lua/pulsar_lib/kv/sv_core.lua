---@diagnostic disable: duplicate-set-field
PulsarLib = PulsarLib or {}
PulsarLib.KV = PulsarLib.KV or {}

local logger = PulsarLib.Logging:Get("KV")

hook.Add("PulsarLib.SQL.Connected", "PulsarLib.KV.CreateTable", function()
    PulsarLib.SQL:RawQuery([[
        CREATE TABLE IF NOT EXISTS pulsarkv_server (
            `key` VARCHAR(100) PRIMARY KEY,
            `value` TEXT NOT NULL,
            `type` INT DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS pulsarkv_shared (
            `key` VARCHAR(100) PRIMARY KEY,
            `value` TEXT NOT NULL,
            `type` INT DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS pulsarkv_client (
            `key` VARCHAR(100) PRIMARY KEY,
            `value` TEXT NOT NULL,
            `type` INT DEFAULT 0
        )
    ]], nil, function()
        logger:Fatal("Failed to create pulsarkv tables")
    end)
end)

local stateTable = {
    [PulsarLib.KV.State.CLIENT] = "pulsarkv_client",
    [PulsarLib.KV.State.SHARED] = "pulsarkv_shared",
    [PulsarLib.KV.State.SERVER] = "pulsarkv_server"
}

--- Checks if a player has permission to upload, update or delete key-value pairs
--- @param ply Player The player to check
function PulsarLib.KV.HasPermission(ply)
    return PulsarLib.AdminUserGroups[ply:GetUserGroup()]
end

--- Inserts or updates a key-value pair in the database
--- @param key string The key to insert
--- @param value any The value to insert
--- @param state PulsarKVState The state of the key-value pair
--- @param valueType PulsarKVType The type of the value
--- @param onSuccess? function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
--- @param player? Player The player who created the key-value pair
function PulsarLib.KV.Insert(key, value, state, valueType, onSuccess, onError, player)
    if valueType == PulsarLib.KV.Type.TABLE and type(value) == "table" then
        value = util.TableToJSON(value)
    else
        value = util.TypeToString(value)
    end

    local table = stateTable[state]

    PulsarLib.SQL:PreparedQuery("REPLACE INTO " .. table .. " (`key`, `value`, `type`) VALUES (?, ?, ?)",
    {key, value, valueType},
    function()
        if onSuccess then
            onSuccess()
        end

        if player and state != PulsarLib.KV.State.SERVER then
            PulsarLib.Net.Start("KV.Inserted")
                :WriteString(key)
                :WriteString(value)
                :WriteUInt(state, 3)
                :WriteUInt(valueType, 4)
            :SendOmit(player)
        end
    end,
    onError)
end

--- Fetches a value from the database
--- @param key string The key to fetch
--- @param state PulsarKVState What state the key-value pair is in
--- @param onSuccess function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
--- @param convert? boolean Should we convert the value from a string to its original type
function PulsarLib.KV.Fetch(key, state, onSuccess, onError, convert)
    local table = stateTable[state]

    PulsarLib.SQL:PreparedQuery("SELECT `value`, `type` FROM " .. table .. " WHERE `key` = ?",
    {key},
    function(data)
        if data and data[1] then
            local value = data[1].value
            local valueType = data[1].type

            local returnVal = value
            if convert then
                returnVal = PulsarLib.KV.ConvertType(value, valueType)
            end

            onSuccess(returnVal, type)
        else
            onSuccess(nil)
        end
    end, onError)
end

--- Deletes a key-value pair from the database
--- @param key string The key to delete
--- @param state PulsarKVState The state of the key-value pair
--- @param onSuccess? function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
--- @param player? Player The player who deleted the key-value pair
function PulsarLib.KV.Delete(key, state, onSuccess, onError, player)
    local table = stateTable[state]

    PulsarLib.SQL:PreparedQuery("DELETE FROM " .. table .. " WHERE `key` = ?",
    {key},
    function()
        if onSuccess then
            onSuccess()
        end

        if player and state != PulsarLib.KV.State.SERVER then
            PulsarLib.Net.Start("KV.Deleted")
                :WriteString(key)
                :WriteUInt(state, 3)
            :SendOmit(player)
        end
    end,
    onError)
end

--- Fetches all key-value pairs from the database
--- @param state PulsarKVState Where is the query being called from (server or client)
--- @param onSuccess function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
--- @param convert? boolean Should we convert the values from a string to their original type
function PulsarLib.KV.FetchAll(state, onSuccess, onError, convert)
    local table = stateTable[state]

    PulsarLib.SQL:RawQuery("SELECT `key`, `value`, `type` FROM " .. table,
    function(data)
        if data then
            local convertedData = data

            if convert then
                for k, v in pairs(data) do
                    convertedData[k] = {
                        key = v.key,
                        value = PulsarLib.KV.ConvertType(v.value, v.type),
                        type = v.type
                    }
                end
            end

            onSuccess(convertedData)
        else
            if onSuccess then
                onSuccess({})
            end
        end
    end, onError)
end
