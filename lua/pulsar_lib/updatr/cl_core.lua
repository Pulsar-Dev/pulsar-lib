local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local net_ReadData = net.ReadData
local util_Decompress = util.Decompress
local util_JSONToTable = util.JSONToTable
local string_Explode = string.Explode

PulsarLib.Updatr = PulsarLib.Updatr or {}
PulsarLib.Updatr.ReceivedData = PulsarLib.Updatr.ReceivedData or {}

local logger = PulsarLib.Logging:Get("Updatr")

function PulsarLib.Updatr.ApplyUpdates(tbl, updates)
    for key, value in pairs(updates) do
        if value == "Updatr.REMOVEDKEYVALUE" then
            tbl[key] = nil
        elseif type(value) == "table" then
            if not tbl then
                logger:Fatal("Table is missing! This is bad!")

                if PulsarLib.DevelopmentMode then
                    logger:Fatal("Updatr Table Debug: ")
                    PrintTable(updates)
                end
            end

            if not tbl[key] then
                tbl[key] = value
            else
                PulsarLib.Updatr.ApplyUpdates(tbl[key], value)
            end
        else
            tbl[key] = value
        end
    end

    logger:Debug("Applied updates to table")
end

PulsarLib.Net.Receive("Updatr.TableData", function()
    local tableName = net_ReadString()
    local dataLength = net_ReadUInt(32)
    local compressedData = net_ReadData(dataLength)
    local serializedTable = util_Decompress(compressedData)
    local t = util_JSONToTable(serializedTable)

    local path = string_Explode(".", tableName)
    local tableToUpdate = _G
    for i = 1, #path - 1 do
        tableToUpdate = tableToUpdate[path[i]]
    end

    tableToUpdate[path[#path]] = t

    logger:Debug("Received table data for " .. tableName)

    hook.Run("Updatr.TableDataReceived", tableName)
    PulsarLib.Updatr.ReceivedData[tableName] = t
end)


PulsarLib.Net.Receive("Updatr.TableUpdates", function()
    local tableName = net_ReadString()
    local dataLength = net_ReadUInt(32)
    local compressedData = net_ReadData(dataLength)
    local serializedUpdates = util_Decompress(compressedData)
    local updates = util_JSONToTable(serializedUpdates)

    local path = string_Explode(".", tableName)
    local tableToUpdate = _G
    for i = 1, #path - 1 do
        tableToUpdate = tableToUpdate[path[i]]
    end

    PulsarLib.Updatr.ApplyUpdates(tableToUpdate[path[#path]], updates)

    logger:Debug("Received table updates for " .. tableName)

    if PulsarLib.DevelopmentMode then
        logger:Debug("Updatr Table Debug: ")
        PrintTable(tableToUpdate)
    end

    hook.Run("Updatr.TableUpdatesReceived", tableName)
end)
