local _, ns = ...

local Theme = {
    width = 480,
    padding = 12,
    gap = 7,
    dropdownHeight = 34,
    timelineHeight = 34,
    sectionTitleHeight = 18,
    explanationButtonHeight = 40,
    callButtonHeight = 42,

    settings = {
        width = 600,
        height = 620,
        padding = 18,
        footerHeight = 70,
        explanationFieldHeight = 128,
        callFieldHeight = 60,
        fieldGap = 8,
    },

    font = "Fonts\\FRIZQT__.TTF",
    texture = "Interface\\Buttons\\WHITE8X8",

    colors = {
        background = { 0.035, 0.075, 0.055, 0.92 },
        backgroundSolid = { 0.020, 0.050, 0.040, 0.98 },
        surface = { 0.070, 0.120, 0.090, 1.00 },
        surfaceRaised = { 0.100, 0.190, 0.130, 1.00 },
        border = { 0.160, 0.280, 0.200, 1.00 },
        borderStrong = { 0.220, 0.360, 0.270, 1.00 },
        text = { 0.950, 0.960, 0.930, 1.00 },
        muted = { 0.550, 0.630, 0.580, 1.00 },
        venom = { 0.730, 0.910, 0.200, 1.00 },
        venomBright = { 0.840, 0.980, 0.380, 1.00 },
        venomDark = { 0.530, 0.710, 0.140, 1.00 },
        teal = { 0.330, 0.780, 0.710, 1.00 },
        called = { 0.140, 0.190, 0.160, 1.00 },
        error = { 0.900, 0.360, 0.300, 1.00 },
        success = { 0.730, 0.910, 0.200, 1.00 },
    },
}

ns:RegisterModule("UI.Theme", Theme)
