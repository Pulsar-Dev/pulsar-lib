PulsarLib = PulsarLib or {}
PulsarLib.Net = PulsarLib.Net or {}

local l = PulsarLib.Language

--- Receives a net message.
--- @param name string The name of the net message.
--- @param func function The function to call when the net message is received.
--- @param allowedGroups? table The groups allowed to use this net message.
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

--- Starts a net message.
--- @param name string The name of the net message to start.
function PulsarLib.Net.Start(name)
    return net.Start("PulsarLib." .. name)
end

--- Sends a net message.
--- @param ply Player The player to send the net message to.
function PulsarLib.Net.Send(ply)
    return net.Send(ply)
end

--- Adds a network string.
--- @param name string The name of the network string to add.
function PulsarLib.Net.String(name)
    util.AddNetworkString("PulsarLib." .. name)
end

--- Sends an error message back to the player.
--- @param ply Player The player to send the error message to.
--- @param netString string The name of the net message.
--- @param err string The error message to send.
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

--- Starts a new net message.
--- @param name string The name of the net message to start.
--- @return table
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
            type = v,
            data = data,
            extras = extras
        })

        return self
    end
end

--- Sends the net message.
--- @param ply Player|table The player(s) to send the net message to. This can be a player or a table of players.
function NetHandler:Send(ply)
    net.Start(self.name)

    for k, v in ipairs(self.data) do
        if v.extras then
            net["Write" .. v.type](v.data, v.extras)
            continue
        end

        net["Write" .. v.type](v.data)
    end

    net.Send(ply)
end

--- Broadcasts the net message.
function NetHandler:Broadcast()
    net.Start(self.name)

    for k, v in ipairs(self.data) do
        if v.extras then
            net["Write" .. v.type](v.data, v.extras)
            continue
        end

        net["Write" .. v.type](v.data)
    end

    net.Broadcast()
end

PulsarLib.Net.Start = NetHandler.Start