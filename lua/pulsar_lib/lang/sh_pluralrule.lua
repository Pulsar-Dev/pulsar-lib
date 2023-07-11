local RULE = {}
RULE.__index = RULE

function RULE:New(languageHandler, id)
    return setmetatable({
        handler = languageHandler,
        id = id,
        rules = {}
    }, RULE)
end

function RULE:Add(check)
    table.insert(self.rules, check)
    return self
end

--- Check a number against this rule.
-- @number num The number to check with.
-- @rnumber The plural form index to use for this number.
function RULE:Check(num)
    for i, check in ipairs(self.rules) do
        if isfunction(check) and check(num) then
            return i
        elseif istable(check) and check[num] then
            return i
        elseif isnumber(check) and check == num then
            return i
        elseif isbool(check) and check then
            return i
        end
    end

    return #self.rules + 1
end

function RULE:Register()
    self.registered = true
    return self.handler:RegisterRule(self.id, self)
end

function RULE:__call(val)
    if val == nil then
        return self:Register()
    end
    if not self.registered then
        return self:Add(val)
    end

    return self:Check(val)
end

RULE = setmetatable(RULE, {__call = RULE.New})
return RULE
