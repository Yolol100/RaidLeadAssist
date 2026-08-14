local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

ns:RegisterModule("UI.Theme", { colors = {} })
ns:RegisterModule("UI.ActionButton", {})
T.Load("UI/ConfirmDialog.lua", ns)

local Dialog = ns:GetModule("UI.ConfirmDialog")
local hidden = 0
local canceled = 0
Dialog.overlay = {
    Hide = function() hidden = hidden + 1 end,
    IsShown = function() return hidden == 0 end,
}
Dialog.onSave = function() error("save callback must not run on cancel") end
Dialog.onDiscard = function() error("discard callback must not run on cancel") end
Dialog.onCancel = function() canceled = canceled + 1 end

Dialog:Hide()
assert(hidden == 1 and canceled == 1, "dismissing a confirmation must execute its cancel path exactly once")
assert(Dialog.onSave == nil and Dialog.onDiscard == nil and Dialog.onCancel == nil,
    "confirmation callbacks must be cleared after dismissal")

Dialog:Hide()
assert(hidden == 2 and canceled == 1, "a second hide must be idempotent with respect to callbacks")

print("ok - confirmation dismissal preserves cancel semantics")
