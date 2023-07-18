PulsarLib = PulsarLib or {}
PulsarLib.SQL = PulsarLib.SQL or setmetatable({
	stored = {}
}, {__index = PulsarLib})

local SQL = PulsarLib.SQL
local logger = PulsarLib.Logging:Get("Database")

file.CreateDir("pulsarlib")

function SQL:FetchDetails()
	local details = {
		UsingMySQL = false
	}
	if file.Exists("pulsarlib/mysql.json", "DATA") then
		local data = file.Read("pulsarlib/mysql.json", "DATA")
		details = util.JSONToTable(data)
	else
		file.Write("pulsarlib/mysql.json", util.TableToJSON({
			["UsingMySQL"] = false,
			["Hostname"] = "",
			["Port"] = 3306,
			["Username"] = "",
			["Password"] = "",
			["Database"] = ""
		}, true))
		logger:Info("Created mysql.json in `garrysmod/data/pulsarlib/`. If you wish to use mysql, fill out these details.")
	end

	if details.UsingMySQL then
		require("mysqloo")
	end

	self.Details = details
	return details
end

function SQL:ConnectMySQL()
	if self.Connection then return end

	local details = self.Details
	self.Connection = mysqloo.connect(details.Hostname, details.Username, details.Password, details.Database, details.Port)

	self.Connection.onConnected = function()
		logger:Info("Successfully connected to mysql database")
		hook.Run("PulsarLib.SQL.Connected")
	end

	self.Connection.onConnectionFailed = function(_, err)
		logger:Error("Failed to connect to mysql database: " .. err)
		hook.Run("PulsarLib.SQL.ConnectionFailed")
	end

	self.Connection:connect()
end

function SQL:ConnectSQLite()
	hook.Run("PulsarLib.SQL.Connected")
end

function SQL:Connect()
	self:FetchDetails()

	if self.Details.UsingMySQL then
		self:ConnectMySQL()
	else
		self:ConnectSQLite()
	end
end

function SQL:IsMySQL()
	return self.Details.UsingMySQL == true
end

hook.Add("Think", "PulsarLib.ConnectToSQL", function()
	hook.Remove("Think", "PulsarLib.ConnectToSQL")
	SQL:Connect()
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
	["IGNORE"] = " OR IGNORE"
}

local emptyFunction = function() end

function SQL:RawQuery(query, onSuccess, onError)
	onSuccess = onSuccess or emptyFunction
	onError = onError or emptyFunction

	if self.Details.UsingMySQL then
		local queryObj = self.Connection:query(query)

		queryObj.onSuccess = function(_, data)
			onSuccess(data)
		end

		queryObj.onError = function(_, err)
			logger:Fatal("Raw MySQL query failed!")
			logger:Fatal(err)
			logger:Fatal(query)
			onError(err)
		end

		queryObj:start()
	else
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
end

function SQL:PreparedQuery(query, values, onSuccess, onError)
	onSuccess = onSuccess or emptyFunction
	onError = onError or emptyFunction

	self:FetchDetails()

	if self.Details.UsingMySQL then
		local queryObj = self.Connection:prepare(query)

		queryObj.onSuccess = function(_, data)
			logger:Debug("Prepared MySQL query succeeded!")
			logger:Debug(SQL:prepareStatement(query, values))
			onSuccess(data)
		end

		queryObj.onError = function(_, err)
			logger:Fatal("Prepared MySQL query failed!")
			logger:Fatal(err)
			logger:Fatal(SQL:prepareStatement(query, values))
			onError(err)
		end

		for k, v in ipairs(values or {}) do
			if type(v) == "string" then
				queryObj:setString(k, v)
			elseif type(v) == "number" then
				queryObj:setNumber(k, v)
			elseif type(v) == "boolean" then
				queryObj:setBoolean(k, v)
			elseif v == nil then
				queryObj:setNull(k)
			end
		end
		queryObj:start()
	else
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
end

function SQL:Escape(str)
	if self.Details.UsingMySQL then
		return "'" .. self.Connection:escape(str) .. "'"
	else
		return sql.SQLStr(str)
	end
end
