-- Generated manifest is separate so rebuilding cannot erase loader behavior.
local manifest = require("@src/features/manifest");
local loader = {};
function loader.initialize()
    assert(aztup and aztup.features, "Initialize aztup before registering features");
    local registered, skipped, failed = 0, 0, 0;
    for _, id in ipairs(manifest) do
        local ok, feature = pcall(require, id);
        if not ok then
            failed += 1;
            warn(string.format("[features][oss] require failed: %s | %s", id, tostring(feature)));
        elseif type(feature) == "table" and type(feature.id) == "string" then
            if not aztup.features[feature.id] then
                aztup.features[feature.id] = feature;
                registered += 1;
            else
                skipped += 1;
                if aztup.features[feature.id] ~= feature then
                    failed += 1;
                    warn("[features][oss] duplicate feature id: " .. feature.id);
                end;
            end;
        else
            skipped += 1;
        end;
    end;
    loader.last_report = { registered = registered, skipped = skipped, failed = failed };
    warn(string.format("[features][oss] %d registered, %d skipped, %d failed", registered, skipped, failed));
    return aztup.features;
end;
return loader;
