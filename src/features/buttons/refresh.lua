-- LoadCharacter is server-only. Use the executor's existing reset signal.
local refreshing;
return function()
    local player = services.Players.LocalPlayer;
    local character = player.Character;
    local root = character and character:FindFirstChild("HumanoidRootPart");
    if refreshing or not root then return false; end;
    if EffectReplicator and (EffectReplicator:FindEffect("Danger") or EffectReplicator:FindEffect("Combat")) then
        warn("[Project Ponytail] Cannot refresh while in combat.");
        return false;
    end;
    if type(replicatesignal) ~= "function" then
        warn("[Project Ponytail] Refresh needs replicatesignal. Use the game's normal reset instead.");
        return false;
    end;
    local saved = root.CFrame;
    local connection;
    connection = player.CharacterAdded:Connect(function(new_character)
        if new_character == character then return; end;
        connection:Disconnect();
        task.spawn(function()
            local new_root = new_character:WaitForChild("HumanoidRootPart", 15);
            if refreshing ~= connection then return; end;
            if new_root and player.Character == new_character then new_root.CFrame = saved; end;
            refreshing = nil;
        end);
    end);
    refreshing = connection;
    if aztup and aztup.maid then aztup.maid:give_task(connection); end;
    local ok, reason = pcall(function() replicatesignal(player.Kill); end);
    if not ok then connection:Disconnect(); refreshing = nil; warn(reason); return false; end;
    task.delay(20, function()
        if refreshing ~= connection then return; end;
        connection:Disconnect(); refreshing = nil;
        warn("[Project Ponytail] Refresh timed out waiting for a new character.");
    end);
    return true;
end;
