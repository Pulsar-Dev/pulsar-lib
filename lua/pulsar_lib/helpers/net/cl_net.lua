PulsarLib = PulsarLib or {}
PulsarLib.Net = PulsarLib.Net or {}
PulsarLib.NetworkQueue = PulsarLib.NetworkQueue or {}

--- Receives a net message.
--- @param name string The name of the net message to receive.
--- @param func fun(len: integer) The function to call when the net message is received.
function PulsarLib.Net.Receive(name, func)
    net.Receive("PulsarLib." .. name, function(len)
        func(len)
    end)
end

--- Sends a net message to the server
function PulsarLib.Net.Send()
    return net.SendToServer()
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

local function processQueue()
    if PulsarLib.NetworkQueue[1] then
        local messageData = PulsarLib.NetworkQueue[1]

        net.Start(messageData.name)

        for k, v in ipairs(messageData.data) do
            if v.extras then
                net["Write" .. v.type](v.data, v.extras)
                continue
            end

            net["Write" .. v.type](v.data)
        end

        net.SendToServer()

        local time = (PulsarLib.AdminUserGroups[PulsarLib.GetRank(LocalPlayer())] or PulsarLib.AdminUserGroups[PulsarLib.GetRank(LocalPlayer(), true)]) and 0 or 2
        timer.Create("PulsarLib.NetworkQueue", time, 1, function()
            table.remove(PulsarLib.NetworkQueue, 1)
            processQueue()
        end)
    end
end

--- Sends the net message to the server through the net queue.
function NetHandler:Send()
    table.insert(PulsarLib.NetworkQueue, self)

    if #PulsarLib.NetworkQueue == 1 then
        processQueue()
    end
end

PulsarLib.Net.Start = NetHandler.Start

--- Dumps the network queue.
--- WARNING: This will fully clear the network queue. Data WILL be lost. Use with caution.
function PulsarLib.Net.DumpQueue()
    PulsarLib.NetworkQueue = {}
end