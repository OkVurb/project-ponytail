-- Shared source/bundle runtime. Project modules use a shared environment;
-- native ModuleScript requires never pass through the project resolver.
return function(config)
    local host = config.host or getfenv(0);
    local global = config.global or getgenv();
    local native_require = global.pr_native_require or host.require;
    local cache, loading, asset_cache = {}, {}, {};
    local known = {};
    for _, id in ipairs(config.modules) do known[id] = true; end;
    local env = setmetatable({}, {
        __index = function(_, key)
            local value = global[key];
            if value ~= nil then return value; end;
            return host[key];
        end,
        __newindex = function(_, key, value) global[key] = value; end,
    });
    local function normalize(id)
        id = id:gsub("%.lua$", "");
        if known[id] then return id; end;
        if known[id .. "/init"] then return id .. "/init"; end;
        error("[Project Ponytail] Unknown module: " .. id, 3);
    end;
    local function project_require(id)
        if type(id) ~= "string" or id:sub(1, 5) ~= "@src/" then
            return native_require(id);
        end;
        id = normalize(id);
        if cache[id] then return table.unpack(cache[id], 1, cache[id].n); end;
        local owner = coroutine.running();
        if loading[id] == owner then error("[Project Ponytail] Circular require: " .. id, 2); end;
        while loading[id] do
            assert(host.task and host.task.wait, "Concurrent require needs task.wait");
            host.task.wait();
        end;
        if cache[id] then return table.unpack(cache[id], 1, cache[id].n); end;
        loading[id] = owner;
        local values = table.pack(pcall(function()
            local factory = config.resolve(id);
            assert(type(factory) == "function", "Module resolver did not return a function: " .. id);
            setfenv(factory, env);
            return factory();
        end));
        loading[id] = nil;
        if not values[1] then error("[Project Ponytail] " .. id .. ": " .. tostring(values[2]), 2); end;
        local result = { n = values.n - 1 };
        for i = 2, values.n do result[i - 1] = values[i]; end;
        if result.n == 0 then result = table.pack(true); end;
        cache[id] = result;
        return table.unpack(result, 1, result.n);
    end;
    local function list_modules(pattern)
        pattern = pattern:gsub("^@src/", ""):gsub("%.lua$", "");
        local escaped = pattern:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"):gsub("%*", "[^/]*");
        local result = {};
        for _, id in ipairs(config.modules) do
            if id:sub(6):match("^" .. escaped .. "$") then table.insert(result, id); end;
        end;
        table.sort(result);
        return result;
    end;
    local function asset(id)
        assert(type(id) == "string" and id:sub(1, 8) == "@assets/", "Expected an @assets path");
        if asset_cache[id] == nil then asset_cache[id] = config.asset(id); end;
        assert(type(asset_cache[id]) == "string", "Asset encoder must return a string");
        return asset_cache[id];
    end;
    rawset(env, "require", project_require);
    rawset(env, "base_require", native_require);
    rawset(env, "builder_require", project_require);
    rawset(env, "list_modules", list_modules);
    rawset(env, "inline_asset_b96", asset);
    global.pr_native_require = native_require;
    global.base_require = native_require;
    global.builder_require = project_require;
    global.script_require = project_require;
    global.list_modules = list_modules;
    global.inline_asset_b96 = asset;
    return { require = project_require, list_modules = list_modules, env = env };
end;
