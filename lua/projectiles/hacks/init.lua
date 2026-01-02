AddCSLuaFile();

if SERVER then
    include("realistic_blood.lua");
    include("shellshock.lua");
    include("muzzleflash.lua");
    include("hurt_armorednpcs.lua");
end

if CLIENT then
end

include("enhanced_blood_splatters.lua");

print("loaded projectiles hacks");