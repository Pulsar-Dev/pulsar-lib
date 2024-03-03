--- @class LanguageHandler
--- @field rules PluralRule[]
--- @field languages Language[]
--- @field filePath string
local HANDLER = {}
HANDLER.__index = HANDLER

local logger = PulsarLib.Logging:Get("Language")

--- Create a new language handler.
--- @return LanguageHandler
function HANDLER:New()
	return setmetatable({
		rules = {},
		languages = {},
		filePath = "languages/*.lua"
	}, HANDLER)
end

local RULE = PulsarLib:Include("lang/sh_pluralrule.lua")
--- Create a new plural rule.
--- @param id? number The ID of the plural rule.
--- @return PluralRule
function HANDLER:PluralRule(id)
	if not id then
		id = #self.rules
		if self.rules[0] then
			id = id + 1
		end
	end

	return RULE(self, id)
end

--- Register a plural rule.
--- @param id number The ID of the plural rule.
--- @param rule PluralRule The plural rule to register.
--- @return LanguageHandler
function HANDLER:RegisterRule(id, rule)
	self.rules[id] = rule
	return self
end

local LANG = PulsarLib:Include("lang/sh_language.lua")
--- Get a language.
--- @param languageCode string The language code to get.
--- @param pluralRuleId number The plural rule ID to use.
--- @return Language
function HANDLER:Language(languageCode, pluralRuleId)
	return LANG(self, languageCode, pluralRuleId)
end

--- Register a language.
--- @param code string The language code to register.
--- @param lang Language The language to register.
--- @return LanguageHandler
function HANDLER:Register(code, lang)
	self.languages[code] = lang
	return self
end

--- Load all language files.
--- @return LanguageHandler
function HANDLER:Load()
	local languageFiles = file.Find(self.filePath, "LUA")
	for _, langFile in ipairs(languageFiles) do
		PulsarLib:Include("lang/languages/" .. langFile)
	end
	return self
end

local language_convar = GetConVar("gmod_language")
local current_language = language_convar:GetString() or language_convar:GetDefault() or "en"
cvars.AddChangeCallback(language_convar:GetName(), function(_, _, val)
	current_language = val
end, "PulsarLib.Language")

--- Get the primary language code.
--- @return string
function HANDLER:PrimaryCode()
	return current_language
end

--- Get the secondary language code.
--- @return string string This is always "en".
function HANDLER:SecondaryCode()
	return "en"
end

--- Gets the primary language.
--- @return Language
function HANDLER:Primary()
	return self.languages[self:PrimaryCode()]
end

--- Gets the secondary language.
--- @return Language Language This is always the English language.
function HANDLER:Secondary()
	return self.languages[self:SecondaryCode()]
end

--- Gets a phrase from the selected language.
--- @param key string The key of the phrase to get.
--- @return string
function HANDLER:Phrase(key)
	local lang, phrase

	lang = self:Primary()
	if lang then
		phrase = lang:Get(key)
	end
	if phrase then
		return phrase
	end

	lang = self:Secondary()
	if lang then
		phrase = lang:Get(key)
	end
	if phrase then
		return phrase
	end

	return key
end

--- Gets a string pluralised from the selected language.
--- @param key string The key of the plural to get.
--- @param count number The count to check against.
--- @return string
function HANDLER:Plural(key, count)
	local lang, rule, plural

	lang = self:Primary()
	if lang then
		rule = self.rules[lang:Rule()]
		plural = lang:GetPlural(key)
	end
	if rule and plural then
		return plural:Get(rule:Check(count))
	end

	lang = self:Secondary()
	if lang then
		rule = self.rules[lang:Rule()]
		plural = lang:GetPlural(key)
	end
	if rule and plural then
		return plural:Get(rule:Check(count))
	end

	return key
end

--- Interpolate a language string.
--- The language string must be in the form "regular text {{plural_name|number_key}} {{data_key}} {{languageKey}}".
--- pluralKeys are localised with the number passed as the second argument. For example, if "computer" was a key, {{computer|2}} would become "computers".
--- dataKeys are interpolated with variables from the data parameter. data = {name = "John"}, str = "Hello {{name}}" -> "Hello John".
--- If neither of these fit, then it's passed back to the localisation system as a key.
--- If none of these work, it is replaced with "??".
--- @param str string The string to interpolate.
--- @param data table<string, any> A string keyed table of stringable parameters to pass into the localised string.
--- @return string
function HANDLER:Interpolate(str, data)
	if not data then
		data = {}
	end

	logger:Debug("Interpolating '", str, "'")

	local old = str
	local pattern = "{{([%w|_.:]+)}}"
	local substr = str:match(pattern)
	while substr do
		local t = substr:match("([%w]+):")

		if not t then
			logger:Debug("Found ", substr, " with no type, assuming data key.")
			str = str:gsub("{{" .. substr .. "}}", data[substr] or "")
		elseif t == "var" then
			logger:Debug("Found data key: ", substr)
			str = str:gsub("{{" .. substr .. "}}", data[substr:sub(#t + 2)] or "")
		elseif t == "plural" then
			local name, key = substr:match(":([%w._]+)|([%w._]+)")
			logger:Debug("Requested Plural: ", name, " with key ", key, " mapping to ", data[key])
			str = str:gsub("{{" .. substr .. "}}", self:Plural(name, data[key]))
		elseif t == "phrase" then
			local name = substr:match(":([%w._]+)")
			logger:Debug("Requested Phrase: ", name)
			str = str:gsub("{{" .. substr .. "}}", self:Phrase(name))
		elseif t == "interp" then
			local name = substr:match(":([%w._]+)")
			logger:Debug("Requested Child Interpolation: ", name)
			str = str:gsub("{{" .. substr .. "}}", self:Interpolate(self:Phrase(name), data))
		else
			str = str:gsub("{{" .. substr .. "}}", "!!" .. substr .. "!!")
		end

		if old == str then
			break
		end
		old = str
		substr = str:match(pattern)
	end

	logger:Debug("Final Result")
	logger:Debug(str)
	return str
end

--- Calls the language handler.
--- @param name string The key of the phrase to get.
--- @param data table<string, any> A string keyed table of stringable parameters to pass into the localised string.
--- @return string
function HANDLER:__call(name, data)
	return self:Interpolate(self:Phrase(name), data)
end

HANDLER = setmetatable(HANDLER, {__call = HANDLER.New})
return HANDLER
