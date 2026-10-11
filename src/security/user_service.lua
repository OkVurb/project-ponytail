-- Local OSS identity, not proof of paid access or remote authentication.
local user_service = { authenticated = false, tier = "oss", key = "no-key" };
function user_service:get(key) return self[key]; end;
function user_service:is_premium() return false; end;
function user_service:has_role(role) return role == "oss" or role == "free"; end;
return user_service;
