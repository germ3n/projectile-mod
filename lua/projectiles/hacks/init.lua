AddCSLuaFile();

if SERVER then
    include("realistic_blood.lua");
    include("shellshock.lua");
    include("muzzleflash.lua");
end

if CLIENT then
end

print("loaded projectiles hacks");