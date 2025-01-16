local pairs = pairs
local type = type
local next = next
local unpack = unpack
local table_Copy = table.Copy
local table_insert = table.insert
local table_remove = table.remove
local table_Count = table.Count
local table_IsEmpty = table.IsEmpty
local string_sub = string.sub
local util_TableToJSON = util.TableToJSON
local util_Compress = util.Compress

PulsarLib.Updatr = PulsarLib.Updatr or {}
PulsarLib.Updatr.RegisteredTables = PulsarLib.Updatr.RegisteredTables or {}

local logger = PulsarLib.Logging:Get("Updatr")

PulsarLib.Net.String("Updatr.TableUpdates")
PulsarLib.Net.String("Updatr.TableData")

function PulsarLib.Updatr.GetTableGlobalName(targetTable)
	local seenTables = {}
	local stack = { { _G, "_G" } }

	while #stack > 0 do
		local currentTable, currentTableName = unpack(table_remove(stack))

		if currentTable == targetTable then
			return string_sub(currentTableName, 4) -- Remove the "_G." prefix
		end

		seenTables[currentTable] = true

		for name, tbl in pairs(currentTable) do
			if type(name) == "table" then continue end
			if type(tbl) == "table" and not seenTables[tbl] then
				if type(name) == "Player" or type(name) == "Entity" then
					name = name:GetName()
				end

				table_insert(stack, { tbl, currentTableName .. "." .. name })
			end
		end
	end

	return nil
end

function PulsarLib.Updatr.RegisterTable(t, ignoreList)
	local tableName = PulsarLib.Updatr.GetTableGlobalName(t)
	if not tableName then
		error("Unable to register table, table is not a global table or cannot be found")
		return
	end

	PulsarLib.Updatr.RegisteredTables[tableName] = { table = t, ignoreList = ignoreList or {} }
	logger:Debug("Registered table " .. tableName)
end

function PulsarLib.Updatr.GetUpdatedSubTables(newTable, oldTable, ignoreList, isSubTable)
	local updates = {}
	local tableName = PulsarLib.Updatr.GetTableGlobalName(newTable)
	if not tableName and not isSubTable then
		logger:Debug("Table is not a global table")
		return
	end

	ignoreList = ignoreList or PulsarLib.Updatr.RegisteredTables[tableName] and PulsarLib.Updatr.RegisteredTables[tableName].ignoreList

	for key, value in pairs(newTable) do
		if ignoreList and ignoreList[tostring(key)] and type(key) ~= "number" then
			continue
		end

		if type(value) == "table" then
			if oldTable[key] == nil then
				updates[key] = value
			else
				local subUpdates = PulsarLib.Updatr.GetUpdatedSubTables(value, oldTable[key], tableName, true) or {}
				if next(subUpdates) ~= nil then
					updates[key] = subUpdates
				end
			end
		elseif oldTable[key] ~= value then
			updates[key] = value
		end
	end

	for key, _ in pairs(oldTable) do
		if newTable[key] == nil then
			updates[key] = "Updatr.REMOVEDKEYVALUE"
		end
	end

	local updateCount = table_Count(updates)
	if updateCount ~= 0 then
		logger:Debug("Found " .. updateCount .. " updates")
	end

	return updates
end

function PulsarLib.Updatr.TableCompare(t1, t2)
	for key, value in pairs(t1) do
		if type(value) == "table" then
			if type(t2[key]) ~= "table" or not PulsarLib.Updatr.TableCompare(value, t2[key]) then
				return false
			end
		elseif value ~= t2[key] then
			return false
		end
	end

	for key, value in pairs(t2) do
		if type(value) == "table" then
			if type(t1[key]) ~= "table" or not PulsarLib.Updatr.TableCompare(value, t1[key]) then
				return false
			end
		elseif value ~= t1[key] then
			return false
		end
	end

	return true
end

function PulsarLib.Updatr.SendUpdates(newTable, oldTable)
	local tableName = PulsarLib.Updatr.GetTableGlobalName(newTable)
	if not tableName then
		logger:Error("Table is not a global table")
		return
	end

	if not PulsarLib.Updatr.RegisteredTables[tableName] then
		logger:Fatal("Table " .. tableName .. " is not registered")

		return
	end

	logger:Debug("Broadcasting updates for table " .. tableName)

	local updates = PulsarLib.Updatr.GetUpdatedSubTables(newTable, oldTable, PulsarLib.Updatr.RegisteredTables[tableName].ignoreList)

	if not updates or table_IsEmpty(updates) then
		logger:Debug("No updates found, skipping broadcast")

		return
	end

	local serializedUpdates = util_TableToJSON(updates)
	local compressedUpdates = util_Compress(serializedUpdates)

	PulsarLib.Net.Start("Updatr.TableUpdates")
		:WriteString(tableName)
		:WriteUInt(#compressedUpdates, 32)
		:WriteData(compressedUpdates, #compressedUpdates)
	:Broadcast()

	logger:Debug("Broadcasted updates for table " .. tableName)
end

local function removeIgnoredKeys(t, ignoreList)
	local ignoredTable = table_Copy(t)
	for key, value in pairs(t) do
		if ignoreList and ignoreList[key] then
			ignoredTable[key] = nil
		elseif type(value) == "table" then
			removeIgnoredKeys(value, ignoreList)
		end
	end

	return ignoredTable
end

function PulsarLib.Updatr.SendTableToClient(ply, tableName, t)
	local ignoredTable = removeIgnoredKeys(t, PulsarLib.Updatr.RegisteredTables[tableName].ignoreList)
	local serializedTable = util_TableToJSON(ignoredTable)
	local compressedTable = util_Compress(serializedTable)

	logger:Debug("Sending table " .. tableName .. " to " .. ply:Nick())

	PulsarLib.Net.Start("Updatr.TableData")
		:WriteString(tableName)
		:WriteUInt(#compressedTable, 32)
		:WriteData(compressedTable, #compressedTable)
	:Send(ply)
end

local loadQueue = {}

hook.Add("PlayerInitialSpawn", "Updatr.PlayerLoad", function(ply)
	loadQueue[ply] = true
end)

hook.Add("SetupMove", "Updatr.PlayerSetupMove", function(ply, _, cmd)
	if not loadQueue[ply] then return end
	if cmd:IsForced() then return end
	loadQueue[ply] = nil

	logger:Debug("Sending all tables to " .. ply:Nick())
	for tableName, t in pairs(PulsarLib.Updatr.RegisteredTables) do
		PulsarLib.Updatr.SendTableToClient(ply, tableName, t.table)
	end
end)
