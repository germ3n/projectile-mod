AddCSLuaFile();

pro_projectiles_enabled = CreateConVar("pro_projectiles_enabled", "1", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable projectiles");
pro_debug = CreateConVar("pro_debug_projectiles", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles");
pro_debug_duration = CreateConVar("pro_debug_duration", "4", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles duration");
pro_debug_color = CreateConVar("pro_debug_color", "0 0 255", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles color");
pro_debug_penetration = CreateConVar("pro_debug_penetration", "0", bit.bor(FCVAR_NOTIFY, FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug penetration");
pro_ricochet_enabled = CreateConVar("pro_ricochet_enabled", "0", bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable ricochet");
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