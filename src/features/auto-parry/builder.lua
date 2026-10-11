--[[ Timing builder. combat.lua uses: builder:set_visible(bool), builder.on_close. ]]
local builder = {};
builder.visible = false;
builder.on_close = nil;
builder.selected = nil;

local gui, frame, list, strip;

local function names()
    local src = getgenv().timing_names and getgenv().timing_names() or getgenv().effect_names or {};
    return src;
end;

local function ensure_ui()
    if gui and gui.Parent then return end;
    gui = Instance.new("ScreenGui");
    gui.Name = "PR_TimingBuilder";
    gui.ResetOnSpawn = false;
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui");

    frame = Instance.new("Frame");
    frame.Size = UDim2.fromOffset(560, 260);
    frame.Position = UDim2.fromScale(0.5, 0.8);
    frame.AnchorPoint = Vector2.new(0.5, 1);
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28);
    frame.BorderSizePixel = 0;
    frame.Visible = false;
    frame.Active = true;
    frame.Draggable = true;
    frame.Parent = gui;
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8);

    local title = Instance.new("TextLabel");
    title.Size = UDim2.new(1, 0, 0, 26);
    title.BackgroundTransparency = 1;
    title.Text = "Timing Builder";
    title.TextColor3 = Color3.fromRGB(235, 235, 235);
    title.Font = Enum.Font.GothamMedium;
    title.TextSize = 14;
    title.Parent = frame;

    local close = Instance.new("TextButton");
    close.Size = UDim2.fromOffset(26, 26);
    close.Position = UDim2.new(1, -30, 0, 0);
    close.BackgroundTransparency = 1;
    close.Text = "X";
    close.TextColor3 = Color3.fromRGB(200, 200, 200);
    close.Parent = frame;
    close.MouseButton1Click:Connect(function()
        builder:set_visible(false);
        if builder.on_close then builder.on_close(); end;
    end);

    list = Instance.new("ScrollingFrame");
    list.Size = UDim2.new(0, 170, 1, -40);
    list.Position = UDim2.fromOffset(10, 32);
    list.BackgroundTransparency = 1;
    list.BorderSizePixel = 0;
    list.ScrollBarThickness = 4;
    list.CanvasSize = UDim2.new(0, 0, 0, 0);
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y;
    list.Parent = frame;

    local layout = Instance.new("UIListLayout");
    layout.SortOrder = Enum.SortOrder.LayoutOrder;
    layout.Padding = UDim.new(0, 3);
    layout.Parent = list;

    strip = Instance.new("Frame");
    strip.Size = UDim2.new(1, -200, 0, 60);
    strip.Position = UDim2.fromOffset(190, 40);
    strip.BackgroundColor3 = Color3.fromRGB(32, 32, 38);
    strip.BorderSizePixel = 0;
    strip.Parent = frame;
    Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 6);

    local save = Instance.new("TextButton");
    save.Size = UDim2.fromOffset(120, 26);
    save.Position = UDim2.fromOffset(190, 110);
    save.Text = "Save";
    save.Font = Enum.Font.GothamMedium;
    save.TextSize = 13;
    save.BackgroundColor3 = Color3.fromRGB(45, 45, 55);
    save.TextColor3 = Color3.fromRGB(230, 230, 230);
    save.Parent = frame;
    Instance.new("UICorner", save).CornerRadius = UDim.new(0, 6);
    save.MouseButton1Click:Connect(function()
        if builder.selected and getgenv().save_timing then
            pcall(getgenv().save_timing, builder.selected);
        end;
    end);

    for _, name in ipairs(names()) do
        local b = Instance.new("TextButton");
        b.Size = UDim2.new(1, -6, 0, 22);
        b.Text = tostring(name);
        b.TextXAlignment = Enum.TextXAlignment.Left;
        b.Font = Enum.Font.Gotham;
        b.TextSize = 12;
        b.BackgroundColor3 = Color3.fromRGB(38, 38, 44);
        b.TextColor3 = Color3.fromRGB(220, 220, 220);
        b.Parent = list;
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4);
        b.MouseButton1Click:Connect(function()
            builder.selected = name;
        end);
    end;
end;

function builder:set_visible(visible)
    ensure_ui();
    self.visible = visible and true or false;
    frame.Visible = self.visible;
end;

return builder;