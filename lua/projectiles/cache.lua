AddCSLuaFile();

local projectiles = projectiles;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;
local get_string = convar_meta.GetString;

local get_convar = GetConVar;

local next = next;

local red = Color(255, 0, 0);
local green = Color(0, 255, 0);
local blue = Color(0, 0, 255);
local white = Color(255, 255, 255);

local TRACK_CVARS = {
    {"projectiles_enabled", "bool", "pro_projectiles_enabled"},
    {"debug_projectiles", "bool", "pro_debug_projectiles"},
    {"debug_duration", "float", "pro_debug_duration"},
    {"debug_color", "string", "pro_debug_color"},
    {"debug_penetration", "bool", "pro_debug_penetration"},
    {"ricochet_enabled", "bool", "pro_ricochet_enabled"},
    {"ricochet_chance", "float", "pro_ricochet_chance"},
    {"ricochet_spread", "float", "pro_ricochet_spread"},
    {"ricochet_speed_multiplier", "float", "pro_ricochet_speed_multiplier"},
    {"ricochet_damage_multiplier", "float", "pro_ricochet_damage_multiplier"},
    {"ricochet_distance_multiplier", "float", "pro_ricochet_distance_multiplier"},
    {"drag_enabled", "bool", "pro_drag_enabled"},
    {"drag_multiplier", "float", "pro_drag_multiplier"},
    {"drag_water_multiplier", "float", "pro_drag_water_multiplier"},
    {"gravity_enabled", "bool", "pro_gravity_enabled"},
    {"gravity_multiplier", "float", "pro_gravity_multiplier"},
    {"gravity_water_multiplier", "float", "pro_gravity_water_multiplier"},
    {"gravity", "float", "sv_gravity"},
};

print("loaded projectiles cache");
