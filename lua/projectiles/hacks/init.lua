AddCSLuaFile();

local projectiles = projectiles;

if SERVER then
    include("realistic_blood.lua");
    include("shellshock.lua");
    include("muzzleflash.lua");
    include("hurt_armorednpcs.lua");
end

if CLIENT then
end

include("enhanced_blood_splatters.lua");

local fx_patch_rlb_fire_bullets = fx_patch_rlb_fire_bullets;
local fx_patch_shellshock = fx_patch_shellshock;
local fx_patch_hurt_armorednpcs = fx_patch_hurt_armorednpcs;
local fx_patch_dyn_splatter = fx_patch_dyn_splatter;
function fx_patch_all(enable)
    projectiles.currently_using_firebullets = enable;
    if SERVER then
        fx_patch_rlb_fire_bullets(enable);
        fx_patch_shellshock(enable);
        fx_patch_hurt_armorednpcs(enable);
        fx_patch_dyn_splatter(enable);
    end
end

print("loaded projectiles hacks");