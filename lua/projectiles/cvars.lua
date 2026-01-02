AddCSLuaFile();

local pro_projectiles_enabled = CreateConVar("pro_projectiles_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable projectiles", 0, 1);
local pro_penetration_power_cost_multiplier = CreateConVar("pro_penetration_power_cost_multiplier", "0.15", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration power cost multiplier", 0.0, 10.0);
local pro_penetration_dmg_tax_per_unit = CreateConVar("pro_penetration_dmg_tax_per_unit", "2.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration damage tax per unit", 0.0);
local pro_penetration_entry_cost_multiplier = CreateConVar("pro_penetration_entry_cost_multiplier", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration entry cost multiplier", 0.0, 10.0);
local pro_weapon_damage_scale = CreateConVar("pro_weapon_damage_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration weapon damage scale", 0.0, 10.0);
local pro_penetration_power_scale = CreateConVar("pro_penetration_power_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration power scale", 0.0, 10.0);
local pro_speed_scale = CreateConVar("pro_speed_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Speed scale", 0.0, 10.0);
local pro_debug = CreateConVar("pro_debug_projectiles", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles", 0, 1);
local pro_debug_duration = CreateConVar("pro_debug_duration", "4", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles duration", 0, 99999999);
local pro_debug_color = CreateConVar("pro_debug_color", "0 0 255", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles color");
local pro_debug_penetration = CreateConVar("pro_debug_penetration", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug penetration", 0, 1);
local pro_ricochet_enabled = CreateConVar("pro_ricochet_enabled", "0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable ricochet", 0, 1);
local pro_debug_ricochet = CreateConVar("pro_debug_ricochet", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug ricochet", 0, 1);
local pro_ricochet_chance = CreateConVar("pro_ricochet_chance", "0.1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet chance", 0.0, 1.0);
local pro_ricochet_spread = CreateConVar("pro_ricochet_spread", "0.2", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet spread", 0.0, 1.0);
local pro_ricochet_speed_multiplier = CreateConVar("pro_ricochet_speed_multiplier", "0.6", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet speed multiplier", 0.0, 1.0);
local pro_ricochet_damage_multiplier = CreateConVar("pro_ricochet_damage_multiplier", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet damage multiplier", 0.0, 1.0);
local pro_drag_enabled = CreateConVar("pro_drag_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable drag", 0, 1);
local pro_drag_multiplier = CreateConVar("pro_drag_multiplier", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Drag multiplier", 0.0, 10.0);
local pro_drag_water_multiplier = CreateConVar("pro_drag_water_multiplier", "4", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Drag water multiplier", 1.0, 25.0);
local pro_gravity_enabled = CreateConVar("pro_gravity_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable gravity", 0, 1);
local pro_gravity_multiplier = CreateConVar("pro_gravity_multiplier", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Gravity multiplier", 0.0, 10.0);
local pro_gravity_water_multiplier = CreateConVar("pro_gravity_water_multiplier", "100", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Gravity water multiplier", 0.0, 1000.0);
local pro_wind_enabled = CreateConVar("pro_wind_enabled", "0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable wind", 0, 1);
local pro_wind_strength = CreateConVar("pro_wind_strength", "10", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength", 0.0, 1000.0);
local pro_wind_strength_min_variance = CreateConVar("pro_wind_strength_min_variance", "0.8", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength min variance", 0.0, 10.0);
local pro_wind_strength_max_variance = CreateConVar("pro_wind_strength_max_variance", "1.2", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength max variance", 0.0, 10.0);
local pro_wind_min_update_interval = CreateConVar("pro_wind_min_update_interval", "30", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind update interval", 0, 99999999);
local pro_wind_max_update_interval = CreateConVar("pro_wind_max_update_interval", "60", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Max wind update interval", 0, 99999999);
local pro_wind_gust_chance = CreateConVar("pro_wind_gust_chance", "0.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind gust chance", 0.0, 1.0);
local pro_wind_gust_min_strength = CreateConVar("pro_wind_gust_min_strength", "0.1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind gust strength", 0.0, 1.0);
local pro_wind_gust_max_strength = CreateConVar("pro_wind_gust_max_strength", "0.3", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Max Wind gust strength", 0.0, 1.0);
local pro_wind_gust_min_duration = CreateConVar("pro_wind_gust_min_duration", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind gust duration", 0.0, 99999999);
local pro_wind_gust_max_duration = CreateConVar("pro_wind_gust_max_duration", "7.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Max wind gust duration", 0.0, 99999999);
local pro_wind_jitter_amount = CreateConVar("pro_wind_jitter_amount", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind jitter amount", 0.0, 100.0);
local pro_render_enabled = CreateConVar("pro_render_enabled", "1", bit.bor(FCVAR_ARCHIVE), "Enable render", 0, 1);
local pro_render_wind_hud = CreateConVar("pro_render_wind_hud", "1", bit.bor(FCVAR_ARCHIVE), "Enable wind hud", 0, 1);
local pro_net_reliable = CreateConVar("pro_net_reliable", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Enable net reliable", 0, 1);
local pro_net_method = CreateConVar("pro_net_send_method", "1", bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Networking send method", 0, 2); -- 0 PVS, 1 PAS, 2 Broadcast

PROJECTILE_CVAR_NAMES = {
    "pro_projectiles_enabled",
    "pro_penetration_power_cost_multiplier",
    "pro_penetration_dmg_tax_per_unit",
    "pro_penetration_entry_cost_multiplier",
    "pro_weapon_damage_scale",
    "pro_penetration_power_scale",
    "pro_speed_scale",
    "pro_debug_projectiles",
    "pro_debug_duration",
    "pro_debug_color",
    "pro_debug_penetration",
    "pro_ricochet_enabled",
    "pro_debug_ricochet",
    "pro_ricochet_chance",
    "pro_ricochet_spread",
    "pro_ricochet_speed_multiplier",
    "pro_ricochet_damage_multiplier",
    "pro_drag_enabled",
    "pro_drag_multiplier",
    "pro_drag_water_multiplier",
    "pro_gravity_enabled",
    "pro_gravity_multiplier",
    "pro_gravity_water_multiplier",
    "pro_wind_enabled",
    "pro_wind_strength",
    "pro_wind_strength_min_variance",
    "pro_wind_strength_max_variance",
    "pro_wind_min_update_interval",
    "pro_wind_max_update_interval",
    "pro_wind_gust_chance",
    "pro_wind_gust_min_strength",
    "pro_wind_gust_max_strength",
    "pro_wind_gust_min_duration",
    "pro_wind_gust_max_duration",
    "pro_wind_jitter_amount",
    "pro_render_enabled",
    "pro_render_wind_hud",
    "pro_net_reliable",
    "pro_net_send_method",
};