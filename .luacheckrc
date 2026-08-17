std = "lua51"
global = false
unused_args = false
unused_secondaries = false
max_line_length = false

files["Services/Providers/BigWigsProvider.lua"] = {
  ignore = { "211/validEventID" },
}

files["Core/App.lua"] = {
  ignore = { "431/settingsEnabled", "431/settingsReason" },
}
