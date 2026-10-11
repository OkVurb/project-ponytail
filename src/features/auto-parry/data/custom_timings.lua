local schema = require("@src/features/auto-parry/data/timing_schema");
local store = { directory = "Project Rain/Custom Timings", raw = {}, data = {}, by_id = {} };
local function convert(data)
    local copy = table.clone(data);
    copy.actions = {};
    for _, action in ipairs(data.actions) do
        local item = table.clone(action);
        local hitbox, offset = action.hitbox, action.offset;
        if hitbox then item.hitbox = Vector3.new(hitbox.X, hitbox.Y, hitbox.Z); end;
        if offset then item.offset = CFrame.new(offset.X, offset.Y, offset.Z); end;
        table.insert(copy.actions, item);
    end;
    return copy;
end;
function store:sync()
    if not isfolder(self.directory) then makefolder(self.directory); end;
    local files = listfiles(self.directory);
    table.sort(files);
    local present = {};
    for _, file in ipairs(files) do
        local name = file:gsub("\\", "/"):match("/([%w_%-]+)%.json$");
        if name and isfile(file) then
            present[name] = true;
            local ok, source, data = pcall(function()
                local source = readfile(file);
                local data = schema.validate(services.HttpService:JSONDecode(source));
                assert(data.name == name, "Filename must match timing name");
                return source, data;
            end);
            if ok then
                self.raw[name] = source;
                self.data[name] = convert(data);
            else
                -- Keep the last valid entry when an edit is partial or malformed.
                warn("[Project Ponytail] Invalid custom timing " .. name .. ": " .. tostring(source));
            end;
        end;
    end;
    for name in pairs(self.data) do
        if not present[name] then self.data[name] = nil; self.raw[name] = nil; end;
    end;
    table.clear(self.by_id);
    local names = {};
    for name in pairs(self.data) do table.insert(names, name); end;
    table.sort(names);
    for _, name in ipairs(names) do
        for _, id in ipairs(self.data[name].ids) do self.by_id[id] = name; end;
    end;
    return self.data;
end;
function store:lookup(id)
    id = tostring(id):match("%d+$") or tostring(id);
    local name = self.by_id[id];
    return name and self.data[name], name;
end;
function store:save(source)
    local data = schema.validate(services.HttpService:JSONDecode(source));
    if not isfolder(self.directory) then makefolder(self.directory); end;
    local encoded = services.HttpService:JSONEncode(data);
    writefile(self.directory .. "/" .. data.name .. ".json", encoded);
    self:sync();
    return data.name;
end;
store:sync();
return store;
