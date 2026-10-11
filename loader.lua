--[[ Key-free entry point. Run: loadstring(game:HttpGet("<raw url of this>"))() ]]
local BASE = "https://raw.githubusercontent.com/OkVurb/project-ponytail/main/";

local _cache = {};

local function resolve(path)
    if path:sub(1, 5) == "@src/" then
        return BASE .. "src/" .. path:sub(6) .. ".lua";
    elseif path:sub(1, 6) == "@meta/" then
        return BASE .. "meta/" .. path:sub(7) .. ".lua";
    end;
    return BASE .. path .. ".lua";
end;

local function pr_require(path)
    if _cache[path] ~= nil then return _cache[path]; end;
    local url = resolve(path);
    local src = game:HttpGet(url);
    local chunk, err = loadstring(src, path);
    if not chunk then
        error(string.format("[require] load failed for %s (%s): %s", path, url, tostring(err)), 2);
    end;
    local result = chunk();
    _cache[path] = result;
    return result;
end;

require = pr_require;
getgenv().require = pr_require;

builder_require = builder_require or pr_require;
getgenv().script_require = builder_require;

local _asset_cache = {};
inline_asset_b96 = function(path)
    if _asset_cache[path] then return _asset_cache[path] end;
    local rel = path:gsub("^@", "");
    local url = (BASE .. rel):gsub(" ", "%%20");
    local raw = game:HttpGet(url);
    local es = game:GetService("EncodingService");
    local compressed = es:CompressBuffer(buffer.fromstring(raw), Enum.CompressionAlgorithm.Zstd);
    local b64 = es:Base64Encode(compressed);
    _asset_cache[path] = b64;
    return b64;
end;

pr_require("@src/init");