-- Appended to the real source modules and runtime by build.test.js.
local global = {};
local native_calls, asset_calls, executions = 0, 0, 0;
local native_value = {};
local host = setmetatable({
    require = function(value) native_calls += 1; return value; end,
    getgenv = function() return global; end,
    game = { PlaceId = 5735553160, GetService = function(_, key) return { key = key }; end },
    identifyexecutor = function() return "mock"; end,
    tick = function() return 10; end,
    warn = function() end,
}, { __index = getfenv(0) });
factories["@src/one"] = function() executions += 1; return "one", nil, { name = "Main" }; end;
factories["@src/nil"] = function() executions += 1; return nil; end;
factories["@src/empty"] = function() executions += 1; end;
factories["@src/nested/init"] = function() return "alias"; end;
factories["@src/cycle"] = function() return require("@src/cycle"); end;
local fails = true;
factories["@src/retry"] = function() if fails then error("temporary"); end; return 42; end;
factories["@src/writer"] = function() shared_value = 42; return shared_value; end;
factories["@src/features/test/registered"] = function() return { id = "registered" }; end;
factories["@src/features/test/helper"] = function() return function() end; end;
factories["@src/features/test/broken"] = function() error("Expected fixture failure"); end;
factories["@src/features/manifest"] = function()
    return { "@src/features/test/broken", "@src/features/test/helper", "@src/features/test/registered" };
end;
local ids = {};
for id in pairs(factories) do table.insert(ids, id); end;
local runtime = create_runtime({ host = host, global = global, modules = ids,
    resolve = function(id) return factories[id]; end,
    asset = function() asset_calls += 1; return "encoded"; end,
});
local values = table.pack(runtime.require("@src/one"));
assert(values.n == 3 and values[1] == "one" and values[2] == nil and values[3].name == "Main");
runtime.require("@src/one.lua"); assert(executions == 1);
assert(table.pack(runtime.require("@src/nil")).n == 1); runtime.require("@src/nil"); assert(executions == 2);
assert(runtime.require("@src/empty") == true); runtime.require("@src/empty"); assert(executions == 3);
assert(runtime.require("@src/nested") == "alias");
assert(runtime.require(native_value) == native_value and native_calls == 1);
assert(not pcall(runtime.require, "@src/cycle"));
assert(not pcall(runtime.require, "@src/retry")); fails = false; assert(runtime.require("@src/retry") == 42);
assert(not pcall(runtime.require, "@src/missing"));
assert(runtime.require("@src/writer") == 42 and global.shared_value == 42);
assert(host.require ~= runtime.require, "Native require must not be overwritten");
assert(#runtime.list_modules("features/auto-parry/data/*") == 3);
assert(#runtime.list_modules("nested/*") == 1);
assert(#runtime.list_modules("*") == 8);
assert(runtime.env.inline_asset_b96("@assets/x") == "encoded");
runtime.env.inline_asset_b96("@assets/x"); assert(asset_calls == 1);
assert(runtime.require("@src/luarmor_init_script") == true);
assert(global.LRM_ScriptName == "Project Ponytail", "Default script name must match the new branding");
assert(global.is_depths and not global.is_chime and global.is_regular and global.place_name == "The Depths");
assert(global.Feature and type(global.list_modules) == "function");
assert(type(global.load_timings) == "function" and #global.timing_names() == 0);
global.aztup = { features = {} };
local loader = runtime.require("@src/features/loader");
assert(loader.initialize().registered.id == "registered", "One failed module must not abort registration");
assert(loader.last_report.registered == 1 and loader.last_report.skipped == 1 and loader.last_report.failed == 1);
loader.initialize(); assert(loader.last_report.registered == 0, "Registration must be idempotent");
local connections, disconnected, updates = 0, 0, 0;
local callback;
local signal = { Connect = function(_, fn)
    connections += 1; callback = fn;
    return { Disconnect = function() disconnected += 1; end };
end };
local feature = global.Feature:new("example", signal, function() updates += 1; end);
feature:enable(); feature:enable(); assert(connections == 1);
callback(); assert(updates == 1);
feature:disable(); feature:disable(); assert(disconnected == 1);
local externally_bound = global.Feature:new("ui-bound", signal);
externally_bound.current_connection = signal:Connect(function() end);
externally_bound:enable(); assert(connections == 2); externally_bound:disable();
local schema = runtime.require("@src/features/auto-parry/data/timing_schema");
local valid = { name = "test", ids = { "123" }, action_type = "Spell", actions = { { when = 0.5, type = "Parry", hitbox = { X = 1, Y = 2, Z = 3 } } } };
assert(schema.validate(valid) == valid);
for _, bad in ipairs({ "../escape", "a/b", "", "two words" }) do
    local data = table.clone(valid); data.name = bad; assert(not pcall(schema.validate, data));
end;
local invalid = table.clone(valid); invalid.actions = { { when = -1, type = "Parry" } };
assert(not pcall(schema.validate, invalid));
invalid.actions = { { when = math.huge, type = "Parry" } }; assert(not pcall(schema.validate, invalid));
invalid.actions = { { when = 0.5, type = "Bad" } }; assert(not pcall(schema.validate, invalid));
invalid.actions = { { when = 0.5, type = "Parry", hitbox = { X = -1, Y = 0, Z = 0 } } }; assert(not pcall(schema.validate, invalid));
invalid.actions = { { when = 1, type = "Parry" }, { when = 0.5, type = "Parry" } }; assert(not pcall(schema.validate, invalid));
invalid = table.clone(valid); invalid.run = "not executable"; assert(not pcall(schema.validate, invalid));
invalid = table.clone(valid); invalid.actions = { { when = 0, type = "Parry", enc = true } }; assert(not pcall(schema.validate, invalid));
invalid = table.clone(valid); invalid.ids = { "123", extra = "not-an-array" }; assert(not pcall(schema.validate, invalid));
invalid = table.clone(valid); invalid.actions = { [1] = valid.actions[1], [3] = valid.actions[1] }; assert(not pcall(schema.validate, invalid));
invalid = table.clone(valid); invalid.actions = { { when = 0, type = "Parry", offset = { X = 0, Y = 0, Z = 0, unexpected = true } } }; assert(not pcall(schema.validate, invalid));
local disk = {}; local folder = false;
global.isfolder = function() return folder; end;
global.makefolder = function() folder = true; end;
global.isfile = function(file) return disk[file] ~= nil; end;
global.readfile = function(file) return disk[file]; end;
global.writefile = function(file, text) disk[file] = text; end;
global.listfiles = function()
    local files = {}; for file in pairs(disk) do table.insert(files, file); end; return files;
end;
global.Vector3 = { new = function(x, y, z) return { X = x, Y = y, Z = z }; end };
global.CFrame = global.Vector3;
global.services = { HttpService = {
    JSONDecode = function(_, text) assert(text == "valid", "bad JSON"); return valid; end,
    JSONEncode = function() return "valid"; end,
} };
local store = runtime.require("@src/features/auto-parry/data/custom_timings");
assert(store:save("valid") == "test");
local entry, name = store:lookup("rbxassetid://123"); assert(entry and name == "test");
assert(entry.actions[1].hitbox.Z == 3);
disk[store.directory .. "/test.json"] = "broken";
store:sync(); assert(store:lookup("123"), "Malformed edits must preserve last known good timing");
disk[store.directory .. "/test.json"] = nil;
store:sync(); assert(not store:lookup("123"), "Deleted timings must leave the lookup");
local refresh_callback;
local delayed = {};
local reset_calls = 0;
local old_root = { CFrame = "saved-position" };
local old_character = { FindFirstChild = function() return old_root; end };
local player = { Character = old_character, Kill = {} };
player.CharacterAdded = { Connect = function(_, fn)
    refresh_callback = fn;
    return { Disconnect = function() end };
end };
global.services.Players = { LocalPlayer = player };
global.task = { spawn = function(fn) fn(); end, delay = function(_, fn) table.insert(delayed, fn); end };
global.replicatesignal = function() reset_calls += 1; end;
local refresh = runtime.require("@src/features/buttons/refresh");
assert(refresh() and reset_calls == 1);
assert(not refresh(), "Only one refresh may wait for a respawn");
local new_root = { CFrame = "new-position" };
local new_character = { WaitForChild = function() return new_root; end, FindFirstChild = function() return new_root; end };
player.Character = new_character; refresh_callback(new_character);
assert(new_root.CFrame == "saved-position");
assert(refresh()); delayed[1]();
assert(not refresh(), "An old timeout must not clear the next pending refresh");
delayed[2](); assert(refresh()); delayed[3]();
global.EffectReplicator = { FindEffect = function() return true; end };
assert(not refresh(), "Combat blocks refresh"); global.EffectReplicator = nil;
global.replicatesignal = nil; assert(not refresh(), "Missing reset capability must not kill the player");
for _, name in ipairs({ "Project Rain", "testing", "Project Ponytail" }) do
    global.LRM_ScriptName = name;
    factories["@src/globals"]();
    assert(global.is_regular == (name ~= "testing"), "Renaming must preserve regular-build gates and legacy names");
end;
print("Runtime mock checks passed");
