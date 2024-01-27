PulsarLib = PulsarLib or {}
PulsarLib.Net = PulsarLib.Net or {}

local l = PulsarLib.Language

function PulsarLib.Net.Receive(name, func, allowedGroups)
    net.Receive("PulsarLib." .. name, function(len, ply, ...)
        if not IsValid(ply) then return end

        local err = false
        local usergroup = PulsarLib.GetRank(ply)
        local secondaryUsergroup = PulsarLib.GetRank(ply, true)

        if allowedGroups and (not allowedGroups[usergroup] or not allowedGroups[secondaryUsergroup]) then
            err = l:Phrase("error.permissions")
            PulsarLib.Net.Error(ply, name, err)
            PulsarLib.Notify(ply, l:Phrase("error.permissions.message"))
            return
        end

        if not PulsarLib.AdminUserGroups[usergroup] and (ply.PulsarRateLimit or 0) > CurTime() then
            PulsarLib.Notify(ply, l:Phrase("error.ratelimit"))
            return
        end

        ply.PulsarRateLimit = CurTime() + 2
        func(len, ply, ...)
    end)
end

function PulsarLib.Net.Start(name)
    return net.Start("PulsarLib." .. name)
end

function PulsarLib.Net.Send(ply)
    return net.Send(ply)
end

function PulsarLib.Net.String(name)
    util.AddNetworkString("PulsarLib." .. name)
end

function PulsarLib.Net.Error(ply, netString, err)
    PulsarLib.Net.Start(netString)
        :WriteBool(false)
        :WriteString(err)
    :Send(ply)
end

-- Better net

local NetHandler = {}

local types = {
    ["angle"] = "Angle",
    ["bit"] = "Bit",
    ["bool"] = "Bool",
    ["color"] = "Color",
    ["data"] = "Data",
    ["double"] = "Double",
    ["entity"] = "Entity",
    ["float"] = "Float",
    ["int"] = "Int",
    ["matrix"] = "Matrix",
    ["normal"] = "Normal",
    ["player"] = "Player",
    ["string"] = "String",
    ["table"] = "Table",
    ["type"] = "Type",
    ["uint"] = "UInt",
    ["uint64"] = "UInt64",
    ["vector"] = "Vector"
}

function NetHandler.Start(name)
    local message = setmetatable({}, {
        __index = NetHandler
    })

    message.name = "PulsarLib." .. name
    message.data = {}

    return message
end

for k, v in pairs(types) do
    NetHandler["Write" .. v] = function(self, data, extras)
        table.insert(self.data, {
            type = k,
            data = data,
            extras
        })

        return self
    end
end

function NetHandler:Send(ply)
    net.Start(self.name)

    for k, v in ipairs(self.data) do
        if v.extras then
            net[types[v.type]](v.data, v.extras)
            continue
        end

        net[types[v.type]](v.data)
    end

    net.Send(ply)
end

function NetHandler:Broadcast()
    net.Start(self.name)

    for k, v in ipairs(self.extras) do
        if v.extras then
            net[types[v.type]](v.data, v.extras)
            continue
        end

        net[types[v.type]](v.data)
    end

    net.Broadcast()
end

PulsarLib.Net.Start = NetHandler.Start