-- anything that uses zippy realistic blood

local projectiles = projectiles;
local fire_bullets_patched = false;
local entity_take_damage_patched = false;
local rlb_fire_bullets = nil;
local rlb_entity_take_damage = nil;
local cv_projectiles_enabled = GetConVar("pro_projectiles_enabled");
local guard_rlb_fire_bullets = false;
local BLOOD_COLOR_RED = BLOOD_COLOR_RED;
local DONT_BLEED = DONT_BLEED;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

local entity_meta = FindMetaTable("Entity");
local get_blood_color = entity_meta.GetBloodColor;
local set_blood_color = entity_meta.SetBloodColor;

local function patched_rlb_entity_take_damage(ent, ...)
    if not ent.rlb_initialized then
        ent.UsesRealisticBlood = true;
        if get_blood_color(ent) == BLOOD_COLOR_RED then ent.AnimatedBlood_RedBlood = true; end
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent.RealLifeBloodRedux_OGBloodColor = get_blood_color(ent);
            set_blood_color(ent, DONT_BLEED);
        end
        if ent.IsVJBaseSNPC then ent.Bleeds = false end
        ent.rlb_initialized = true;
        --print("patched rlb_entity_take_damage for", ent);
    end

    rlb_entity_take_damage(ent, ...);
end

timer.Create("projectile_patch_zippy_realistic_blood", 3, 0, function()
    if not rlb_fire_bullets or not rlb_entity_take_damage then
        local hooks = hook.GetTable();

        rlb_fire_bullets = rlb_fire_bullets or hooks["EntityFireBullets"] and hooks["EntityFireBullets"]["EntityFireBullets_RealisticBlood"];
        rlb_entity_take_damage = rlb_entity_take_damage or hooks["EntityTakeDamage"] and hooks["EntityTakeDamage"]["EntityTakeDamage_RealisticBlood"];

        if not rlb_fire_bullets or not rlb_entity_take_damage then
            return;
        end
    end

    if get_bool(cv_projectiles_enabled) then
        if not fire_bullets_patched then
            hook.Remove("EntityFireBullets", "EntityFireBullets_RealisticBlood");
            fire_bullets_patched = true;
            print("patched rlb_fire_bullets");
        end

        if not entity_take_damage_patched then
            hook.Remove("EntityTakeDamage", "EntityTakeDamage_RealisticBlood");
            hook.Add("EntityTakeDamage", "EntityTakeDamage_RealisticBlood", patched_rlb_entity_take_damage);
            entity_take_damage_patched = true;
            print("patched rlb_entity_take_damage");
        end
    else
        if fire_bullets_patched then
            hook.Add("EntityFireBullets", "EntityFireBullets_RealisticBlood", rlb_fire_bullets);
            fire_bullets_patched = false;
            print("unpatched rlb_fire_bullets");
        end

        if entity_take_damage_patched then
            hook.Add("EntityTakeDamage", "EntityTakeDamage_RealisticBlood", rlb_entity_take_damage);
            entity_take_damage_patched = false;
            print("unpatched rlb_entity_take_damage");
        end
    end
end);