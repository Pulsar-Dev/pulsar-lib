local PLURAL = {}
PLURAL.__index = PLURAL

function PLURAL:New(lang, id)
    return setmetatable({
        forms = {},
        id = id,
        lang = lang
    }, PLURAL)
end

function PLURAL:Set(form, value)
    self.forms[form] = value
    return self
end

function PLURAL:Add(value)
    table.insert(self.forms, value)
    return self
end

function PLURAL:Get(form)
    return self.forms[form]
end

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

function PLURAL:Register()
    self.registered = true
    return self.lang:SetPlural(self.id, self)
end

PLURAL = setmetatable(PLURAL, {__call = PLURAL.New})
return PLURAL
