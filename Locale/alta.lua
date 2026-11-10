-- Alta de idiomas. El texto de cada uno está en su .properties.
local _, NS = ...

local ALTA = {
    { "es", "Español" },
    { "en", "English" },
}

for _, row in ipairs(ALTA) do
    local code, name = row[1], row[2]
    local text = NS.PropertyText and NS.PropertyText[code]
    if text then
        NS.RegisterLocale(code, name, text)
    end
end
