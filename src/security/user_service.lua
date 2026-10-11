--[[ Original reported Luarmor-authenticated user. No key => report a local user. ]]
local user_service = {};
user_service.authenticated = true;
user_service.tier = "free";
user_service.key = getgenv().script_key or "no-key";

function user_service:get(_) return nil end;
function user_service:is_premium() return false end;
function user_service:has_role(_) return true end;

return user_service;