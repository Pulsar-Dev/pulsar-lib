--- Logging Instance
-- @classmod Logger
-- @see PulsarLib.Logging
-- @alias logger

--- Create a new logger instance with the given name.
-- @internal This should not be called directly. Use @{PulsarLib.Logging.GetLogger}, @{PulsarLib.Logging.Root}, @{GetChild} or @{GetParent} instead.
-- @function logger:New(name)
-- @string name Name of the lgger to create.
-- @treturn Logger The created logger.

--- Sets the logging level of this logger.
-- @function logger:SetLevel(level)
-- @tparam number|string New logging level to set.
-- @treturn Logger

--- Gets the logging level of this logger.
-- @function logger:GetLevel()
-- @treturn number The parsed logging level of this logger.

--- Gets the name of the parent of this logger.
-- @function logger:GetParentName()
-- @treturn ?string Name of the parent, or nil if none exists.
-- @internal Use @{GetParent} instead.

--- Gets the parent logger of this logger.
-- @function logger:GetParent()
-- @treturn ?Logger Parent logger, or nil if this is the root logger.

--- Gets the name of the child name of this logger.
-- @function logger:GetChildName(name)
-- @string name The child component of the name.
-- @treturn string Child logger name.
-- @internal Use @{GetChild} instead.

--- Gets the given child logger.
-- @function logger:GetChild(name)
-- @string name The child component of the name.
-- @treturn Logger The child logger.

--- Gets the effective logging level of the logger, taking into account its parent loggers.
-- @function logger:GetEffectiveLevel()
-- @treturn number The parsed logging level.

--- Emit a log with a Fatal log level.
-- @function logger:Fatal(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a Critical log level.
-- @function logger:Critical(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a Error log level.
-- @function logger:Error(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a Warning log level.
-- @function logger:Warning(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a Info log level.
-- @function logger:Info(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a Debug log level.
-- @function logger:Debug(...)
-- @param ... Stringable arguments.
-- @treturn Logger


--- Emit a log with a level 1 trace log level.
-- @function logger:Trace1(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a level 2 trace log level.
-- @function logger:Trace2(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Emit a log with a level 3 trace log level.
-- @function logger:Trace3(...)
-- @param ... Stringable arguments.
-- @treturn Logger

--- Wrap the statements in highligt color.
-- @function logger:Highlight(...)
-- @param ... Stringable arguments.
-- @treturn table
