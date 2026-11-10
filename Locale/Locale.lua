-- Idiomas del addon.
-- El texto vive en Locale/<codigo>.properties.
-- Para dar de alta otro idioma:
--   1. Crea Locale/<codigo>.properties (mismo formato clave=valor).
--   2. Crea Locale/<codigo>.lua copiando es.lua y cambiando el código.
--   3. Añade una línea en Locale/alta.lua.
--   4. Carga ese .lua en LevelGuide.toc, antes de Locale/alta.lua.
-- WoW no abre ficheros sueltos: el .lua solo incrusta el texto del .properties.

local _, NS = ...

NS.PropertyText = NS.PropertyText or {}
NS.locales = {}
NS.localeOrder = {}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unescape(s)
    s = s:gsub("\\n", "\n")
    s = s:gsub("\\t", "\t")
    s = s:gsub("\\\\", "\\")
    return s
end

function NS.ParseProperties(text)
    local out = {}
    if not text then return out end
    for line in (text .. "\n"):gmatch("(.-)\n") do
        line = trim(line)
        if line ~= "" and line:sub(1, 1) ~= "#" and line:sub(1, 1) ~= "!" then
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                out[trim(key)] = unescape(value or "")
            end
        end
    end
    return out
end

function NS.RegisterLocale(code, name, text)
    if NS.locales[code] then return end
    NS.locales[code] = { code = code, name = name, s = NS.ParseProperties(text) }
    NS.localeOrder[#NS.localeOrder + 1] = code
end

function NS.Lang()
    local code = NS.cfg and NS.cfg.lang
    if code and NS.locales[code] then return code end
    if NS.locales.es then return "es" end
    return NS.localeOrder[1]
end

function NS.L(key)
    local code = NS.Lang()
    local pack = code and NS.locales[code]
    local value = pack and pack.s[key]
    if value == nil and NS.locales.es then value = NS.locales.es.s[key] end
    if value == nil then return key end
    return value
end

function NS.Lf(key, ...)
    local pattern = NS.L(key)
    local ok, text = pcall(string.format, pattern, ...)
    if ok then return text end
    return pattern
end

function NS.DungeonName(en)
    if not en or en == "" then return nil end
    local name = en:gsub("^Mazmorra:%s*", ""):gsub("^Dungeon:%s*", "")
    local key = "dg." .. name
    local value = NS.L(key)
    if value == key then return name end
    return value
end
