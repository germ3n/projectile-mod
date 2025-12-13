AddCSLuaFile();

local projectiles = projectiles;

local zero_vec = Vector(0, 0, 0);
local rand = math.Rand;
local abs = math.abs;

local angle_meta = FindMetaTable("Angle");
local right = angle_meta.Right;
local up = angle_meta.Up;

local vector_meta = FindMetaTable("Vector");
local angle = vector_meta.Angle;

local function calc_spread(weapon, dir, spread, bias)
    if spread == zero_vec then
        return dir;
    end

    bias = bias or 1.0;
    local flatness = abs(bias * 0.5);
    local final_spread_x, final_spread_y;
    local angle_dir = angle(dir);
    local vec_right = right(angle_dir);
    local vec_up = up(angle_dir);

    repeat
        final_spread_x = rand(-1, 1) * flatness + rand(-1, 1) * (1.0 - flatness);
        final_spread_y = rand(-1, 1) * flatness + rand(-1, 1) * (1.0 - flatness);
        if bias < 0.0 then
            final_spread_x = final_spread_x >= 0.0 and 1.0 - final_spread_x or -1.0 -final_spread_x;
            final_spread_y = final_spread_y >= 0.0 and 1.0 - final_spread_y or -1.0 -final_spread_y;
        end
    until (final_spread_x * final_spread_x + final_spread_y * final_spread_y) <= 1.0;

    local final_dir = dir + (final_spread_x * spread.x * vec_right) + (final_spread_y * spread.y * vec_up);
    return final_dir;
end

local SPREAD_VALUES = {
    ["default"] = calc_spread,
    ["weapon_shotgun"] = function(weapon, dir, spread, bias)
        return calc_spread(weapon, dir, spread, -1.0);
    end,
};

local function get_weapon_spread(weapon, class_name, dir, spread, bias)
    local spread_func = SPREAD_VALUES[class_name];
    if spread_func then return spread_func(weapon, dir, spread, bias); end

    return SPREAD_VALUES["default"](weapon, dir, spread, bias);
end

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;

local cv_projectiles_enabled = GetConVar("pro_projectiles_enabled");
local cv_penetration_power_scale = GetConVar("pro_penetration_power_scale");
local cv_weapon_damage_scale = GetConVar("pro_weapon_damage_scale");
local cv_speed_scale = GetConVar("pro_speed_scale");

if SERVER then
    local broadcast_projectile = broadcast_projectile;
    local calculate_lean_pos = calculate_lean_pos;
    local get_weapon_speed = get_weapon_speed;
    local get_weapon_damage = get_weapon_damage;
    local get_weapon_spread = get_weapon_spread;
    local get_weapon_penetration_power = get_weapon_penetration_power;
    local get_weapon_penetration_count = get_weapon_penetration_count;
    local get_weapon_drag = get_weapon_drag;
    local get_weapon_mass = get_weapon_mass;
    local get_weapon_drop = get_weapon_drop;
    local get_weapon_min_speed = get_weapon_min_speed;
    local get_weapon_max_distance = get_weapon_max_distance;
    
    local player_meta = FindMetaTable("Player");
    local get_lean_amount = player_meta.GetLeanAmount;
    local player_get_active_weapon = player_meta.GetActiveWeapon;
    local is_player = player_meta.IsPlayer;

    local vector_meta = FindMetaTable("Vector");
    local angle = vector_meta.Angle;

    local NULL = NULL;
    local entity_meta = FindMetaTable("Entity");
    local get_class = entity_meta.GetClass;

    local npc_meta = FindMetaTable("NPC");
    local is_npc = npc_meta.IsNPC;
    local npc_get_active_weapon = npc_meta.GetActiveWeapon;

    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if projectiles.disable_fire_bullets or not get_bool(cv_projectiles_enabled) then return; end
        if not shooter or shooter == NULL then return; end
        --print(shooter, data.Inflictor, data.Damage);

        local inflictor;
        local lean_amount = get_lean_amount and shooter:IsPlayer() and get_lean_amount(shooter) or 0.0;
        if (not data.Inflictor or data.Inflictor == NULL) and shooter ~= NULL then
            if shooter:IsPlayer() then--if is_player(shooter) then
                inflictor = player_get_active_weapon(shooter);
            elseif shooter:IsNPC() then--elseif is_npc(shooter) then
                inflictor = npc_get_active_weapon(shooter);
            end
        else
            inflictor = data.Inflictor;
        end

        if not inflictor or inflictor == NULL then
            return;
        end

        local inflictor_class = get_class(inflictor);
        local speed = get_weapon_speed(inflictor, inflictor_class) * get_float(cv_speed_scale);
        local damage = get_weapon_damage(inflictor, inflictor_class, data.Damage) * get_float(cv_weapon_damage_scale);
        local src = calculate_lean_pos and calculate_lean_pos(data.Src, angle(data.Dir), lean_amount, shooter) or data.Src;
        local penetration_power = get_weapon_penetration_power(inflictor, inflictor_class) * get_float(cv_penetration_power_scale);
        local penetration_count = get_weapon_penetration_count(inflictor, inflictor_class);
        local drag = get_weapon_drag(inflictor, inflictor_class);
        local mass = get_weapon_mass(inflictor, inflictor_class);
        local drop = get_weapon_drop(inflictor, inflictor_class);
        local min_speed = get_weapon_min_speed(inflictor, inflictor_class);
        local max_distance = get_weapon_max_distance(inflictor, inflictor_class);
        for idx = 1, data.Num do
            local spread_dir = get_weapon_spread(inflictor, inflictor_class, data.Dir, data.Spread);
            broadcast_projectile(
                shooter,
                inflictor,
                src,
                spread_dir, 
                speed,
                damage,
                drag,
                penetration_power,
                penetration_count,
                2.5, -- constpen
                mass,
                drop,
                min_speed,
                max_distance
            );
        end

        return false;
    end);
end

if CLIENT then
    hook.Add("EntityFireBullets", "projectiles", function(shooter, data)
        if not get_bool(cv_projectiles_enabled) then return; end
        return false;
    end);
end

print("loaded projectiles firebullets");