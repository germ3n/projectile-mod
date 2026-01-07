-- https://steamcommunity.com/sharedfiles/filedetails/?id=2837128795
-- reimplementation of sh_hooks

AddCSLuaFile();

local is_singleplayer = game.SinglePlayer();
local is_valid = IsValid;
local effect = util.Effect;
local effect_data = EffectData;
local CLIENT = CLIENT;
local SERVER = SERVER;

local entity_meta = FindMetaTable("Entity");
local get_owner = entity_meta.GetOwner;

local effect_data_meta = FindMetaTable("CEffectData");
local set_origin = effect_data_meta.SetOrigin;
local set_normal = effect_data_meta.SetNormal;
local set_magnitude = effect_data_meta.SetMagnitude;
local set_radius = effect_data_meta.SetRadius;
local set_entity = effect_data_meta.SetEntity;
local set_flags = effect_data_meta.SetFlags;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

local cv_projectiles_enabled = GetConVar("pro_projectiles_enabled");
local cv_splatter_enabled = nil;
local cv_splatter_predict = nil;

local dyn_splatter_backup = nil;
local splatter_patched = false;

local function should_bullet_impact(ent)
    if is_singleplayer and SERVER then
        return true;
    end

    if CLIENT and not is_singleplayer then
        return true;
    end

    local owner = get_owner(ent);
    local is_firing = ent:IsPlayer() or (ent:IsWeapon() and is_valid(owner) and owner:IsPlayer())
    if SERVER and not is_singleplayer and not is_firing then
        return true;
    end

    return false;
end

function dyn_splatter(shooter, hit_entity, hit_pos, hit_normal, damage)
    if not cv_splatter_enabled or not get_bool(cv_splatter_enabled) or not should_bullet_impact(shooter) then return; end

    local effectdata = effect_data();
    set_origin(effectdata, hit_pos);
    set_normal(effectdata, -hit_normal);
    set_magnitude(effectdata, 1.2);
    set_radius(effectdata, damage);
    set_entity(effectdata, hit_entity);
    set_flags(effectdata, hit_entity:GetBloodColor() + 1);
    effect("dynamic_blood_splatter_effect", effectdata, true, true);
end

local hook_add = hook.Add;
local hook_remove = hook.Remove;
function fx_patch_dyn_splatter(enable)
    if not dyn_splatter_backup then
        return;
    end

    if enable then
        hook_add("EntityFireBullets", "dynsplatter", dyn_splatter_backup);
        splatter_patched = false;
    else
        hook_remove("EntityFireBullets", "dynsplatter");
        splatter_patched = true;
    end
end

timer.Create("projectile_patch_zippy_blood_splatter", 3, 0, function()
    if not dyn_splatter_backup then
        if hook.GetTable()["EntityFireBullets"] then
            dyn_splatter_backup = hook.GetTable()["EntityFireBullets"]["dynsplatter"];
        end

        if not dyn_splatter_backup then
            return;
        end

        cv_splatter_enabled = GetConVar("dynamic_blood_splatter_enable_mod");
        cv_splatter_predict = GetConVar("dynamic_blood_splatter_predict");
    end

    if get_bool(cv_projectiles_enabled) then
        if not splatter_patched then
            hook.Remove("EntityFireBullets", "dynsplatter");
            splatter_patched = true;
            print("patched dynsplatter");
        end
    else
        if splatter_patched then
            hook.Add("EntityFireBullets", "dynsplatter", dyn_splatter_backup);
            splatter_patched = false;
            print("unpatched dynsplatter");
        end
    end
end);

print("loaded enhanced blood splatters hack");