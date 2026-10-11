-- Copy the latest bundle into your executor's workspace before running this launcher.
repeat task.wait() until game:IsLoaded();
assert(type(readfile) == "function", "This launcher needs executor filesystem access.");
local source = readfile("project_ponytail_bundle.lua");
local run, reason = loadstring(source, "@ProjectPonytail");
assert(run, reason);
return run();
