-- Real Life Blood REDUX 2025
-- todo: optimize this

local projectiles = projectiles;
local fire_bullets_patched = false;
local entity_take_damage_patched = false;
local rlb_fire_bullets = nil;
local rlb_entity_take_damage = nil;
local cv_projectiles_enabled = GetConVar("pro_projectiles_enabled");
local guard_rlb_fire_bullets = false;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

local entity_meta = FindMetaTable("Entity");
local get_blood_color = entity_meta.GetBloodColor;
local set_blood_color = entity_meta.SetBloodColor;

local function patched_rlb_fire_bullets(...)
    if guard_rlb_fire_bullets then return; end
    guard_rlb_fire_bullets = true;
    rlb_fire_bullets(...);
    guard_rlb_fire_bullets = false;
end

local function patch_rlb_fire_bullets()
    hook.Remove("EntityFireBullets", "EntityFireBullets_RealisticBlood");
    --hook.Add("EntityFireBullets", "EntityFireBullets_RealisticBlood", patched_rlb_fire_bullets);
    fire_bullets_patched = true;
    print("patched rlb_fire_bullets");
end

local function patched_rlb_entity_take_damage(ent, ...)
    if not ent.rlb_initialized then
        ent.UsesRealisticBlood = true;
        if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then
            ent.RealLifeBloodRedux_OGBloodColor = get_blood_color(ent);
            set_blood_color(ent, -1);
        end
        if ent.IsVJBaseSNPC then ent.Bleeds = false end
        ent.rlb_initialized = true;
        --print("patched rlb_entity_take_damage for", ent);
    end

    rlb_entity_take_damage(ent, ...);
end

local function patch_rlb_entity_take_damage()
    hook.Remove("EntityTakeDamage", "EntityTakeDamage_RealisticBlood");
    hook.Add("EntityTakeDamage", "EntityTakeDamage_RealisticBlood", patched_rlb_entity_take_damage);
    entity_take_damage_patched = true;
    print("patched rlb_entity_take_damage");
end

timer.Create("2867635154", 1, 0, function()
    local hooks = hook.GetTable();
    rlb_fire_bullets = hooks["EntityFireBullets"] and hooks["EntityFireBullets"]["EntityFireBullets_RealisticBlood"];
    rlb_entity_take_damage = hooks["EntityTakeDamage"] and hooks["EntityTakeDamage"]["EntityTakeDamage_RealisticBlood"];

    if not fire_bullets_patched and rlb_fire_bullets then
        patch_rlb_fire_bullets();
    end

    if not entity_take_damage_patched and rlb_entity_take_damage then
        patch_rlb_entity_take_damage();
    end

    if fire_bullets_patched and entity_take_damage_patched then
        print("all Realistic Blood hacks patched");
        timer.Remove("2867635154");
    end
end);