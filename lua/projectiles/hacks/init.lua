AddCSLuaFile();

if SERVER then
    include("realistic_blood.lua");
    include("shellshock.lua");
    include("muzzleflash.lua");
end

if CLIENT then
end

include("enhanced_blood_splatters.lua");

print("loaded projectiles hacks");