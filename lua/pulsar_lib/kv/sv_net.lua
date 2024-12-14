PulsarLib = PulsarLib or {}

PulsarLib.Net.String("KV.Ready")
PulsarLib.Net.String("KV.FetchOnJoin")

PulsarLib.Net.String("KV.Insert")
PulsarLib.Net.String("KV.Fetch")
PulsarLib.Net.String("KV.Delete")
PulsarLib.Net.String("KV.FetchAll")

PulsarLib.Net.String("KV.Inserted")
PulsarLib.Net.String("KV.Deleted")

local logger = PulsarLib.Logging:Get("KV")

PulsarLib.Net.Receive("KV.Ready", function(_, ply)
    PulsarLib.KV.FetchAll(PulsarLib.KV.State.CLIENT, function(data)
        data = util.TableToJSON(data)
        data = util.Compress(data)

        local len = #data

        PulsarLib.Net.Start("KV.FetchOnJoin")
            :WriteUInt(len, 32)
            :WriteData(data, len)
            :WriteUInt(PulsarLib.KV.State.CLIENT, 3)
        :Send(ply)
    end,
    function(err)
        logger:Error(err)
    end)

    PulsarLib.KV.FetchAll(PulsarLib.KV.State.SHARED, function(data)
        data = util.TableToJSON(data)
        data = util.Compress(data)

        local len = #data

        PulsarLib.Net.Start("KV.FetchOnJoin")
            :WriteUInt(len, 32)
            :WriteData(data, len)
            :WriteUInt(PulsarLib.KV.State.SHARED, 3)
        :Send(ply)
    end,
    function(err)
        logger:Error(err)
    end)
end)

PulsarLib.Net.Receive("KV.Insert", function(_, ply)
    local key = net.ReadString()
    local value = net.ReadString()
    local state = net.ReadUInt(3)
    local type = net.ReadUInt(4)

    if state != PulsarLib.KV.State.CLIENT and state != PulsarLib.KV.State.SHARED and state != PulsarLib.KV.State.LOCAL then
        PulsarLib.Net.Start("KV.Insert")
            :WriteBool(false)
            :WriteString("Unable to insert server only key-value pairs from the client")
        :Send(ply)

        return
    end

    PulsarLib.KV.Insert(key, value, state, type,
    function()
        PulsarLib.Net.Start("KV.Insert")
            :WriteBool(true)
        :Send(ply)
    end,
    function(err)
        PulsarLib.Net.Start("KV.Insert")
            :WriteBool(false)
            :WriteString(err)
        :Send(ply)
    end)
end, PulsarLib.AdminUserGroups)

net.Receive("KV.Fetch", function(_, ply)
    local key = net.ReadString()
    local state = net.ReadUInt(3)

    PulsarLib.KV.Fetch(key, state,
    function(value, type)
        PulsarLib.Net.Start("KV.Fetch")
            :WriteBool(true)
            :WriteString(value)
            :WriteUInt(type, 4)
        :Send(ply)
    end,
    function(err)
        PulsarLib.Net.Start("KV.Fetch")
            :WriteBool(false)
            :WriteString(err)
        :Send(ply)
    end)
end)

PulsarLib.Net.Receive("KV.Delete", function(_, ply)
    local key = net.ReadString()
    local state = net.ReadUInt(3)

    if state != PulsarLib.KV.State.CLIENT and state != PulsarLib.KV.State.SHARED then
        PulsarLib.Net.Start("KV.Insert")
            :WriteBool(false)
            :WriteString("Unable to insert server only key-value pairs from the client")
        :Send(ply)

        return
    end

    PulsarLib.KV.Delete(key, state,
    function()
        PulsarLib.Net.Start("KV.Delete")
            :WriteBool(true)
        :Send(ply)
    end,
    function(err)
        PulsarLib.Net.Start("KV.Delete")
            :WriteBool(false)
            :WriteString(err)
        :Send(ply)
    end)
end, PulsarLib.AdminUserGroups)

PulsarLib.Net.Receive("KV.FetchAll", function(_, ply)
    local state = net.ReadUInt(3)

    PulsarLib.KV.FetchAll(state,
    function(data)
        data = util.TableToJSON(data)
        data = util.Compress(data)

        local len = #data

        PulsarLib.Net.Start("KV.FetchAll")
            :WriteBool(true)
            :WriteUInt(len, 32)
            :WriteData(data, len)
        :Send(ply)
    end,
    function(err)
        PulsarLib.Net.Start("KV.FetchAll")
            :WriteBool(false)
            :WriteString(err)
        :Send(ply)
    end, false)
end)