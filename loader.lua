-- Source loader. Publish your reviewed source and module-manifest.json first.
-- Override with getgenv().PROJECT_RAIN_SOURCE_URL for a trusted pinned revision.
local BASE = getgenv().PROJECT_RAIN_SOURCE_URL or "https://raw.githubusercontent.com/OkVurb/project-ponytail/master/";
BASE = BASE:gsub("/+$", "") .. "/";
local function fetch(relative)
    return game:HttpGet(BASE .. relative:gsub(" ", "%%20"));
end;
local factory, reason = loadstring(fetch("tools/runtime.lua"), "@tools/runtime");
assert(factory, reason);
local manifest = game:GetService("HttpService"):JSONDecode(fetch("module-manifest.json"));
assert(manifest.version == 1 and type(manifest.modules) == "table", "Invalid module manifest");
getgenv().PROJECT_RAIN_SOURCE_URL = BASE;
getgenv().PROJECT_RAIN_LOADER_URL = BASE .. "loader.lua";
local runtime = factory()({
    modules = manifest.modules,
    resolve = function(id)
        local chunk, err = loadstring(fetch("src/" .. id:sub(6) .. ".lua"), id);
        assert(chunk, err);
        return chunk;
    end,
    asset = function(id)
        local raw = fetch("assets/" .. id:sub(9));
        local encoding = game:GetService("EncodingService");
        local packed = encoding:CompressBuffer(buffer.fromstring(raw), Enum.CompressionAlgorithm.Zstd);
        return buffer.tostring(encoding:Base64Encode(packed));
    end,
});
return runtime.require("@src/init");
