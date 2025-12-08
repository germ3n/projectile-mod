AddCSLuaFile();

local projectiles = projectiles;
local trace_to_exit = trace_to_exit;
local get_surface_data = util.GetSurfaceData;
local math_random = math.random;
local vector_rand = VectorRand;
local MAT_GRATE = MAT_GRATE;
local MAT_GLASS = MAT_GLASS;
local MAT_FLESH = MAT_FLESH;
local MAT_WOOD = MAT_WOOD;
local MAT_METAL = MAT_METAL;
local MAT_PLASTIC = MAT_PLASTIC;
local SURFACE_PROPS_PENETRATION = SURFACE_PROPS_PENETRATION;
local random_seed = math.randomseed;
local get_convar = GetConVar;

local cv_ricochet_enabled = get_convar("pro_ricochet_enabled");
local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

function handle_penetration(shooter, projectile_data, src, dir, constpen, enter_trace)
    if not enter_trace.MatType then 
        return true, nil, nil;
    end

    if get_bool(cv_ricochet_enabled) then
        random_seed(tonumber(util.CRC(tostring(src + dir))));
    end

    local hit_normal = enter_trace.HitNormal;
    local dot = dir:Dot(hit_normal);

    if get_bool(cv_ricochet_enabled) and enter_trace.MatType ~= MAT_FLESH and enter_trace.MatType ~= MAT_GLASS and math_random() < 0.25 then -- todo: make this configurable
        local reflect = dir - (2 * dot * hit_normal);
        local spread = vector_rand() * 0.2;

        projectile_data.dir = (reflect + spread):GetNormalized();
        projectile_data.speed = projectile_data.speed * 0.6;
        projectile_data.damage = projectile_data.damage * 0.5;
        projectile_data.pos = enter_trace.HitPos + (projectile_data.dir * 2.0);

        return false, nil, nil;
    end

    if projectile_data.penetration_count <= 0 or projectile_data.penetration_power <= 0.0 then 
        return true, nil, nil;
    end

    local exit_pos, exit_trace = trace_to_exit(enter_trace, src, dir, projectile_data.mins, projectile_data.maxs, shooter);
    if not exit_pos then
        return true, nil, nil;
    end

    local enter_surf_data = get_surface_data(enter_trace.SurfaceProps);
    local exit_surf_data = get_surface_data(exit_trace.SurfaceProps);

    local enter_mat = enter_trace.MatType;
    local exit_mat = exit_trace.MatType;

    local is_grate_surf = (enter_mat == MAT_GRATE) or (enter_mat == MAT_GLASS);
    local pen_mod = 1.0;
    local dmg_mod = 0.16;

    if is_grate_surf then
        pen_mod = 3.0;
        dmg_mod = 0.05;
    elseif enter_mat == MAT_FLESH then 
        pen_mod = 1.0;
        dmg_mod = 0.16;
    else
        local exit_pen = exit_surf_data and SURFACE_PROPS_PENETRATION[exit_surf_data.name] or 1.0;
        local enter_pen = enter_surf_data and SURFACE_PROPS_PENETRATION[enter_surf_data.name] or 1.0;
        pen_mod = (enter_pen + exit_pen) * 0.5;
        dmg_mod = 0.16;
    end
    
    if enter_mat == exit_mat then
        if exit_mat == MAT_WOOD or exit_mat == MAT_METAL then
            pen_mod = 3.0;
        elseif exit_mat == MAT_PLASTIC then
            pen_mod = 2.0;
        end
    end

    local pen_mod_inv = 1.0 / pen_mod;
    if pen_mod_inv < 0.0 then pen_mod_inv = 0.0; end

    local pen_ratio = (3.0 / constpen) * 1.25;
    if pen_ratio < 0.0 then pen_ratio = 0.0; end

    local lost_damage = (pen_mod_inv * 3.0 * pen_ratio) + (dmg_mod * projectile_data.damage);
    
    local dist = (exit_trace.HitPos - enter_trace.HitPos):Length();
    if dist > 90 then 
        return true, nil, nil;
    end

    local final_damage_loss = (((dist * dist) * pen_mod_inv) / 24.0) + lost_damage;
    projectile_data.damage = projectile_data.damage - final_damage_loss;

    if projectile_data.damage < 1.0 then 
        return true, nil, nil;
    end

    projectile_data.penetration_count = projectile_data.penetration_count - 1;
    
    return false, exit_trace.HitPos, exit_trace;
end

local HITGROUP_MULTIPLIERS = {
    [HITGROUP_GENERIC] = 1.0,
    [HITGROUP_HEAD] = 4.0,
    [HITGROUP_CHEST] = 1.25,
    [HITGROUP_STOMACH] = 1.0,
    [HITGROUP_LEFTARM] = 1.0,
    [HITGROUP_RIGHTARM] = 1.0,
    [HITGROUP_LEFTLEG] = 0.75,
    [HITGROUP_RIGHTLEG] = 0.75,
    [HITGROUP_GEAR] = 1.0,
};

function get_damage_multiplier(hitgroup)
    return HITGROUP_MULTIPLIERS[hitgroup] or 1.0;
end

print("loaded projectiles penetration");