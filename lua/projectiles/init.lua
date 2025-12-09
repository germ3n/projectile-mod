AddCSLuaFile();

projectiles = projectiles or {};

include("config.lua");
include("surfaceprops.lua");
include("ray.lua");
include("net.lua");
include("penetration.lua");
include("move.lua");    
include("render.lua");
include("weapon_cfg.lua");
include("firebullets.lua");
include("props.lua");

print("loaded projectiles system");