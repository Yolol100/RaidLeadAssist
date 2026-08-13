local addonName, ns = ...

ns.name = addonName
ns.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
ns.modules = {}

function ns:RegisterModule(name, module)
    assert(type(name) == "string" and name ~= "", "RaidLeadAssist: invalid module name")
    assert(type(module) == "table", "RaidLeadAssist: module must be a table")
    assert(not self.modules[name], "RaidLeadAssist: duplicate module " .. name)
    self.modules[name] = module
    return module
end

function ns:GetModule(name)
    local module = self.modules[name]
    assert(module, "RaidLeadAssist: missing module " .. tostring(name))
    return module
end

function ns:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(("|cffb9e832RLA|r: %s"):format(tostring(message)))
end
