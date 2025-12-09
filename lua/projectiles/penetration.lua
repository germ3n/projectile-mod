AddCSLuaFile();

local projectiles = projectiles;
local trace_to_exit = trace_to_exit;
local get_surface_data = util.GetSurfaceData;
local rand = math.Rand;
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
local cv_ricochet_chance = get_convar("pro_ricochet_chance");
local cv_ricochet_spread = get_convar("pro_ricochet_spread");
local cv_ricochet_speed_multiplier = get_convar("pro_ricochet_speed_multiplier");
local cv_ricochet_damage_multiplier = get_convar("pro_ricochet_damage_multiplier");
local cv_ricochet_distance_multiplier = get_convar("pro_ricochet_distance_multiplier");
local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;

local vector_meta = FindMetaTable("Vector");
local dot = vector_meta.Dot;
local get_normalized = vector_meta.GetNormalized;
local len = vector_meta.Length;

local tick_count = engine.TickCount;
local max = math.max;

--todo: use penetration_power
function handle_penetration(shooter, projectile_data, src, dir, constpen, penetration_power, enter_trace)
    if not enter_trace.MatType then 
        return true, nil, nil;
    end

    if get_bool(cv_ricochet_enabled) then
        random_seed(projectile_data.random_seed + projectile_data.penetration_count);

        local hit_normal = enter_trace.HitNormal;
        local dot_result = dot(dir, hit_normal);
    
        if enter_trace.MatType ~= MAT_FLESH and enter_trace.MatType ~= MAT_GLASS and rand(0, 1) < get_float(cv_ricochet_chance) then
            local reflect = dir - (2 * dot_result * hit_normal);
            local spread = vector_rand() * get_float(cv_ricochet_spread);
    
            projectile_data.dir = get_normalized(reflect + spread);
            projectile_data.speed = projectile_data.speed * get_float(cv_ricochet_speed_multiplier);
            projectile_data.damage = projectile_data.damage * get_float(cv_ricochet_damage_multiplier);
            projectile_data.pos = enter_trace.HitPos + (projectile_data.dir * get_float(cv_ricochet_distance_multiplier));
    
            return false, nil, nil;
        end
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
    --local dmg_mod = 0.16;

    if is_grate_surf then
        pen_mod = 3.0;
        --dmg_mod = 0.05;
    elseif enter_mat == MAT_FLESH then 
        pen_mod = 1.0;
        --dmg_mod = 0.16;
    else
        local exit_pen = exit_surf_data and SURFACE_PROPS_PENETRATION[exit_surf_data.name] or 1.0;
        local enter_pen = enter_surf_data and SURFACE_PROPS_PENETRATION[enter_surf_data.name] or 1.0;
        print(enter_pen, exit_pen);
        pen_mod = (enter_pen + exit_pen) * 0.5;
        --dmg_mod = 0.16;
    end

    local dmg_mod = 0.16 / max(0.01, pen_mod);

    local pen_mod_inv = 1.0 / pen_mod;
    if pen_mod_inv < 0.0 then pen_mod_inv = 0.0; end

    local pen_ratio = (3.0 / constpen) * 1.25;
    if pen_ratio < 0.0 then pen_ratio = 0.0; end

    local lost_damage = (pen_mod_inv * 3.0 * pen_ratio) + (dmg_mod * projectile_data.damage);
    
    local dist = len(exit_trace.HitPos - enter_trace.HitPos);
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

--todo: make this configurable
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