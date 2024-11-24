---@diagnostic disable: duplicate-set-field
PulsarLib = PulsarLib or {}
PulsarLib.KV = PulsarLib.KV or {}
PulsarLib.KV.Data = PulsarLib.KV.Data or {}

PulsarLib.KV.Data[PulsarLib.KV.State.LOCAL] = PulsarLib.KV.Data[PulsarLib.KV.State.LOCAL] or {}
PulsarLib.KV.Data[PulsarLib.KV.State.CLIENT] = PulsarLib.KV.Data[PulsarLib.KV.State.CLIENT] or {}
PulsarLib.KV.Data[PulsarLib.KV.State.SHARED] = PulsarLib.KV.Data[PulsarLib.KV.State.SHARED] or {}

local logger = PulsarLib.Logging:Get("KV")

hook.Add("InitPostEntity", "PulsarLib.KV.Ready", function()
    logger:Debug("Fetching local data")

    PulsarLib.KV.FetchAll(PulsarLib.KV.State.LOCAL, nil, function(err)
        logger:Fatal("Failed to fetch local data: " .. err)
    end)

    PulsarLib.Net.Start("KV.Ready")
    :Send()
end)

hook.Add("PulsarLib.SQL.Connected", "PulsarLib.KV.CreateTable", function()
    PulsarLib.SQL.RawQuery([[
        CREATE TABLE IF NOT EXISTS pulsarkv_local (
            `key` VARCHAR(100) PRIMARY KEY,
            `value` TEXT NOT NULL,
            `type` INT DEFAULT 0
        )
    ]], nil, function()
        logger:Fatal("Failed to create local key-value table")
    end)
end)

--- Inserts or updates a key-value pair in the database
--- @param key string The key to insert
--- @param value any The value to insert
--- @param state PulsarKVState The state of the key-value pair
--- @param typeValue PulsarKVType The type of the value
--- @param onSuccess? function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
function PulsarLib.KV.Insert(key, value, state, typeValue, onSuccess, onError)
    if state == PulsarLib.KV.State.LOCAL then
        key = PulsarLib.SQL:Escape(key)
        value = PulsarLib.SQL:Escape(value)

        PulsarLib.SQL:PreparedQuery("REPLACE INTO pulsarkv_local (`key`, `value`, `type`) VALUES (?, ?, ?, ?)",
        {key, value, state, typeValue},
        function()
            if onSuccess then
                onSuccess()
            end

            PulsarLib.KV.Data[state][key] = value
        end,
        onError)

        return
    end

    local convertedValue

    if typeValue == PulsarLib.KV.Type.TABLE and type(value) == "table" then
        convertedValue = util.TableToJSON(value)
    else
        convertedValue = util.TypeToString(value)
    end

    PulsarLib.Net.Start("KV.Insert")
        :WriteString(key)
        :WriteString(convertedValue)
        :WriteUInt(state, 3)
        :WriteUInt(typeValue, 4)
    :Send()

    PulsarLib.Net.Receive("KV.Insert", function()
        local success = net.ReadBool()

        if not success then
            local err = net.ReadString()

            if onError then
                onError(err)
            end

            return
        end

        PulsarLib.KV.Data[state][key] = value

        if onSuccess then
            onSuccess()
        end
    end)
end

--- Fetches a value from the database
--- @param key string The key to fetch
--- @param state PulsarKVState What state the key-value pair is in
--- @param onSuccess function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
function PulsarLib.KV.Fetch(key, state, onSuccess, onError)
    if state == PulsarLib.KV.State.LOCAL then
        key = PulsarLib.SQL:Escape(key)

        PulsarLib.SQL:PreparedQuery("SELECT `value`, `type` FROM pulsarkv_local WHERE `key` = ?",
        {key},
        function(data)
            if data and data[1] then
                local value = data[1].value
                local valueType = data[1].type

                local convertedValue = PulsarLib.KV.ConvertType(value, valueType)
                onSuccess(convertedValue)

                PulsarLib.KV.Data[state][key] = convertedValue
            else
                onSuccess(nil)
            end
        end,
        onError)

        return
    end

    PulsarLib.Net.Start("KV.Fetch")
        :WriteString(key)
        :WriteUInt(state, 3)
    :Send()

    PulsarLib.Net.Fetch("KV.Fetch", function()
        local success = net.ReadBool()

        if not success then
            local err = net.ReadString()

            if onError then
                onError(err)
            end

            return
        end

        local value = net.ReadString()
        local type2 = net.ReadUInt(4)
        value = PulsarLib.KV.ConvertType(value, type2)

        PulsarLib.KV.Data[state][key] = value

        if onSuccess then
            onSuccess(value)
        end
    end)
end

--- Deletes a key-value pair from the database
--- @param key string The key to delete
--- @param state PulsarKVState The state of the key-value pair
--- @param onSuccess? function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
function PulsarLib.KV.Delete(key, state, onSuccess, onError)
    if state == PulsarLib.KV.State.LOCAL then
        key = PulsarLib.SQL:Escape(key)

        PulsarLib.SQL:PreparedQuery("DELETE FROM pulsarkv_local WHERE `key` = ?",
        {key},
        function()
            if onSuccess then
                onSuccess()
            end

            PulsarLib.KV.Data[state][key] = nil
        end,
        onError)

        return
    end

    PulsarLib.Net.Start("KV.Delete")
        :WriteString(key)
        :WriteUInt(state, 3)
    :Send()

    PulsarLib.Net.Receive("KV.Delete", function()
        local success = net.ReadBool()

        if not success then
            local err = net.ReadString()

            if onError then
                onError(err)
            end

            return
        end

        PulsarLib.KV.Data[state][key] = nil

        if onSuccess then
            onSuccess()
        end
    end)
end

--- Fetches all key-value pairs from the database
--- @param state PulsarKVState Where is the query being called from (server or client)
--- @param onSuccess? function The function to call when the query is successful
--- @param onError? function The function to call when the query fails
function PulsarLib.KV.FetchAll(state, onSuccess, onError)
    if state == PulsarLib.KV.State.LOCAL then
        PulsarLib.SQL:PreparedQuery("SELECT `key`, `value`, `type` FROM pulsarkv_local",
        {},
        function(data)
            for k, v in pairs(data or {}) do
                local convertedValue = PulsarLib.KV.ConvertType(v.value, v.type)
                PulsarLib.KV.Data[state][v.key] = convertedValue
            end


            if onSuccess then
                onSuccess(PulsarLib.KV.Data[state])
            end
        end,
        onError)

        return
    end

    PulsarLib.Net.Start("KV.FetchAll")
        :WriteUInt(state, 3)
    :Send()

    PulsarLib.Net.Receive("KV.FetchAll", function()
        local success = net.ReadBool()

        if not success then
            local err = net.ReadString()
            if onError then
                onError(err)
            end

            return
        end

        local len = net.ReadUInt(32)
        local data = net.ReadData(len)
        data = util.Decompress(data)
        local table = util.JSONToTable(data)


        for k, v in pairs(table or {}) do
            local convertedValue = PulsarLib.KV.ConvertType(v.value, v.type)
            PulsarLib.KV.Data[state][v.key] = convertedValue
        end

        if onSuccess then
            onSuccess(PulsarLib.KV.Data[state])
        end
    end)
end
