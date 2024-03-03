--- @class Language
--- @field stored table<string, string>
--- @field plurals table<string, function>
--- @field handler LanguageHandler
--- @field code string
--- @field rule PluralRule
local LANG = {}
LANG.__index = LANG

--- Creates a new language
--- @param languageHandler LanguageHandler
--- @param code string
--- @param pluralRule PluralRule
--- @return Language
function LANG:New(languageHandler, code, pluralRule)
    return setmetatable({
        stored = {},
        plurals = {},
        handler = languageHandler,
        code = code,
        rule = pluralRule
    }, LANG)
end

--- Sets a phrase
--- @param key string
--- @param phrase string
--- @return Language
function LANG:Set(key, phrase)
    self.stored[key] = phrase
    return self
end

--- Gets a phrase from a key
--- @param key string
--- @return string
function LANG:Get(key)
    return self.stored[key]
end

--- Sets a plural string
--- @param key string
--- @param plural any? ive got no idea what type this needs to be
--- @return Language
function LANG:SetPlural(key, plural)
    self.plurals[key] = plural
    return self
end

--- Gets a plural from a key
--- @param key string
--- @return function
function LANG:GetPlural(key)
    return self.plurals[key]
end

local PLURAL = PulsarLib:Include("lang/sh_plural.lua")
--- Gets a plural from a key
--- @param key string
--- @param value number
--- @return string
function LANG:Plural(key, value)
    if not self.registered then
        return PLURAL(self, key)
    else
        return self:GetPlural(key)(self.rule:Check(value))
    end
end

--- Gets the language rule
--- @return PluralRule
function LANG:Rule()
    return self.rule
end

--- Registers the language
--- @return LanguageHandler
function LANG:Register()
    self.registered = true
    return self.handler:Register(self.code, self)
end

--- stuff?
--- @param key string
--- @param phrase string
--- @return LanguageHandler|Language|string
function LANG:__call(key, phrase)
    if key == nil then
        return self:Register()
    end

    if self.registered then
        return self:Get(key)
    else
        return self:Set(key, phrase)
    end
end

LANG = setmetatable(LANG, {__call = LANG.New})
return LANG