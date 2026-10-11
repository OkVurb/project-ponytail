-- OSS custom timing editor, not the unreleased graphical timeline.
local store = require("@src/features/auto-parry/data/custom_timings");
local builder = { visible = false, on_close = nil };
local gui, frame, list, editor, status;
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
local function refresh_list()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy(); end;
    end;
    local names = {};
    for name in pairs(store:sync()) do table.insert(names, name); end;
    table.sort(names);
    for _, name in ipairs(names) do
        local button = text_object("TextButton", list, name);
        button.Size = UDim2.new(1, -6, 0, 28);
        button.MouseButton1Click:Connect(function()
            editor.Text = store.raw[name];
            status.Text = "Editing " .. name .. ". Save replaces this custom file.";
        end);
    end;
end;
local function ensure_ui()
    if gui and gui.Parent then return; end;
    gui = Instance.new("ScreenGui");
    gui.Name = "PR_TimingBuilder";
    gui.ResetOnSpawn = false;
    gui.Parent = (gethui and gethui()) or services.CoreGui;
    frame = Instance.new("Frame");
    frame.Size = UDim2.fromScale(0.85, 0.7);
    frame.Position = UDim2.fromScale(0.5, 0.5);
    frame.AnchorPoint = Vector2.new(0.5, 0.5);
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28);
    frame.Visible = false;
    frame.Parent = gui;
    local limit = Instance.new("UISizeConstraint", frame);
    limit.MaxSize = Vector2.new(760, 520);
    local title = text_object("TextLabel", frame, "Project Ponytail | Custom Timing JSON Editor");
    title.Size = UDim2.new(1, -44, 0, 30);
    local close = text_object("TextButton", frame, "X");
    close.Size = UDim2.fromOffset(40, 30);
    close.Position = UDim2.new(1, -40, 0, 0);
    close.MouseButton1Click:Connect(function()
        builder:set_visible(false);
        if builder.on_close then builder.on_close(); end;
    end);
    list = Instance.new("ScrollingFrame");
    list.Size = UDim2.new(0.25, -12, 1, -112);
    list.Position = UDim2.fromOffset(8, 40);
    list.BackgroundTransparency = 1;
    list.ScrollBarThickness = 4;
    list.CanvasSize = UDim2.new();
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y;
    list.Parent = frame;
    local layout = Instance.new("UIListLayout", list);
    layout.Padding = UDim.new(0, 4);
    editor = text_object("TextBox", frame, template);
    editor.Position = UDim2.new(0.25, 4, 0, 40);
    editor.Size = UDim2.new(0.75, -12, 1, -112);
    editor.MultiLine = true;
    editor.ClearTextOnFocus = false;
    editor.TextXAlignment = Enum.TextXAlignment.Left;
    editor.TextYAlignment = Enum.TextYAlignment.Top;
    editor.TextWrapped = true;
    local new = text_object("TextButton", frame, "New");
    new.Size = UDim2.fromOffset(88, 28);
    new.Position = UDim2.new(0, 8, 1, -64);
    new.MouseButton1Click:Connect(function() editor.Text = template; status.Text = "Replace the example animation ID before saving."; end);
    local save = text_object("TextButton", frame, "Save JSON");
    save.Size = UDim2.fromOffset(120, 28);
    save.Position = UDim2.new(0.25, 4, 1, -64);
    save.MouseButton1Click:Connect(function()
        local ok, result = pcall(store.save, store, editor.Text);
        status.Text = ok and ("Saved " .. result .. ".json. Custom lookup refreshed.") or tostring(result);
        if ok then refresh_list(); end;
    end);
    status = text_object("TextLabel", frame, "Seconds, numeric-string IDs, ordered actions. Custom files only.");
    status.BackgroundTransparency = 1;
    status.TextWrapped = true;
    status.Size = UDim2.new(1, -16, 0, 30);
    status.Position = UDim2.new(0, 8, 1, -32);
    if aztup and aztup.maid then
        aztup.maid:give_task(function() gui:Destroy(); builder.visible = false; end);
    end;
end;
function builder:set_visible(value)
    if not value and not gui then return; end;
    ensure_ui();
    self.visible = value == true;
    frame.Visible = self.visible;
    if self.visible then refresh_list(); end;
end;
return builder;
