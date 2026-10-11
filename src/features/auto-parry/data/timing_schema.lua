-- JSON-only custom timing format. No executable timing files are created.
local schema = {};
local action_types = { Parry = true, Block = true, Roll = true, ["End Block"] = true };
local timing_fields = { name = true, ids = true, actions = true, action_type = true };
local move_types = { M1 = true, Critical = true, Spell = true, Bell = true, Untagged = true, Undefined = true };
local action_fields = { when = true, type = true, hitbox = true, offset = true };
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge;
end;
local function array(value, message)
    assert(type(value) == "table" and #value > 0, message);
    local count = 0;
    for key in pairs(value) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #value,
            "Expected a dense array");
        count += 1;
    end;
    assert(count == #value, "Expected a dense array");
end;
function schema.validate(data)
    assert(type(data) == "table", "Timing must be an object");
    for key in pairs(data) do assert(timing_fields[key], "Unsupported timing field: " .. tostring(key)); end;
    assert(data.action_type == nil or move_types[data.action_type], "Unsupported move type");
    assert(type(data.name) == "string" and #data.name <= 64 and data.name:match("^[%w_%-]+$"),
        "Name must contain only letters, numbers, underscores or hyphens");
    array(data.ids, "Add at least one animation ID");
    for _, id in ipairs(data.ids) do
        assert(type(id) == "string" and id:match("^%d+$"), "Animation IDs must be numeric strings");
    end;
    array(data.actions, "Add at least one action");
    local last = 0;
    for _, action in ipairs(data.actions) do
        assert(type(action) == "table", "Each action must be an object");
        for key in pairs(action) do assert(action_fields[key], "Unsupported action field: " .. tostring(key)); end;
        assert(finite(action.when) and action.when >= last, "Action times must be nonnegative, finite and sorted");
        last = action.when;
        assert(action_types[action.type], "Action type must be Parry, Block, Roll or End Block");
        for _, key in ipairs({ "hitbox", "offset" }) do
            local value = action[key];
            if value ~= nil then
                assert(type(value) == "table", key .. " must be an object with X, Y, Z");
                for axis in pairs(value) do
                    assert(axis == "X" or axis == "Y" or axis == "Z", "Unsupported " .. key .. " field");
                end;
                for _, axis in ipairs({ "X", "Y", "Z" }) do
                    assert(finite(value[axis]), key .. "." .. axis .. " must be a finite number");
                    if key == "hitbox" then assert(value[axis] >= 0, "Hitbox dimensions cannot be negative"); end;
                end;
            end;
        end;
    end;
    return data;
end;
return schema;
