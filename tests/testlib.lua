local TestLib = {}

function TestLib.NewNamespace()
    local ns = { modules = {}, messages = {} }

    function ns:RegisterModule(name, module)
        assert(type(name) == "string" and name ~= "", "invalid module name")
        assert(type(module) == "table", "module must be a table")
        assert(not self.modules[name], "duplicate module " .. name)
        self.modules[name] = module
        return module
    end

    function ns:GetModule(name)
        local module = self.modules[name]
        assert(module, "missing module " .. tostring(name))
        return module
    end

    function ns:Print(message)
        self.messages[#self.messages + 1] = tostring(message)
    end

    return ns
end

function TestLib.Load(path, ns)
    local chunk, err = loadfile(path)
    assert(chunk, err)
    return chunk("RaidLeadAssist", ns)
end

function TestLib.Frame()
    local frame = { events = {} }
    function frame:SetScript(kind, callback) self[kind] = callback end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:UnregisterAllEvents() self.events = {} end
    return frame
end

return TestLib
