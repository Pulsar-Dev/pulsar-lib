PulsarLib = PulsarLib or {}
PulsarLib.Net = PulsarLib.Net or {}
PulsarLib.NetworkQueue = PulsarLib.NetworkQueue or {}

function PulsarLib.Net.Receive(name, func)
    net.Receive("PulsarLib." .. name, function(len)
        func(len, ply)
    end)
end

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
            extras
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

function NetHandler:Send()
    table.insert(PulsarLib.NetworkQueue, self)

    if #PulsarLib.NetworkQueue == 1 then
        processQueue()
    end
end

PulsarLib.Net.Start = NetHandler.Start

function PulsarLib.Net.DumpQueue()
    PulsarLib.NetworkQueue = {}
end