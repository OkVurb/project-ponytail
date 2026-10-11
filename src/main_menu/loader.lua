--[[ Menu-place (4111023553) loader stub. Builds a tiny join UI. ]]
return function()
    if game:GetService("CoreGui"):FindFirstChild("PR_Menu") then return end;
    local gui = Instance.new("ScreenGui");
    gui.Name = "PR_Menu";
    gui.ResetOnSpawn = false;
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui");

    local frame = Instance.new("Frame");
    frame.Size = UDim2.fromOffset(320, 180);
    frame.Position = UDim2.fromScale(0.5, 0.5);
    frame.AnchorPoint = Vector2.new(0.5, 0.5);
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 26);
    frame.Parent = gui;
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10);

    local title = Instance.new("TextLabel");
    title.Size = UDim2.new(1, 0, 0, 40);
    title.BackgroundTransparency = 1;
    title.Text = "Project Rain";
    title.TextColor3 = Color3.fromRGB(240, 240, 240);
    title.Font = Enum.Font.GothamBold;
    title.TextSize = 20;
    title.Parent = frame;

    local join = Instance.new("TextButton");
    join.Size = UDim2.fromOffset(200, 36);
    join.Position = UDim2.new(0.5, -100, 0.5, 10);
    join.Text = "Play Deepwoken";
    join.BackgroundColor3 = Color3.fromRGB(45, 45, 55);
    join.TextColor3 = Color3.fromRGB(235, 235, 235);
    join.Font = Enum.Font.GothamMedium;
    join.TextSize = 14;
    join.Parent = frame;
    Instance.new("UICorner", join).CornerRadius = UDim.new(0, 6);

    join.MouseButton1Click:Connect(function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(5735553160);
        end);
    end);
end;