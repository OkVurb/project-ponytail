--[[ Feature loader (the pass stripped from the OSS release). See HANDOFF.md. ]]
local loader = {};

if not Feature then
    Feature = require("@src/features/generic_feature");
end;
getgenv().Feature = Feature;

aztup_toggles = aztup_toggles or {};
aztup_options = aztup_options or {};
getgenv().aztup_toggles = aztup_toggles;
getgenv().aztup_options = aztup_options;

local EXCLUDE = {
    "features/auto-parry/data/",
    "features/auto-parry/handlers/animator-handler",
    "features/auto-parry/util/",
    "features/auto-parry/services/",
    "features/auto-parry/fallbacks/",
    "features/generic_feature",
    "features/hooking",
    "features/loader",
};

local GLOBS = {
    "features/*/*",
    "features/removals/mantra_revealer/*",
    "features/misc/mod_detector/*",
    "features/buttons/teleports/*",
};

local FALLBACK = {
    "@src/features/auto-builder/auto_builder",
    "@src/features/auto-fight/auto-fight",
    "@src/features/auto-loot/auto-loot",
    "@src/features/automation/auto_brutus",
    "@src/features/automation/auto_chime_requeue",
    "@src/features/automation/auto_decline_guild_invites",
    "@src/features/automation/auto_decline_squad_invites",
    "@src/features/automation/auto_equip_weapon",
    "@src/features/automation/auto_fish",
    "@src/features/automation/auto_flow_state",
    "@src/features/automation/auto_ragdoll_cancel",
    "@src/features/automation/auto_roll_cancel",
    "@src/features/automation/auto_sprint",
    "@src/features/automation/auto_train_agility",
    "@src/features/automation/auto_uppercut",
    "@src/features/automation/auto_wisp",
    "@src/features/automation/backstab_movestacker",
    "@src/features/automation/charisma_farm",
    "@src/features/automation/intelligence_farm",
    "@src/features/buttons/auto_trial",
    "@src/features/buttons/generic_teleport",
    "@src/features/buttons/tp_to_floor",
    "@src/features/buttons/tp_to_guildbase",
    "@src/features/buttons/tp_to_objectives",
    "@src/features/buttons/tp_to_roof",
    "@src/features/buttons/tp_to_void",
    "@src/features/buttons/teleports/depths",
    "@src/features/buttons/teleports/eastern",
    "@src/features/buttons/teleports/etrean",
    "@src/features/buttons/teleports/trial",
    "@src/features/combat/anim_speed_changer",
    "@src/features/combat/attach_to_back",
    "@src/features/combat/auto_air_counter",
    "@src/features/combat/auto_ardour",
    "@src/features/combat/auto_dustlunge",
    "@src/features/combat/auto_golden_tongue",
    "@src/features/combat/auto_reinforce",
    "@src/features/combat/easy_feint",
    "@src/features/combat/easy_roll_cancel",
    "@src/features/combat/fast_swing",
    "@src/features/combat/m1_hold",
    "@src/features/combat/mantra_rolling",
    "@src/features/combat/mantra_slidecasting",
    "@src/features/combat/safe_input",
    "@src/features/combat/silent_aim",
    "@src/features/combat/stored_damage_tracker",
    "@src/features/combat/vehicle_noclip",
    "@src/features/combat/vehicle_speed",
    "@src/features/exploits/ap_breaker",
    "@src/features/exploits/boat_teleport",
    "@src/features/exploits/kamui_teleport",
    "@src/features/exploits/mob_ai_breaker",
    "@src/features/exploits/no_anims",
    "@src/features/exploits/raknet_fakelag",
    "@src/features/exploits/voi_teleport",
    "@src/features/misc/anchor",
    "@src/features/misc/apply_fflags",
    "@src/features/misc/build_stealer",
    "@src/features/misc/hair_id_stealer",
    "@src/features/misc/linoria_watermark",
    "@src/features/misc/mod_detector/mod_detector",
    "@src/features/misc/opiumware_fix",
    "@src/features/misc/override_deepwoken_cursor",
    "@src/features/misc/override_roblox_reset",
    "@src/features/misc/proximity_list",
    "@src/features/misc/streamer_mode",
    "@src/features/misc/talent_highlighter",
    "@src/features/movement/fly",
    "@src/features/movement/infinite_jump",
    "@src/features/movement/knocked_ownership",
    "@src/features/movement/multiply_s",
    "@src/features/movement/noclip",
    "@src/features/movement/speed",
    "@src/features/movement/tick_rate",
    "@src/features/qol/aggressive_optimize_game",
    "@src/features/qol/brayden",
    "@src/features/qol/bring_mobs",
    "@src/features/qol/combosser_detector",
    "@src/features/qol/experimental_bug_fixes",
    "@src/features/qol/extend_prompts",
    "@src/features/qol/fake_void",
    "@src/features/qol/fall_multiplier",
    "@src/features/qol/fast_mode",
    "@src/features/qol/fps_booster",
    "@src/features/qol/girl_detector",
    "@src/features/qol/give_animation_gamepass",
    "@src/features/qol/jesus",
    "@src/features/qol/minesweeper",
    "@src/features/qol/optimize_game",
    "@src/features/qol/parry_sounds",
    "@src/features/qol/restore_old_weapon_behavior",
    "@src/features/qol/snake_game",
    "@src/features/qol/tetris",
    "@src/features/qol/void_mobs",
    "@src/features/removals/anti_afk",
    "@src/features/removals/harrow_remover",
    "@src/features/removals/mantra_revealer/mantra_revealer",
    "@src/features/removals/no_blind",
    "@src/features/removals/no_blur",
    "@src/features/removals/no_cl_gate",
    "@src/features/removals/no_clouds",
    "@src/features/removals/no_depths_trial_voices",
    "@src/features/removals/no_echo_screen",
    "@src/features/removals/no_fall",
    "@src/features/removals/no_fire",
    "@src/features/removals/no_flame_blind",
    "@src/features/removals/no_fog",
    "@src/features/removals/no_hive_gate",
    "@src/features/removals/no_kill_bricks",
    "@src/features/removals/no_mob_encounters",
    "@src/features/removals/no_one_bit",
    "@src/features/removals/no_roll_fatigue",
    "@src/features/removals/no_sanity_vfx",
    "@src/features/removals/no_sea",
    "@src/features/removals/no_speed_debuff",
    "@src/features/removals/no_status_effects",
    "@src/features/removals/no_stun",
    "@src/features/removals/no_wind",
    "@src/features/removals/no_yun_shul_gate",
    "@src/features/removals/roll2_revealer",
    "@src/features/spoofing/agility_spoofer",
    "@src/features/spoofing/endurance_runner_spoof",
    "@src/features/spoofing/freestylers_band_spoof",
    "@src/features/spoofing/kongas_spoof",
    "@src/features/spoofing/lightweight_spoof",
    "@src/features/spoofing/momentum_spoof",
    "@src/features/visuals/auto_hide_hud",
    "@src/features/visuals/base_esp",
    "@src/features/visuals/chain_counter",
    "@src/features/visuals/free_cam",
    "@src/features/visuals/full_bright",
    "@src/features/visuals/inf_zoom",
    "@src/features/visuals/leaderboard_spectate",
    "@src/features/visuals/no_shadows",
    "@src/features/visuals/player_esp",
    "@src/features/visuals/race_morph_menu",
    "@src/features/visuals/sanity_indicator",
    "@src/features/visuals/show_all_on_map",
    "@src/features/visuals/show_chat",
    "@src/features/visuals/stream_proof_esp",
    "@src/features/visuals/zoom",
};

local function is_excluded(path)
    for _, frag in ipairs(EXCLUDE) do
        if path:find(frag, 1, true) then return true; end;
    end;
    return false;
end;

local function discover()
    if type(list_modules) == "function" then
        local out = {};
        for _, glob in ipairs(GLOBS) do
            local ok, modules = pcall(list_modules, glob);
            if ok and type(modules) == "table" then
                for _, path in ipairs(modules) do out[#out + 1] = path; end;
            end;
        end;
        if #out > 0 then return out; end;
    end;
    return FALLBACK;
end;

function loader.initialize()
    local registered, skipped, failed = 0, 0, 0;
    for _, path in ipairs(discover()) do
        if is_excluded(path) then skipped += 1; continue end;
        local ok, feature = pcall(require, path);
        if not ok then
            failed += 1;
            warn(string.format("[features][oss] require failed: %s | %s", path, tostring(feature)));
            continue;
        end;
        if type(feature) == "table" and type(feature.id) == "string" then
            if not aztup.features[feature.id] then
                aztup.features[feature.id] = feature;
                registered += 1;
            end;
        else
            skipped += 1;
        end;
    end;
    warn(string.format("[features][oss] %d registered, %d skipped, %d failed", registered, skipped, failed));
    return aztup.features;
end;

return loader;