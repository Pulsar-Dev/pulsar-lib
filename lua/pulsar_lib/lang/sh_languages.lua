PulsarLib = PulsarLib or {}

local HANDLER = PulsarLib:Include("lang/sh_handler.lua")
PulsarLib.Language = HANDLER()

PulsarLib.Language
    :PluralRule()() -- Asian (Chinese, Japanese, Korean), Persian, Turkic/Altaic (Turkish), Thai, Lao
    :PluralRule()(1)() -- Germanic (Danish, English, German), Finno-Ugric (Estonian), Language isolate (Basque), Greek, Latin, Hebrew, Romanic (Italian)
    :PluralRule()({[0] = true, [1] = true})() -- Romanic (French, Brazilian Portuguese), Lingala
    :PluralRule()(function(num)
        return tostring(num):sub(-1) == "0"
    end)(function(num)
        return num ~= 11 and tostring(num):sub(-1) == "1"
    end)() -- Baltic (Latvian, Latgalian)
    :Load()
