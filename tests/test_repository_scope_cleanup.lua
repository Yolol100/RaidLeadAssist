local forbidden = {
    "scripts/native_ats_prospecting.py",
    "tests/test_native_ats_prospecting.py",
}

for _, path in ipairs(forbidden) do
    local file = io.open(path, "rb")
    if file then
        file:close()
        error("unrelated ATS/prospecting artifact must not be tracked in RaidLeadAssist: " .. path)
    end
end

print("ok - repository scope excludes unrelated ATS prospecting artifacts")
