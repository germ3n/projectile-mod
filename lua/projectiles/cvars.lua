AddCSLuaFile();

pro_projectiles_enabled = CreateConVar("pro_projectiles_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable projectiles");
pro_penetration_power_cost_multiplier = CreateConVar("pro_penetration_power_cost_multiplier", "0.15", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration power cost multiplier");
pro_penetration_dmg_tax_per_unit = CreateConVar("pro_penetration_dmg_tax_per_unit", "2.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration damage tax per unit");
pro_penetration_entry_cost_multiplier = CreateConVar("pro_penetration_entry_cost_multiplier", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration entry cost multiplier");
pro_weapon_damage_scale = CreateConVar("pro_weapon_damage_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration weapon damage scale");
pro_penetration_power_scale = CreateConVar("pro_penetration_power_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Penetration power scale");
pro_speed_scale = CreateConVar("pro_speed_scale", "1.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Speed scale");
pro_debug = CreateConVar("pro_debug_projectiles", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles");
pro_debug_duration = CreateConVar("pro_debug_duration", "4", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles duration");
pro_debug_color = CreateConVar("pro_debug_color", "0 0 255", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles color");
pro_debug_penetration = CreateConVar("pro_debug_penetration", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug penetration");
pro_ricochet_enabled = CreateConVar("pro_ricochet_enabled", "0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable ricochet");
pro_debug_ricochet = CreateConVar("pro_debug_ricochet", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug ricochet");
pro_ricochet_chance = CreateConVar("pro_ricochet_chance", "0.25", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet chance");
pro_ricochet_spread = CreateConVar("pro_ricochet_spread", "0.2", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet spread");
pro_ricochet_speed_multiplier = CreateConVar("pro_ricochet_speed_multiplier", "0.6", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet speed multiplier");
pro_ricochet_damage_multiplier = CreateConVar("pro_ricochet_damage_multiplier", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet damage multiplier");
pro_ricochet_distance_multiplier = CreateConVar("pro_ricochet_distance_multiplier", "2.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Ricochet distance multiplier");
pro_drag_enabled = CreateConVar("pro_drag_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable drag");
pro_drag_multiplier = CreateConVar("pro_drag_multiplier", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Drag multiplier");
pro_drag_water_multiplier = CreateConVar("pro_drag_water_multiplier", "4", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Drag water multiplier");
pro_gravity_enabled = CreateConVar("pro_gravity_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable gravity");
pro_gravity_multiplier = CreateConVar("pro_gravity_multiplier", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Gravity multiplier");
pro_gravity_water_multiplier = CreateConVar("pro_gravity_water_multiplier", "100", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Gravity water multiplier");
pro_wind_enabled = CreateConVar("pro_wind_enabled", "0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable wind");
pro_wind_strength = CreateConVar("pro_wind_strength", "2.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength");
pro_wind_strength_min_variance = CreateConVar("pro_wind_strength_min_variance", "0.8", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength min variance");
pro_wind_strength_max_variance = CreateConVar("pro_wind_strength_max_variance", "1.2", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind strength max variance");
pro_wind_gust_chance = CreateConVar("pro_wind_gust_chance", "0.2", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind gust chance");
pro_wind_gust_min_strength = CreateConVar("pro_wind_gust_min_strength", "0.1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind gust strength");
pro_wind_gust_max_strength = CreateConVar("pro_wind_gust_max_strength", "0.3", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind gust strength");
pro_wind_gust_min_duration = CreateConVar("pro_wind_gust_min_duration", "0.5", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Min wind gust duration");
pro_wind_gust_max_duration = CreateConVar("pro_wind_gust_max_duration", "7.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Max wind gust duration");
pro_wind_change_min_duration = CreateConVar("pro_wind_change_min_duration", "4.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind frequency direction");
pro_wind_change_max_duration = CreateConVar("pro_wind_change_max_duration", "15.0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind frequency direction");
pro_wind_change_speed = CreateConVar("pro_wind_change_speed", "0.1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Wind change speed");
pro_render_enabled = CreateConVar("pro_render_enabled", "1", bit.bor(FCVAR_ARCHIVE), "Enable render");
pro_render_wind_hud = CreateConVar("pro_render_wind_hud", "1", bit.bor(FCVAR_ARCHIVE), "Enable wind hud");

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
	"pro_ricochet_distance_multiplier",
	"pro_drag_enabled",
	"pro_drag_multiplier",
	"pro_drag_water_multiplier",
	"pro_gravity_enabled",
	"pro_gravity_multiplier",
	"pro_gravity_water_multiplier",
	"pro_render_enabled",
	"pro_wind_enabled",
	"pro_wind_strength",
	"pro_wind_strength_min_variance",
	"pro_wind_strength_max_variance",
	"pro_wind_gust_chance",
	"pro_wind_gust_min_strength",
	"pro_wind_gust_max_strength",
	"pro_wind_gust_min_duration",
	"pro_wind_gust_max_duration",
	"pro_wind_change_min_duration",
	"pro_wind_change_max_duration",
	"pro_wind_change_speed",
	"pro_render_wind_hud",
};