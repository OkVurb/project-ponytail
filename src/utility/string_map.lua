-- Static release data, decoded independently of auto-parry initialization.
return function(asset)
    local encoding = services.EncodingService;
    local decoded = encoding:Base64Decode(buffer.fromstring(asset));
    local raw = encoding:DecompressBuffer(decoded, Enum.CompressionAlgorithm.Zstd);
    local data = services.HttpService:JSONDecode(buffer.tostring(raw));
    assert(type(data) == "table", "Expected a string lookup map");
    for key, value in pairs(data) do
        assert(type(key) == "string" and type(value) == "string" and #value > 0,
            "Invalid string lookup entry: " .. tostring(key));
    end;
    return data;
end;
