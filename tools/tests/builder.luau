-- Actual builder code with explicit GUI/signal mocks, not a rendered Roblox UI.
local function clone(value)
    if type(value) ~= "table" then return value; end;
    local result = {}; for key, item in pairs(value) do result[key] = clone(item); end; return result;
end;
local function signal()
    local self = { connections = {} };
    function self:Connect(callback)
        local connection = { callback = callback, Connected = true };
        function connection:Disconnect() self.Connected = false; end;
        table.insert(self.connections, connection); return connection;
    end;
    function self:fire(...)
        for _, connection in ipairs(table.clone(self.connections)) do
            if connection.Connected then connection.callback(...); end;
        end;
    end;
    function self:count()
        local count = 0; for _, connection in ipairs(self.connections) do if connection.Connected then count += 1; end; end;
        return count;
    end;
    return self;
end;
local instances = {};
local function instance(class, parent)
    local values = { ClassName = class, Name = class, AbsoluteSize = { X = 360 }, AbsolutePosition = { X = 0 } };
    local children, properties, events = {}, {}, {};
    for _, key in ipairs({ "MouseButton1Click", "InputBegan", "FocusLost", "DescendantAdded", "DescendantRemoving" }) do events[key] = signal(); end;
    local self;
    local methods = {};
    function methods:IsA(name)
        return name == class or name == "GuiObject" and table.find({ "Frame", "ScrollingFrame", "TextButton", "TextBox", "TextLabel" }, class) ~= nil;
    end;
    function methods:GetChildren() return table.clone(children); end;
    function methods:GetDescendants()
        local result = {}; for _, child in ipairs(children) do
            table.insert(result, child); for _, item in ipairs(child:GetDescendants()) do table.insert(result, item); end;
        end; return result;
    end;
    function methods:FindFirstChild(name)
        for _, child in ipairs(children) do if child.Name == name then return child; end; end;
    end;
    function methods:GetPropertyChangedSignal(key)
        if not properties[key] then properties[key] = signal(); end; return properties[key];
    end;
    function methods:Destroy()
        for _, child in ipairs(table.clone(children)) do child:Destroy(); end;
        for _, event in pairs(events) do for _, connection in ipairs(event.connections) do connection:Disconnect(); end; end;
        for _, event in pairs(properties) do for _, connection in ipairs(event.connections) do connection:Disconnect(); end; end;
        self.Parent = nil; values.destroyed = true;
    end;
    self = setmetatable({}, {
        __index = function(_, key)
            if values[key] ~= nil then return values[key]; end;
            return methods[key] or events[key];
        end,
        __newindex = function(_, key, value)
            if key == "Parent" then
                local previous = values.Parent;
                if previous then local index = table.find(previous._children, self); if index then table.remove(previous._children, index); end; end;
                if value then table.insert(value._children, self); end;
            end;
            values[key] = value;
            if properties[key] then properties[key]:fire(); end;
        end,
    });
    values._children = children; table.insert(instances, self); self.Parent = parent; return self;
end;
local function find(text)
    for _, item in ipairs(instances) do if not item.destroyed and item.Text == text then return item; end; end;
    error("Missing UI item: " .. text);
end;
local function click(text) find(text).MouseButton1Click:fire(); end;
local fixture = { name = "fixture", ids = { "123" }, action_type = "Spell", actions = {
    { when = 0.5, type = "Block", hitbox = { X = 10, Y = 10, Z = 10 }, offset = { X = 0, Y = 0, Z = 0 } },
    { when = 1, type = "End Block" },
} };
local encoded, encoding_index = { fixture = fixture }, 0;
local http = {};
function http:JSONDecode(source)
    if encoded[source] then return clone(encoded[source]); end;
    if source:find("REPLACE_WITH_NUMERIC_ANIMATION_ID", 1, true) then
        local value = clone(fixture); value.name = "my_timing"; value.ids = { "REPLACE_WITH_NUMERIC_ANIMATION_ID" }; value.actions = { value.actions[1] }; return value;
    end;
    if source == "encoded" then return { ["Smash:Ice"] = "Ice Smash", ["5707296382"] = "Training Vest", ["%202877143560%20"] = "ToolModels" }; end;
    if source == "badmap" then return { bad = 42 }; end;
    error("Bad JSON fixture");
end;
function http:JSONEncode(value)
    encoding_index += 1; local key = "encoded-" .. encoding_index; encoded[key] = clone(value); return key;
end;
local input = { InputChanged = signal(), InputEnded = signal() };
local run = { RenderStepped = signal() };
local cleanup_tasks = {};
global.aztup = { maid = { give_task = function(_, task) table.insert(cleanup_tasks, task); end } };
global.services = { HttpService = http, CoreGui = instance("Frame"), UserInputService = input, RunService = run,
    EncodingService = { Base64Decode = function(_, value) return value; end, DecompressBuffer = function(_, value) return value; end },
};
global.buffer = { fromstring = function(value) return value; end, tostring = function(value) return value; end };
global.Enum = { Font = { Code = "Code" }, UserInputType = { MouseButton1 = "mouse", Touch = "touch", MouseMovement = "move" },
    TextTruncate = { AtEnd = "AtEnd" }, AutomaticSize = { Y = "Y" }, SortOrder = { LayoutOrder = "LayoutOrder" },
    TextXAlignment = { Left = "Left" }, TextYAlignment = { Top = "Top" }, CompressionAlgorithm = { Zstd = "Zstd" },
};
global.Color3 = { fromRGB = function(...) return {...}; end };
global.Vector2 = { new = function(...) return {...}; end };
global.UDim = { new = function(...) return {...}; end };
global.UDim2 = { new = function(...) return {...}; end, fromOffset = function(...) return {...}; end, fromScale = function(...) return {...}; end };
global.Instance = { new = instance };
local entity = { Name = "Fixture Mob" };
local track = { Animation = { AnimationId = "rbxassetid://634" }, TimePosition = 0.2, Length = 0, Speed = 1, IsPlaying = true };
local animator = { AnimationPlayed = signal(), IsA = function(_, key) return key == "Animator"; end,
    FindFirstAncestorOfClass = function() return entity; end, GetPlayingAnimationTracks = function() return { track }; end,
};
local world = instance("Frame");
world.GetDescendants = function() return { animator }; end;
global.workspace = world;
local timeline = runtime.require("@src/features/auto-parry/data/timeline");
local data = clone(fixture); local moved = data.actions[2];
assert(timeline.move(data, moved, 0.12349).when == 0.123 and data.actions[1] == moved);
timeline.move(data, moved, -5); assert(moved.when == 0);
assert(not pcall(timeline.move, data, moved, math.huge));
assert(not pcall(timeline.move, data, moved, 0/0));
assert(not pcall(timeline.move, data, {}, 1));
timeline.move(data, moved, 1e308); assert(moved.when == 1e308 and schema.validate(data));
data = clone(fixture); moved = data.actions[1]; timeline.move(data, moved, 1);
assert(data.actions[1] == moved and data.actions[2].type == "End Block", "Equal-time ordering must be stable");
assert(timeline.extent(data, 0) == 1.25 and timeline.extent(data, 2) == 2);
local map = runtime.require("@src/utility/string_map"); assert(not pcall(map, "badmap"));
assert(runtime.require("@src/features/removals/mantra_revealer/mantras")["Smash:Ice"] == "Ice Smash");
assert(runtime.require("@src/utility/deepwoken/deepwoken_meshes")["5707296382"] == "Training Vest");
assert(runtime.require("@src/utility/deepwoken/deepwoken_meshes")["2877143560"] == "ToolModels");
local watch = runtime.require("@src/features/auto-parry/util/animation_watcher");
local seen = 0; local stop = watch(world, function(_, owner, id) assert(owner == entity and id == "634"); seen += 1; end);
assert(seen == 1 and animator.AnimationPlayed:count() == 1);
world.DescendantAdded:fire(animator); assert(animator.AnimationPlayed:count() == 1);
animator.AnimationPlayed:fire(track); assert(seen == 2);
world.DescendantRemoving:fire(animator); assert(animator.AnimationPlayed:count() == 0);
world.DescendantAdded:fire(animator); assert(seen == 3);
local late = animator.AnimationPlayed.connections[#animator.AnimationPlayed.connections].callback;
stop(); stop(); late(track); assert(seen == 3 and world.DescendantAdded:count() == 0 and world.DescendantRemoving:count() == 0);
local snapshot = animator.GetPlayingAnimationTracks;
animator.GetPlayingAnimationTracks = function() error("Snapshot unavailable"); end;
stop = watch(world, function() seen += 1; end);
animator.AnimationPlayed:fire(track); assert(seen == 4, "Snapshot failure must not block future observations");
stop(); assert(animator.AnimationPlayed:count() == 0);
animator.GetPlayingAnimationTracks = snapshot;
local builder = runtime.require("@src/features/auto-parry/builder");
assert(global.timing_builder == builder and not builder.visible);
local opened = 0; builder.on_open = function() opened += 1; builder:set_visible(true); end;
builder:set_visible(true); builder:set_visible(true);
assert(opened == 1 and input.InputChanged:count() == 1 and animator.AnimationPlayed:count() == 1);
local editor;
for _, item in ipairs(instances) do if item.ClassName == "TextBox" and item.MultiLine then editor = item; end; end;
assert(editor); editor.Text = "fixture"; click("Apply JSON");
local marker = find("0.500s"); local press = { UserInputType = "mouse" };
marker.InputBegan:fire(press); input.InputChanged:fire({ UserInputType = "move", Position = { X = 360 } }); input.InputEnded:fire(press);
local result = http:JSONDecode(editor.Text);
assert(result.actions[1].type == "End Block" and result.actions[2].when == 1.25);
assert(result.actions[2].hitbox.X == 10, "Dragging must preserve hitbox and offset");
local touch = { UserInputType = "touch", Position = { X = 0 } };
find("1.250s").InputBegan:fire(touch);
input.InputChanged:fire({ UserInputType = "move", Position = { X = 0 } });
input.InputEnded:fire(press); assert(http:JSONDecode(editor.Text).actions[2].when == 1.25);
input.InputChanged:fire(touch); input.InputEnded:fire(touch);
assert(http:JSONDecode(editor.Text).actions[1].when == 0, "Only the initiating touch can move or end its drag");
editor.Text = "fixture"; click("Apply JSON");
find("0.500s").InputBegan:fire(press);
input.InputChanged:fire({ UserInputType = "move", Position = { X = 360 } }); input.InputEnded:fire(press);
editor.Text = "invalid"; marker = find("1.250s"); marker.InputBegan:fire(press);
input.InputChanged:fire({ UserInputType = "move", Position = { X = 0 } }); input.InputEnded:fire(press);
click("+ Action"); assert(editor.Text == "invalid", "Invalid draft edits must not be overwritten");
editor.Text = "fixture"; click("Apply JSON");
find("0.500s").InputBegan:fire(press);
-- Simulate deferred property signals: Save must consult the actual text, not a stale drag flag.
local text_signal = editor:GetPropertyChangedSignal("Text");
local text_callback = text_signal.connections[1].callback;
text_signal.connections[1].callback = function() end;
editor.Text = "invalid"; click("Save JSON"); assert(editor.Text == "invalid");
text_signal.connections[1].callback = text_callback;
editor.Text = "fixture"; click("Apply JSON");
local seconds;
for _, item in ipairs(instances) do if item.PlaceholderText == "seconds" then seconds = item; end; end;
seconds.Text = "0.75"; seconds.FocusLost:fire(); assert(http:JSONDecode(editor.Text).actions[1].when == 0.75);
seconds.Text = "bad"; local previous = editor.Text; seconds.FocusLost:fire(); assert(editor.Text == previous);
click("+ Action"); assert(#http:JSONDecode(editor.Text).actions == 3);
click("Delete"); assert(#http:JSONDecode(editor.Text).actions == 2);
click("Previous"); click("Next");
click("Save JSON"); assert(store:lookup("123"));
builder:load_track(track, entity); click("Use ID"); assert(http:JSONDecode(editor.Text).ids[1] == "634");
track.Length = 2; run.RenderStepped:fire(); assert(find("0 to 2.000s | drag a marker, or enter seconds below"));
assert(track.TimePosition == 0.2 and track.Speed == 1 and track.IsPlaying, "Watcher must not alter playback");
for _ = 1, 45 do animator.AnimationPlayed:fire(track); end;
local observation_count = 0;
for _, item in ipairs(instances) do if not item.destroyed and item.Text == "Fixture Mob | 634" then observation_count += 1; end; end;
assert(observation_count == 40, "Watcher history must be bounded");
local unsaved = editor.Text; builder:set_visible(false);
assert(input.InputChanged:count() == 0 and input.InputEnded:count() == 0 and run.RenderStepped:count() == 0);
assert(animator.AnimationPlayed:count() == 0 and world.DescendantAdded:count() == 0);
builder:set_visible(true); assert(editor.Text == unsaved and animator.AnimationPlayed:count() == 1);
for _, cleanup in ipairs(cleanup_tasks) do cleanup(); end;
assert(not builder.visible and global.timing_builder == nil and animator.AnimationPlayed:count() == 0);
assert(input.InputChanged:count() == 0 and run.RenderStepped:count() == 0);
print("Builder and watcher mock checks passed");
