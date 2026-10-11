--[[ Re-queue across teleports. No key: re-run the loader. ]]
local LOADER_URL = "https://raw.githubusercontent.com/OkVurb/project-ponytail/main/loader.lua";
if type(queue_on_teleport) == "function" then
    queue_on_teleport(string.format("loadstring(game:HttpGet(%q))()", LOADER_URL));
end;