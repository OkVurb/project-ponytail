--[[ Private build ran Luarmor's key/auth flow here. Reduced to a no-auth shim. ]]
require("@src/globals");

LPH_OBFUSCATED = LPH_OBFUSCATED or false;
LRM_ScriptName = LRM_ScriptName or "Project Rain";

script_key = script_key or "no-key";
getgenv().script_key = script_key;

luarmor_preload_time = luarmor_preload_time or tick();
luarmor_preload_time_debug = luarmor_preload_time_debug or luarmor_preload_time;

STR_TBL_SF_INVOKE = STR_TBL_SF_INVOKE or function(s) return s end;
PROT_OBF_STR_SAFE_MACRO = PROT_OBF_STR_SAFE_MACRO or function(...) return ... end;
AUTH_GET_CONSTANT = AUTH_GET_CONSTANT or function(...) return ... end;

if not list_modules then list_modules = function() return {} end end;

return true;