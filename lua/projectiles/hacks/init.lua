AddCSLuaFile();

if SERVER then
    include("realistic_blood.lua");
    include("shellshock.lua");
end

print("loaded projectiles hacks");