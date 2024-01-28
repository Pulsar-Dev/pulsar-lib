PulsarLib = PulsarLib or {}
PulsarLib.SQL = PulsarLib.SQL or setmetatable({
	stored = {}
}, {__index = PulsarLib})

local SQL = PulsarLib.SQL
local logger = PulsarLib.Logging:Get("Database")

function SQL:IsConnected()
	return PulsarLib.SQL.Connected == true
end

hook.Add("Think", "PulsarLib.ConnectToSQL", function()
	hook.Remove("Think", "PulsarLib.ConnectToSQL")
	hook.Run("PulsarLib.SQL.Connected")
	PulsarLib.SQL.Connected = true
end)

-- Manually replace ? with values in a query
function SQL:prepareStatement(query, values)
	values = values or {}
	local newQuery = ""
	local i = 1
	local last = 0

	while true do
		local start, stop = string.find(query, "?", last + 1, true)
		if not start then break end
		newQuery = newQuery .. string.sub(query, last + 1, start - 1)
		local value = values[i]

		if value == nil then
			newQuery = newQuery .. "NULL"
		elseif type(value) == "string" then
			newQuery = newQuery .. self:Escape(value)
		elseif type(value) == "boolean" then
			newQuery = newQuery .. (value and "1" or "0")
		elseif tonumber(value) then
			newQuery = newQuery .. value
		else
			logger:Fatal("Invalid value type for prepared statement, expected nil, string, boolean or number, got " .. type(value) .. "\n" .. debug.traceback())
			return
		end

		last = stop
		i = i + 1
	end

	newQuery = newQuery .. string.sub(query, last + 1)

	return newQuery
end

local sqliteReplaces = {
	["AUTO_INCREMENT"] = "AUTOINCREMENT",
	["LAST_INSERT_ID()"] = "last_insert_rowid()",
	["IGNORE"] = " OR IGNORE",
}

local emptyFunction = function() end

function SQL:RawQuery(query, onSuccess, onError)
	onSuccess = onSuccess or emptyFunction
	onError = onError or emptyFunction

	for k, v in pairs(sqliteReplaces) do
		query = string.Replace(query, k, v)
	end

	local x = string.Split(query, "\n")
	for _, line in ipairs(x) do
		logger:Trace1(line)
	end
	query = sql.Query(query)

	if query == false then
		logger:Fatal("SQL query failed!")
		logger:Fatal(sql.LastError())
		onError(sql.LastError())
	else
		onSuccess(query)
	end
end

function SQL:PreparedQuery(query, values, onSuccess, onError)
	onSuccess = onSuccess or emptyFunction
	onError = onError or emptyFunction

	for k, v in pairs(sqliteReplaces) do
		query = string.Replace(query, k, v)
	end

	local x = string.Split(query, "\n")
	for _, line in ipairs(x) do
		logger:Debug(line)
	end

	query = SQL:prepareStatement(query, values)

	query = sql.Query(query)

	if query == false then
		logger:Fatal("SQL query failed!")
		logger:Fatal(sql.LastError())
		onError(sql.LastError())
	else
		onSuccess(query)
	end
end

function SQL:Escape(str)
	return sql.SQLStr(str)
end