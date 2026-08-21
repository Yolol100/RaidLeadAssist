local function read(path)
    local file = assert(io.open(path, "rb"), "missing " .. path)
    local text = file:read("*a")
    file:close()
    return text
end

local toc = read("RaidLeadAssist.toc")
local source = read("Core/AddonCompartment.lua")
local audit = read("docs/COMPARABLE_ADDON_AUDIT-2026-08-21.md")

assert(toc:find("## Version: 0.9.0-beta.63", 1, true), "current TOC identity missing")
assert(toc:find("## AddonCompartmentFunc: RaidLeadAssist_Open", 1, true), "compartment click metadata missing")
assert(toc:find("## AddonCompartmentFuncOnEnter: RaidLeadAssist_CompartmentEnter", 1, true), "compartment enter metadata missing")
assert(toc:find("## AddonCompartmentFuncOnLeave: RaidLeadAssist_CompartmentLeave", 1, true), "compartment leave metadata missing")
assert(toc:find("Core/AddonCompartment.lua", 1, true), "compartment module missing from runtime inventory")
assert(toc:find("## Category: Dungeons & Raids", 1, true), "native addon category missing")
for _, locale in ipairs({ "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
    assert(toc:find("## Category-" .. locale .. ":", 1, true), "localized category missing: " .. locale)
end

assert(source:find('buttonName == "RightButton"', 1, true), "right-click settings route missing")
assert(source:find("MainFrame:IsShown()", 1, true), "left-click toggle must use canonical MainFrame")
assert(source:find("SettingsFrame:Open(App.activeBossKey)", 1, true), "settings route must use canonical guarded SettingsFrame")
assert(not source:find("SendChatMessage", 1, true), "compartment must not send chat")
assert(not source:find("SendAddonMessage", 1, true), "compartment must not add networking")
assert(audit:find("Deadly Boss Mods", 1, true) and audit:find("Northern Sky Raid Tools", 1, true), "comparison evidence incomplete")

print("ok - native addon compartment/category comparison contract")
