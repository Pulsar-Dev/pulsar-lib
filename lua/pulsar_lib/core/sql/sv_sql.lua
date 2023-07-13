PulsarLib = PulsarLib or {}
PulsarLib.SQL = PulsarLib.SQL or setmetatable({
	stored = {}
}, {__index = PulsarLib})

local SQL = PulsarLib.SQL

file.CreateDir("pulsarlib")

function SQL:FetchDetails()
	local details = {
		UsingMySQL = false
	}
	if file.Exists("pulsarlib/mysql.json", "DATA") then
		local data = file.Read("pulsarlib/mysql.json", "DATA")
		details = util.JSONToTable(data)
	end

	if details.UsingMySQL then
		require("mysqloo")
	end

	self.Details = details
	return details
end

function SQL:ConnectMySQL()
	if self.Connection then return end

	self.Connection = mysqloo.connect(self.Details.Hostname, self.Details.Username, self.Details.Password, self.Details.Database, self.Details.Port)

	self.Connection.onConnected = function()
		PulsarLib.Logging.Info("Successfully connected to mysql database")
		hook.Run("PulsarLib.SQL.Connected")
	end

	self.Connection.onConnectionFailed = function(_, err)
		PulsarLib.Logging.Error("Failed to connect to mysql database: " .. err)
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

SQL:Connect()

local sqliteReplaces = {
	["AUTO_INCREMENT"] = "AUTOINCREMENT",
	["LAST_INSERT_ID()"] = "last_insert_rowid()",
	["IGNORE"] = " OR IGNORE"
}

local emptyFunction = function() end

function SQL:RawQuery(query, onSuccess, onError)
	onSuiccess = onSuccess or emptyFunction
	onError = onError or emptyFunction

	if self.Details.UsingMySQL then
		local queryObj = self.Connection:query(query)

		queryObj.onSuccess = function(_, data)
			onSuccess(data)
		end

		queryObj.onError = function(_, err)
			PulsarLib.Logging.Fatal("MySQL query failed!")
			PulsarLib.Logging.Fatal(err)
			PulsarLib.Logging.Fatal(query)
			onError(err)
		end

		queryObj:start()
	else
		for k, v in pairs(sqliteReplaces) do
			query = string.Replace(query, k, v)
		end

		local x = string.Split(query, "\n")
		for _, line in ipairs(x) do
			PulsarStore.Logging.Debug(line)
		end
		query = sql.Query(query)

		if query == false then
			PulsarLib.Logging.Fatal("SQL query failed!")
			PulsarLib.Logging.Fatal(sql.LastError())
			onError(sql.LastError())
		else
			onSuccess(query)
		end
	end
end

function SQL:Escape(str)
	if self.Details.UsingMySQL then
		return self.Connection:escape(str)
	else
		return sql.SQLStr(str)
	end
end