PulsarLib.SQL = PulsarLib.SQL or {}

PulsarLib.SQL.Migrations = PulsarLib.SQL.Migrations or {}
PulsarLib.SQL.Migrations.Ran = PulsarLib.SQL.Migrations.Ran or {}
PulsarLib.SQL.Migrations.Stored = PulsarLib.SQL.Migrations.Stored or {}
PulsarLib.SQL.Migrations.Logging = PulsarLib.SQL.Migrations.Logging or PulsarLib.Logging:Get("Migrations")

PulsarLib.SQL.Migrations.filePath = "pulsar_lib/migrations"
PulsarLib.SQL.Migrations._migrator = include("sv_migrator.lua")

--- Creates a new Migrator
--- @param name string|table The name of the migrator.
--- @param up function|number? The function to run when migrating up.
--- @param down function The function to run when migrating down.
--- @return MIGRATOR
function PulsarLib.SQL.Migrations:Migrator(name, up, down)
	return self._migrator:New(name, up, down)
end

--- Loads the ran migrations from the database.
--- @param callback function The function to call when the migrations have been loaded.
function PulsarLib.SQL.Migrations:LoadRan(callback)
	callback = callback or function() end
	PulsarLib.SQL:RawQuery("SELECT `migration` FROM `pulsarlib_migrations` WHERE `addon` = " .. PulsarLib.SQL:Escape(self.parent.name), function(data)
		if data and istable(data) then
			for _, row in ipairs(data) do
				self.Ran[row["migration"]] = true
			end
		end

		callback()
	end)
end

--- Loads the stored migrations from the file system.
--- @param callback function The function to call when the migrations have been loaded.
function PulsarLib.SQL.Migrations:LoadStored(callback)
	local migrations = file.Find(self.filePath .. "/*.lua", "LUA")
	for _, migration in ipairs(migrations) do
		local id, sort = migration:match("sv_((%d+)-[%w%s-_]+).lua$")
		if not id or not sort then
			self.Logging:Error("Failed to read migration ID or Sort Order: " .. migration)
			return
		end

		local dt = include(self.filePath .. "/sv_" .. id .. ".lua")
		if isstring(dt) then
			self.Stored[id] = self:Migrator(id, tonumber(sort), function(slf, done)
				return PulsarLib.SQL:RawQuery(dt, done, function(err)
					PulsarLib.Logging:Fatal("Failed to run migration " .. id .. ": " .. err)
				end)
			end)
		elseif isfunction(dt) then
			self.Stored[id] = self:Migrator(id, tonumber(sort), dt)
		elseif istable(dt) then
			self.Stored[id] = self:Migrator(id, sort, dt.up)
		else
			self.Logging:Warning("Invalid Migration Format: " .. migration)
		end
	end

	if callback then
		return callback()
	end
end

--- Runs the migrations.
--- @param callback function The function to call when the migrations have been run.
function PulsarLib.SQL.Migrations:Run(callback)
	self.queue = {}
	for _, migration in SortedPairsByMemberValue(self.Stored, "sort") do
		if not self.Ran[migration.name] then
			table.insert(self.queue, migration)
		end
	end

	self:Next()

	if callback then
		callback()
	end
end

--- Runs the next migration in the queue.
function PulsarLib.SQL.Migrations:Next()
	if not self.queue or #self.queue == 0 then
		self.queue = nil
		return
	end

	local migration = table.remove(self.queue, 1)

	migration:Up(function()
		return PulsarLib.SQL:RawQuery(
			"INSERT INTO `pulsarlib_migrations` (`migration`, `addon`) VALUES (" .. PulsarLib.SQL:Escape(migration.name) .. ", " .. PulsarLib.SQL:Escape(self.parent.name) .. ");",
			function()
				return self:Next()
			end,
			function()
				PulsarLib.Logging:Fatal("Failed to run migration " .. migration.name .. ". Aborting all next migrations.")
			end
		)
	end)
end

--- Runs all the migrations.
function PulsarLib.SQL.Migrations:RunAll()
	self.Logging:Debug("Running migrations for addon " .. self.parent.name)

	local canRun, reason = hook.Run("PulsarLib.SQL.Migrations.Start", self.parent.name)

	if canRun == false then
		self.Logging:Warning("Migrations for addon " .. self.parent.name .. " were cancelled" .. (reason and ": " .. reason or ""))
		return
	end

	return self:LoadRan(function()
		return self:LoadStored(function()
			return self:Run(function()
				self.Logging:Info("Migrations Complete")
				hook.Run("PulsarLib.SQL.Migrations.Ran", self.parent.name)
				self.parent.MigrationsRan = true
			end)
		end)
	end)
end
