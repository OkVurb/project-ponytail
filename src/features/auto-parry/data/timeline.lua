local timeline = {};
function timeline.extent(data, length)
    local last = data.actions[#data.actions].when;
    return math.max(1, length or 0, last + 0.25);
end;
function timeline.move(data, action, seconds)
    assert(table.find(data.actions, action), "Select an existing action");
    assert(type(seconds) == "number" and seconds == seconds and math.abs(seconds) < math.huge,
        "Time must be finite");
    local rounded = math.round(seconds * 1000) / 1000;
    action.when = math.max(0, math.abs(rounded) < math.huge and rounded or seconds);
    -- Stable ordering keeps simultaneous block/end-block actions in their original order.
    for index = 2, #data.actions do
        local item, position = data.actions[index], index;
        while position > 1 and data.actions[position - 1].when > item.when do
            data.actions[position] = data.actions[position - 1];
            position -= 1;
        end;
        data.actions[position] = item;
    end;
    return action;
end;
return timeline;
