-- Observes tracks only; never plays, stops or changes a game animation.
return function(root, observe)
    local subscriptions, active = {}, true;
    local function report(track, animator)
        if not active or not track.Animation then return; end;
        local id = track.Animation.AnimationId:match("%d+");
        if not id then return; end;
        local ok, err = pcall(observe, track, animator:FindFirstAncestorOfClass("Model"), id);
        if not ok then warn("[Project Ponytail] Animation watcher: " .. tostring(err)); end;
    end;
    local function attach(item)
        if not active or not item:IsA("Animator") or subscriptions[item] then return; end;
        subscriptions[item] = item.AnimationPlayed:Connect(function(track) report(track, item); end);
        local ok, tracks = pcall(item.GetPlayingAnimationTracks, item);
        if ok then
            for _, track in ipairs(tracks) do report(track, item); end;
        else warn("[Project Ponytail] Animation snapshot: " .. tostring(tracks)); end;
    end;
    local added = root.DescendantAdded:Connect(attach);
    local removing = root.DescendantRemoving:Connect(function(item)
        if subscriptions[item] then subscriptions[item]:Disconnect(); subscriptions[item] = nil; end;
    end);
    for _, item in ipairs(root:GetDescendants()) do attach(item); end;
    return function()
        if not active then return; end;
        active = false;
        added:Disconnect(); removing:Disconnect();
        for _, connection in pairs(subscriptions) do connection:Disconnect(); end;
        table.clear(subscriptions);
    end;
end;
