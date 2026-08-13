local _, ns = ...

local EventBus = { listeners = {} }

function EventBus:On(eventName, owner, callback)
    assert(type(eventName) == "string", "RaidLeadAssist: event name must be a string")
    assert(type(callback) == "function", "RaidLeadAssist: callback must be a function")

    local listeners = self.listeners[eventName]
    if not listeners then
        listeners = {}
        self.listeners[eventName] = listeners
    end
    listeners[#listeners + 1] = { owner = owner, callback = callback }
end

function EventBus:Emit(eventName, ...)
    local listeners = self.listeners[eventName]
    if not listeners then return end

    for index = 1, #listeners do
        local listener = listeners[index]
        local ok, err = pcall(listener.callback, listener.owner, ...)
        if not ok then
            ns:Print(("Event '%s' failed: %s"):format(eventName, tostring(err)))
        end
    end
end

ns:RegisterModule("Core.EventBus", EventBus)
