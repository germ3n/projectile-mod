AddCSLuaFile();

pro_projectiles_enabled = CreateConVar("pro_projectiles_enabled", "1", bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable projectiles");
pro_debug = CreateConVar("pro_debug_projectiles", "0", bit.bor(FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles");
pro_debug_duration = CreateConVar("pro_debug_duration", "4", bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles duration");
pro_debug_color = CreateConVar("pro_debug_color", "0 0 255", bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug projectiles color");
pro_debug_penetration = CreateConVar("pro_debug_penetration", "0", bit.bor(FCVAR_CHEAT, FCVAR_REPLICATED, FCVAR_ARCHIVE), "Debug penetration");
pro_ricochet_enabled = CreateConVar("pro_ricochet_enabled", "1", bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE), "Enable ricochet");