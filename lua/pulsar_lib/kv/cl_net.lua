PulsarLib = PulsarLib or {}
PulsarLib.KV = PulsarLib.KV or {}
PulsarLib.KV.Data = PulsarLib.KV.Data or {}

PulsarLib.Net.Receive("KV.Inserted", function()
    local key = net.ReadString()
    local value = net.ReadString()
    local state = net.ReadUInt(3)
    local valueType = net.ReadUInt(4)

    local convertedValue = PulsarLib.KV.ConvertType(value, valueType)

    PulsarLib.KV.Data[state][key] = convertedValue
end)

PulsarLib.Net.Receive("KV.Deleted", function()
    local key = net.ReadString()
    local state = net.ReadUInt(3)

    PulsarLib.KV.Data[state][key] = nil
end)

PulsarLib.Net.Receive("KV.FetchOnJoin", function()
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)
    local state = net.ReadUInt(3)

    data = util.Decompress(data)
    local table = util.JSONToTable(data)

    for _, v in pairs(table or {}) do
        local convertedValue = PulsarLib.KV.ConvertType(v.value, v.type)
        PulsarLib.KV.Data[state][v.key] = convertedValue
    end
end)