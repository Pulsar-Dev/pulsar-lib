--- @class Plural
--- @field forms table<string, string>
--- @field id string
--- @field lang Language
--- @field registered boolean
local PLURAL = {}
PLURAL.__index = PLURAL

--- Creates a new plural
--- @param lang Language
--- @param id string
--- @return Plural
function PLURAL:New(lang, id)
    return setmetatable({
        forms = {},
        id = id,
        lang = lang
    }, PLURAL)
end

--- Sets a plural form
--- @param form string
--- @param value string
function PLURAL:Set(form, value)
    self.forms[form] = value
    return self
end

--- Adds a plural form
--- @param value string
--- @return Plural
function PLURAL:Add(value)
    table.insert(self.forms, value)
    return self
end

--- Gets a plural form
--- @param form string
--- @return string
function PLURAL:Get(form)
    return self.forms[form]
end

--- stuff?
--- @param val string
--- @return Plural|string|Language
function PLURAL:__call(val)
    if val == nil then
        return self:Register()
    end

    if not self.registered then
        return self:Add(val)
    else
        return self:Get(val)
    end
end

--- Registers the plural
--- @return Language
function PLURAL:Register()
    self.registered = true
    return self.lang:SetPlural(self.id, self)
end

PLURAL = setmetatable(PLURAL, {__call = PLURAL.New})
return PLURAL
