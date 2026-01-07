--https://steamcommunity.com/sharedfiles/filedetails/?id=3061075767

local projectiles = projectiles;

local next = next;
local muzzleflash_moretracers = nil;
local muzzleflash_pistolfix = nil;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

timer.Create("projectiles_hack_muzzleflash", 3, 0, function()
    if not muzzleflash_moretracers and hook.GetTable()["EntityFireBullets"] then
        muzzleflash_moretracers = hook.GetTable()["EntityFireBullets"]["MoreTracersForHL2Weps"];
    end

    if not muzzleflash_pistolfix and hook.GetTable()["EntityFireBullets"] then
        muzzleflash_pistolfix = hook.GetTable()["EntityFireBullets"]["NPCPistolEffectFix"];
    end

    if not muzzleflash_moretracers or not muzzleflash_pistolfix then
        return;
    end

    if not projectiles["pro_projectiles_enabled"] then -- disable hack
        hook.Add("EntityFireBullets", "MoreTracersForHL2Weps", muzzleflash_moretracers);
        hook.Add("EntityFireBullets", "NPCPistolEffectFix", muzzleflash_pistolfix);
    else
        hook.Remove("EntityFireBullets", "MoreTracersForHL2Weps");
        hook.Remove("EntityFireBullets", "NPCPistolEffectFix");
    end
end);

function npc_pistol_effect_fix(shooter, data)
    if muzzleflash_pistolfix then
        muzzleflash_pistolfix(shooter, data);
    end
end

print("loaded muzzleflash hack");