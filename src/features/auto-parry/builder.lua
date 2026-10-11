local store = require("@src/features/auto-parry/data/custom_timings");
local schema = require("@src/features/auto-parry/data/timing_schema");
local timeline = require("@src/features/auto-parry/data/timeline");
local watch = require("@src/features/auto-parry/util/animation_watcher");
local builder = { visible = false, on_close = nil, on_open = nil };
local gui, frame, list, editor, status, lanes, extent_label, time_box, type_button, track_label, observations;
local draft, selected, current, dragging, stop_watch;
local applied_text, observed, playheads, session = "", {}, {}, {};
local render, apply_json;
local template = [[{
  "name": "my_timing",
  "ids": ["REPLACE_WITH_NUMERIC_ANIMATION_ID"],
  "action_type": "Spell",
  "actions": [{"when": 0.5, "type": "Parry", "hitbox": {"X": 10, "Y": 10, "Z": 10}, "offset": {"X": 0, "Y": 0, "Z": 0}}]
}]];
local function text_object(class, parent, text)
    local item = Instance.new(class);
    item.Text = text;
    item.Font = Enum.Font.Code;
    item.TextSize = 14;
    item.TextColor3 = Color3.fromRGB(235, 235, 235);
    item.BackgroundColor3 = Color3.fromRGB(38, 38, 44);
    item.BorderSizePixel = 0;
    item.Parent = parent;
    return item;
end;
local function clear_rows(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy(); end;
    end;
end;
local function write_draft()
    applied_text = services.HttpService:JSONEncode(draft);
    editor.Text = applied_text;
end;
local function ready()
    if editor.Text ~= applied_text or not draft then return apply_json(); end;
    return true;
end;
local function select_action(action)
    selected = action;
    time_box.Text = action and string.format("%.3f", action.when) or "";
    type_button.Text = action and action.type or "Type";
end;
render = function()
    if dragging then
        if editor.Text == applied_text then write_draft(); end;
        dragging = nil;
    end;
    clear_rows(lanes); table.clear(playheads);
    if not draft then extent_label.Text = "Edit JSON, then Apply JSON to draw actions."; return; end;
    local length = current and current.length or 0;
    local extent = timeline.extent(draft, length);
    extent_label.Text = string.format("0 to %.3fs | drag a marker, or enter seconds below", extent);
    for index, action in ipairs(draft.actions) do
        local row = Instance.new("Frame");
        row.Size = UDim2.new(1, -6, 0, 30); row.BackgroundTransparency = 1; row.Parent = lanes;
        row.LayoutOrder = index;
        local label = text_object("TextButton", row, index .. " " .. action.type);
        label.Size = UDim2.fromOffset(110, 28);
        label.MouseButton1Click:Connect(function() select_action(action); end);
        local lane = Instance.new("Frame");
        lane.Position = UDim2.fromOffset(157, 0); lane.Size = UDim2.new(1, -204, 0, 28);
        lane.BackgroundColor3 = Color3.fromRGB(58, 58, 66); lane.BorderSizePixel = 0; lane.Parent = row;
        local head = Instance.new("Frame");
        head.Size = UDim2.fromOffset(2, 28); head.BackgroundColor3 = Color3.fromRGB(250, 220, 120);
        head.BorderSizePixel = 0; head.Parent = lane; head.Visible = false;
        table.insert(playheads, { object = head, extent = extent });
        local marker = text_object("TextButton", lane, string.format("%.3fs", action.when));
        marker.Size = UDim2.fromOffset(90, 26); marker.AnchorPoint = Vector2.new(0.5, 0);
        marker.Position = UDim2.fromScale(action.when / extent, 0); marker.ZIndex = 2;
        marker.MouseButton1Click:Connect(function() select_action(action); end);
        marker.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return; end;
            if editor.Text ~= applied_text then status.Text = "Apply JSON before dragging; your text edits are untouched."; return; end;
            select_action(action);
            dragging = { input = input, action = action, lane = lane, marker = marker, extent = extent };
        end);
    end;
    select_action(selected);
end;
apply_json = function()
    local ok, result = pcall(function() return schema.validate(services.HttpService:JSONDecode(editor.Text)); end);
    if not ok then status.Text = tostring(result); return false; end;
    draft = result; applied_text = editor.Text; dragging = nil; selected = draft.actions[1];
    render(); status.Text = "JSON applied. Timeline edits update the JSON; Save JSON writes the file.";
    return true;
end;
local function refresh_list()
    local ok, data = pcall(store.sync, store);
    if not ok then status.Text = tostring(data); return; end;
    clear_rows(list);
    local names = {}; for name in pairs(data) do table.insert(names, name); end; table.sort(names);
    for _, name in ipairs(names) do
        local button = text_object("TextButton", list, name); button.Size = UDim2.new(1, -6, 0, 28);
        button.MouseButton1Click:Connect(function()
            editor.Text = store.raw[name]; apply_json();
            status.Text = "Editing " .. name .. ". Save replaces this custom file.";
        end);
    end;
end;
local function observe(track, entity, id)
    local row = { track = track, entity = entity, id = id };
    local button = text_object("TextButton", observations, (entity and entity.Name or "Animation") .. " | " .. id);
    button.Size = UDim2.new(1, -6, 0, 28); button.TextSize = 12; button.TextTruncate = Enum.TextTruncate.AtEnd;
    button.MouseButton1Click:Connect(function() current = row; render(); end);
    row.button = button; table.insert(observed, row);
    -- shortcut: keep only the latest 40 observations; add a searchable history only if needed.
    if #observed > 40 then table.remove(observed, 1).button:Destroy(); end;
end;
local function stop_session()
    dragging = nil;
    if stop_watch then stop_watch(); stop_watch = nil; end;
    for _, connection in ipairs(session) do connection:Disconnect(); end;
    table.clear(session); table.clear(observed); table.clear(playheads); current = nil;
    if observations then clear_rows(observations); end;
end;
local function start_session()
    table.insert(session, services.UserInputService.InputChanged:Connect(function(input)
        local drag = dragging;
        if not drag or editor.Text ~= applied_text then return; end;
        if drag.input.UserInputType == Enum.UserInputType.Touch then
            if input ~= drag.input then return; end;
        elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then return; end;
        local width = drag.lane.AbsoluteSize.X;
        if width <= 0 then return; end;
        local ratio = math.clamp((input.Position.X - drag.lane.AbsolutePosition.X) / width, 0, 1);
        timeline.move(draft, drag.action, ratio * drag.extent);
        drag.marker.Position = UDim2.fromScale(drag.action.when / drag.extent, 0);
        drag.marker.Text = string.format("%.3fs", drag.action.when);
        select_action(drag.action);
    end));
    table.insert(session, services.UserInputService.InputEnded:Connect(function(input)
        if not dragging then return; end;
        if input ~= dragging.input then return; end;
        dragging = nil;
        if editor.Text == applied_text then write_draft(); render(); end;
    end));
    table.insert(session, services.RunService.RenderStepped:Connect(function()
        if not current then track_label.Text = "Select an observed animation. Use ID replaces draft IDs."; return; end;
        local ok, position, length, speed, playing = pcall(function()
            return current.track.TimePosition, current.track.Length, current.track.Speed, current.track.IsPlaying;
        end);
        if not ok then current = nil; return; end;
        if current.length ~= length and not dragging then current.length = length; render(); end;
        track_label.Text = string.format("%s | %.3f / %.3fs | x%.2f | %s", current.id, position, length, speed, playing and "playing" or "stopped");
        for _, head in ipairs(playheads) do
            head.object.Visible = true; head.object.Position = UDim2.fromScale(math.clamp(position / head.extent, 0, 1), 0);
        end;
    end));
    stop_watch = watch(workspace:FindFirstChild("Live") or workspace, observe);
end;
local function ensure_ui()
    if gui and gui.Parent then return; end;
    gui = Instance.new("ScreenGui"); gui.Name = "PR_TimingBuilder"; gui.ResetOnSpawn = false;
    gui.Parent = (gethui and gethui()) or services.CoreGui;
    frame = Instance.new("Frame"); frame.Size = UDim2.fromScale(0.9, 0.85); frame.Position = UDim2.fromScale(0.5, 0.5);
    frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28); frame.Visible = false; frame.Parent = gui;
    local limit = Instance.new("UISizeConstraint", frame); limit.MaxSize = Vector2.new(1040, 760);
    local title = text_object("TextLabel", frame, "Project Ponytail | Timing Builder"); title.Size = UDim2.new(1, -44, 0, 30);
    local close = text_object("TextButton", frame, "X"); close.Size = UDim2.fromOffset(40, 30); close.Position = UDim2.new(1, -40, 0, 0);
    close.MouseButton1Click:Connect(function() builder:set_visible(false); if builder.on_close then builder.on_close(); end; end);
    local function scrolling(position, size)
        local area = Instance.new("ScrollingFrame"); area.Position = position; area.Size = size;
        area.BackgroundTransparency = 1; area.ScrollBarThickness = 4; area.CanvasSize = UDim2.new();
        area.AutomaticCanvasSize = Enum.AutomaticSize.Y; area.Parent = frame;
        local layout = Instance.new("UIListLayout", area); layout.Padding = UDim.new(0, 4); layout.SortOrder = Enum.SortOrder.LayoutOrder;
        return area;
    end;
    list = scrolling(UDim2.fromOffset(8, 40), UDim2.new(0.25, -12, 1, -312));
    observations = scrolling(UDim2.new(0, 8, 1, -242), UDim2.new(0.25, -12, 0, 136));
    local watcher_title = text_object("TextLabel", frame, "Observed animations");
    watcher_title.Position = UDim2.new(0, 8, 1, -270); watcher_title.Size = UDim2.new(0.25, -12, 0, 24);
    lanes = scrolling(UDim2.new(0.25, 4, 0, 40), UDim2.new(0.75, -12, 0, 130));
    extent_label = text_object("TextLabel", frame, "Edit JSON, then Apply JSON to draw actions.");
    extent_label.Position = UDim2.new(0.25, 4, 0, 172); extent_label.Size = UDim2.new(0.75, -12, 0, 26);
    local controls = Instance.new("Frame"); controls.BackgroundTransparency = 1; controls.Parent = frame;
    controls.Position = UDim2.new(0.25, 4, 0, 202); controls.Size = UDim2.new(0.75, -12, 0, 28);
    local function button(text, x, width, callback)
        local item = text_object("TextButton", controls, text); item.Position = UDim2.fromScale(x / 500, 0);
        item.Size = UDim2.new(width / 500, 0, 1, 0); item.MouseButton1Click:Connect(callback); return item;
    end;
    time_box = text_object("TextBox", controls, "");
    time_box.Size = UDim2.new(78 / 500, 0, 1, 0); time_box.ClearTextOnFocus = false; time_box.PlaceholderText = "seconds";
    time_box.FocusLost:Connect(function()
        local seconds = tonumber(time_box.Text);
        if not ready() then return; end;
        local ok, err = pcall(timeline.move, draft, selected, seconds);
        if not ok then status.Text = tostring(err); return; end;
        write_draft(); render();
    end);
    local types = { "Parry", "Block", "Roll", "End Block" };
    type_button = button("Type", 82, 92, function()
        if not ready() then return; end;
        selected.type = types[(table.find(types, selected.type) or 0) % #types + 1]; write_draft(); render();
    end);
    button("+ Action", 178, 88, function()
        if not ready() then return; end;
        local action = { when = 0, type = "Parry", hitbox = { X = 10, Y = 10, Z = 10 }, offset = { X = 0, Y = 0, Z = 0 } };
        table.insert(draft.actions, action); selected = timeline.move(draft, action, current and current.track.TimePosition or 0.5);
        write_draft(); render();
    end);
    button("Delete", 270, 70, function()
        if not ready() then return; end;
        if #draft.actions == 1 then status.Text = "Keep at least one action."; return; end;
        table.remove(draft.actions, table.find(draft.actions, selected)); selected = draft.actions[1]; write_draft(); render();
    end);
    button("Previous", 344, 84, function()
        if ready() then select_action(draft.actions[math.max(1, (table.find(draft.actions, selected) or 1) - 1)]); end;
    end);
    button("Next", 432, 60, function()
        if ready() then select_action(draft.actions[math.min(#draft.actions, (table.find(draft.actions, selected) or 1) + 1)]); end;
    end);
    track_label = text_object("TextLabel", frame, "Select an observed animation. Use ID replaces draft IDs.");
    track_label.TextSize = 12; track_label.Position = UDim2.new(0.25, 4, 0, 234); track_label.Size = UDim2.new(0.75, -12, 0, 26);
    editor = text_object("TextBox", frame, template); editor.Position = UDim2.new(0.25, 4, 0, 266);
    editor.Size = UDim2.new(0.75, -12, 1, -338); editor.MultiLine = true; editor.ClearTextOnFocus = false;
    editor.TextXAlignment = Enum.TextXAlignment.Left; editor.TextYAlignment = Enum.TextYAlignment.Top; editor.TextWrapped = true;
    editor:GetPropertyChangedSignal("Text"):Connect(function()
        if editor.Text ~= applied_text then dragging = nil; end;
    end);
    local new = text_object("TextButton", frame, "New"); new.Size = UDim2.fromOffset(88, 28); new.Position = UDim2.new(0, 8, 1, -64);
    new.MouseButton1Click:Connect(function()
        dragging = nil; editor.Text = template; draft = nil; selected = nil; render();
        status.Text = "Replace the example ID, or select an animation and Use ID. Calibrate hitbox/offset in JSON.";
    end);
    local use_id = text_object("TextButton", frame, "Use ID"); use_id.Size = UDim2.fromOffset(88, 28); use_id.Position = UDim2.new(0, 8, 1, -102);
    use_id.MouseButton1Click:Connect(function()
        if not current then status.Text = "Select an observed animation first."; return; end;
        local ok, result = pcall(function()
            local data = services.HttpService:JSONDecode(editor.Text); data.ids = { current.id }; return schema.validate(data);
        end);
        if not ok then status.Text = tostring(result); return; end;
        draft = result; selected = draft.actions[1]; write_draft(); render(); status.Text = "Draft IDs replaced. Review and calibrate before saving.";
    end);
    local save = text_object("TextButton", frame, "Save JSON"); save.Size = UDim2.fromOffset(120, 28); save.Position = UDim2.new(0.25, 4, 1, -64);
    save.MouseButton1Click:Connect(function()
        if dragging then
            dragging = nil;
            if editor.Text == applied_text then write_draft(); end;
        end;
        local ok, result = pcall(store.save, store, editor.Text);
        status.Text = ok and ("Saved " .. result .. ".json. Custom lookup refreshed.") or tostring(result);
        if ok then refresh_list(); end;
    end);
    local apply = text_object("TextButton", frame, "Apply JSON"); apply.Size = UDim2.fromOffset(120, 28); apply.Position = UDim2.new(0.25, 132, 1, -64);
    apply.MouseButton1Click:Connect(apply_json);
    status = text_object("TextLabel", frame, "Seconds, numeric-string IDs, ordered actions. Custom files only.");
    status.BackgroundTransparency = 1; status.TextWrapped = true; status.Size = UDim2.new(1, -16, 0, 30); status.Position = UDim2.new(0, 8, 1, -32);
    if aztup and aztup.maid then
        aztup.maid:give_task(function()
            stop_session(); gui:Destroy(); gui = nil; builder.visible = false;
            if getgenv().timing_builder == builder then getgenv().timing_builder = nil; end;
        end);
    end;
end;
function builder:set_visible(value)
    if not value and not gui then return; end;
    ensure_ui();
    if self.visible == (value == true) then return; end;
    if dragging and editor.Text == applied_text then write_draft(); end;
    stop_session(); self.visible = value == true; frame.Visible = self.visible;
    if self.visible then
        refresh_list(); render(); start_session();
        if self.on_open then self.on_open(); end;
    end;
end;
function builder:load_track(track, entity)
    if not track or not track.Animation then return; end;
    local id = track.Animation.AnimationId:match("%d+"); if not id then return; end;
    self:set_visible(true); current = { track = track, entity = entity, id = id }; render();
end;
getgenv().timing_builder = builder;
return builder;
