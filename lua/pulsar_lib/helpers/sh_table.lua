PulsarLib = PulsarLib or {}
PulsarLib.Table = PulsarLib.Table or {}

--- Get the key of a table from its ID.
--- This requires the table to have an "id" field.
--- @param tbl table The table to get the key from.
--- @param id any The ID to get the key for.
--- @return any
function PulsarLib.Table.KeyFromID(tbl, id) -- Used instead of table.KeyFromValue because that checks all values but we only want to check the id.
    for k, v in pairs(tbl) do
        if v.id == id or tonumber(v.id) == id then
            return k
        end
    end
end

--- Remove an entry from a table by its ID.
--- This requires the table to have an "id" field.
--- @param tbl table The table to remove the entry from.
--- @param id any The ID of the entry to remove.
function PulsarLib.Table.RemoveByID(tbl, id)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if not key then
        PulsarLib.Logging:Error("Attempted to remove a table entry that doesn't exist!")
        debug.Trace()
        return
    end
    tbl[key] = nil
end

--- Update an entry in a table by its ID.
--- This requires the table to have an "id" field.
--- @param tbl table The table to update the entry in.
--- @param id any The ID of the entry to update.
--- @param newTbl table The new table to replace the old one with.
function PulsarLib.Table.UpdateByID(tbl, id, newTbl)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if key then
        tbl[key] = newTbl
    end
end

--- Get an entry from a table by its ID.
--- This requires the table to have an "id" field.
--- @param tbl table The table to get the entry from.
--- @param id any The ID of the entry to get.
--- @return table?
function PulsarLib.Table.GetByID(tbl, id)
    local key = PulsarLib.Table.KeyFromID(tbl, id)
    if key then
        return tbl[key]
    end

    return nil
end

--- Filter a table by a predicate.
--- @param tbl table The table to filter.
--- @param predicate fun(value: any): boolean The predicate to filter by.
--- @return table
function PulsarLib.Table.Filter(tbl, predicate)
    local result = {}
    for i, v in pairs(tbl) do
        if predicate(v) then
            table.insert(result, v)
        end
    end
    return result
end

--- Prints the types of all the keys and values in a table.
function PulsarLib.PrintTableTypes(tbl, indent)
    indent = indent or 0
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. k .. " (" .. type(k) .. "): "
        if type(v) == "table" then
            print(formatting)
            PulsarLib.PrintTableTypes(v, indent + 1)
        else
            print(formatting .. tostring(v) .. " (" .. type(v) .. ")")
        end
    end
end