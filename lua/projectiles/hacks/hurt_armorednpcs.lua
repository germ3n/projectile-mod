-- https://steamcommunity.com/sharedfiles/filedetails/?id=3047373358

local projectiles = projectiles;

local bullets_hurt_armorednpcs = nil;
local bullets_hurt_armorednpcs_patched = false;

local D_LI = D_LI;
local is_valid = IsValid;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

function hurt_armorednpcs(shooter, trace, dmginfo)
    if is_valid(trace.Entity) and trace.Entity.CustomBulletHit then
        local friendly = shooter.Disposition and shooter:Disposition(trace.Entity) == D_LI;
        local driver = trace.Entity.Driver;
        local driver_friendly = shooter.Disposition and is_valid(driver) and shooter:Disposition(driver) == D_LI;

        if not friendly and not driver_friendly then
            trace.Entity:CustomBulletHit(trace, dmginfo);

            return true;
        end
    end

    return false;
end

local hook_add = hook.Add;
local hook_remove = hook.Remove;
function fx_patch_hurt_armorednpcs(enable)
    if not bullets_hurt_armorednpcs then
        return;
    end

    if enable then
        hook_add("EntityFireBullets", "BulletsHurtArmoredNPCs", bullets_hurt_armorednpcs);
        bullets_hurt_armorednpcs_patched = false;
    else
        hook_remove("EntityFireBullets", "BulletsHurtArmoredNPCs");
        bullets_hurt_armorednpcs_patched = true;
    end
end

timer.Create("projectiles_hack_hurt_armorednpcs", 3, 0, function()
    if not bullets_hurt_armorednpcs and hook.GetTable()["EntityFireBullets"] then
        bullets_hurt_armorednpcs = hook.GetTable()["EntityFireBullets"]["BulletsHurtArmoredNPCs"];
    end

    if not bullets_hurt_armorednpcs then
        return;
    end

    if not projectiles["pro_projectiles_enabled"] then -- unpatch
        if bullets_hurt_armorednpcs_patched then
            hook.Add("EntityFireBullets", "BulletsHurtArmoredNPCs", bullets_hurt_armorednpcs);
            bullets_hurt_armorednpcs_patched = false;

            print("unpatched bullets_hurt_armorednpcs");
        end
    else
        if not bullets_hurt_armorednpcs_patched then
            hook.Remove("EntityFireBullets", "BulletsHurtArmoredNPCs");
            bullets_hurt_armorednpcs_patched = true;

            print("patched bullets_hurt_armorednpcs");
        end
    end
end);

print("loaded hurt_armorednpcs hack");