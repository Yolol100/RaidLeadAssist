local _, ns = ...

local Theme = {
    width = 480,
    padding = 12,
    gap = 5,
    dropdownHeight = 34,
    difficultyTabHeight = 27,
    difficultyTabGap = 6,
    timelineHeight = 34,
    sectionTitleHeight = 18,
    explanationButtonHeight = 36,
    callButtonHeight = 38,

    settings = {
        width = 560,
        height = 550,
        padding = 16,
        footerHeight = 76,
        explanationFieldHeight = 116,
        callFieldHeight = 56,
        fieldGap = 7,
    },

    font = "Fonts\\FRIZQT__.TTF",
    texture = "Interface\\Buttons\\WHITE8X8",

    colors = {
        background = { 0.025, 0.035, 0.030, 0.94 },
        backgroundSolid = { 0.015, 0.024, 0.020, 0.985 },
        surface = { 0.055, 0.072, 0.062, 1.00 },
        surfaceRaised = { 0.080, 0.110, 0.090, 1.00 },
        border = { 0.150, 0.220, 0.175, 1.00 },
        borderStrong = { 0.210, 0.320, 0.245, 1.00 },
        text = { 0.950, 0.960, 0.930, 1.00 },
        muted = { 0.590, 0.650, 0.610, 1.00 },
        venom = { 0.650, 0.840, 0.180, 1.00 },
        venomBright = { 0.800, 0.960, 0.330, 1.00 },
        venomDark = { 0.240, 0.350, 0.115, 1.00 },
        teal = { 0.260, 0.670, 0.610, 1.00 },
        called = { 0.095, 0.115, 0.100, 1.00 },
        error = { 0.900, 0.360, 0.300, 1.00 },
        success = { 0.650, 0.840, 0.180, 1.00 },
    },
}

ns:RegisterModule("UI.Theme", Theme)
