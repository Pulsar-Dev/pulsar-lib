PulsarLib = PulsarLib or {}
PulsarLib.Table = PulsarLib.Table or {}

function PulsarLib.Table.KeyFromID(tbl, id) -- Used instead of table.KeyFromValue because that checks all values but we only want to check the id.
    for k, v in pairs(tbl) do
        if v.id == id or tonumber(v.id) == id then
            return k
        end
    end
end

function PulsarLib.Table.RemoveByID(tbl, id)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if not key then
        PulsarLib.Logging:Error("Attempted to remove a table entry that doesn't exist!")
        debug.Trace()
        return
    end
    tbl[key] = nil
end

function PulsarLib.Table.UpdateByID(tbl, id, newTbl)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if key then
        tbl[key] = newTbl
    end
end

function PulsarLib.Table.GetByID(tbl, id)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if key then
        return tbl[key]
    end
end

function PulsarLib.PrintTableTypes(tbl, indent)
    indent = indent or 0
    for k, v in pairs(tbl) do
        formatting = string.rep("  ", indent) .. k .. " (" .. type(k) .. "): "
        if type(v) == "table" then
            print(formatting)
            PulsarLib.PrintTableTypes(v, indent + 1)
        else
            print(formatting .. tostring(v) .. " (" .. type(v) .. ")")
        end
    end
end

function PulsarLib.Table.Filter(tbl, predicate)
    local result = {}
    for i, v in pairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end