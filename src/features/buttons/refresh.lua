--[[ Respawn in place. Not usable in combat; breaks menus. ]]
return function()
    local plr = game:GetService("Players").LocalPlayer;
    local char = plr.Character;
    if not char then return end;
    local root = char:FindFirstChild("HumanoidRootPart");
    local saved = root and root.CFrame;
    plr:LoadCharacter();
    local new = plr.Character or plr.CharacterAdded:Wait();
    new:WaitForChild("HumanoidRootPart");
    if saved then
        task.wait(0.1);
        new.HumanoidRootPart.CFrame = saved;
    end;
end;