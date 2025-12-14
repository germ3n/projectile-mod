AddCSLuaFile();

projectiles = projectiles or {};

include("cvars.lua");
include("cache.lua");
include("surfaceprops.lua");
include("ray.lua");
include("net.lua");
include("hacks/init.lua");
include("penetration.lua");
include("move.lua");    
include("render.lua");
include("weapon_cfg.lua");
include("firebullets.lua");
include("props.lua");
include("config.lua");

print("loaded projectiles system");