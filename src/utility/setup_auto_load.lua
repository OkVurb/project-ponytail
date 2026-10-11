-- Queue only a loader chosen by the source entry point or explicitly by the user.
local env = getgenv();
local url = env.PROJECT_RAIN_LOADER_URL;
local queue = queue_on_teleport or (syn and syn.queue_on_teleport);
if type(queue) ~= "function" then
    warn("[Project Ponytail] Teleport queue is unavailable.");
    return false;
end;
if type(url) ~= "string" or not url:match("^https://") then
    warn("[Project Ponytail] Bundle autoload needs an explicit HTTPS PROJECT_RAIN_LOADER_URL.");
    return false;
end;
local source = env.PROJECT_RAIN_SOURCE_URL;
local prefix = type(source) == "string" and string.format("getgenv().PROJECT_RAIN_SOURCE_URL = %q; ", source) or "";
queue(prefix .. string.format("getgenv().PROJECT_RAIN_LOADER_URL = %q; local f,e = loadstring(game:HttpGet(%q)); assert(f,e); f();", url, url));
return true;
