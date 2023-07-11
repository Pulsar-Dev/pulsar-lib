local LANG = {}
LANG.__index = LANG

function LANG:New(languageHandler, code, pluralRule)
    return setmetatable({
        stored = {},
        plurals = {},
        handler = languageHandler,
        code = code,
        rule = pluralRule
    }, LANG)
end

function LANG:Set(key, phrase)
    self.stored[key] = phrase
    return self
end

function LANG:Get(key)
    return self.stored[key]
end

function LANG:SetPlural(key, plural)
    self.plurals[key] = plural
    return self
end

function LANG:GetPlural(key)
    return self.plurals[key]
end

local PLURAL = PulsarLib:Include("lang/sh_plural.lua")
function LANG:Plural(key, value)
    if not self.registered then
        return PLURAL(self, key)
    else
        return self:GetPlural(key)(self.rule:Check(value))
    end
end

function LANG:Rule()
    return self.rule
end

function LANG:Register()
    self.registered = true
    return self.handler:Register(self.code, self)
end

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