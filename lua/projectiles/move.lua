AddCSLuaFile();

local CLIENT = CLIENT;
local SERVER = SERVER;
local next = next;
local tick_interval = engine.TickInterval();
local projectiles = projectiles;
local projectile_store = projectile_store;
local handle_penetration = handle_penetration;
local projectile_move_trace = projectile_move_trace;
local get_damage_multiplier = get_damage_multiplier;
local band = bit.band;
local bxor = bit.bxor;
local rshift = bit.rshift;
local point_contents = util.PointContents;
local trace_line_ex = util.TraceLine;
local get_surface_data = util.GetSurfaceData;
local string_format = string.format;
local CONTENTS_WATER = CONTENTS_WATER;
local CONTENTS_SLIME = CONTENTS_SLIME;
local CONTENTS_WATER_AND_SLIME = bit.bor(CONTENTS_WATER, CONTENTS_SLIME);
local MASK_WATER = MASK_WATER;
local DMG_BULLET = DMG_BULLET;
local DONT_BLEED = DONT_BLEED;
local effect_data = EffectData;
local effect = util.Effect;
local vector = Vector;
local damage_info = DamageInfo;
local color = Color;
local get_convar = GetConVar;
local debug_overlay = debugoverlay;
local debug_line = debug_overlay.Line;
local debug_box = debug_overlay.Box;
local debug_text = debug_overlay.Text;
local string_split = string.Split;
local tonumber = tonumber;
local tostring = tostring;
local NULL = NULL;
local engine_tick_count = engine.TickCount;
local sqrt = math.sqrt;
local _is_valid = IsValid;
local clamp = math.Clamp;
local util_decal = util.Decal;

local entity_meta = FindMetaTable("Entity");
local is_valid = entity_meta.IsValid;
local take_damage_info = entity_meta.TakeDamageInfo;
local dispatch_trace_attack = entity_meta.DispatchTraceAttack;
local fire_bullets = entity_meta.FireBullets;
local get_class = entity_meta.GetClass;
local get_physics_object = entity_meta.GetPhysicsObject;

local player_meta = FindMetaTable("Player");
local toggle_lag_compensation = player_meta.LagCompensation;
local is_listen_server_host = player_meta.IsListenServerHost;

local entity_meta = FindMetaTable("Entity");
local get_blood_color = entity_meta.GetBloodColor;

local physobj_meta = FindMetaTable("PhysObj");
local is_motion_enabled = physobj_meta.IsMotionEnabled;

local damage_info_meta = FindMetaTable("CTakeDamageInfo");
local set_damage = damage_info_meta.SetDamage;
local set_attacker = damage_info_meta.SetAttacker;
local dmg_set_damage_type = damage_info_meta.SetDamageType;
local set_damage_position = damage_info_meta.SetDamagePosition;
local set_damage_force = damage_info_meta.SetDamageForce;
local set_inflictor = damage_info_meta.SetInflictor;
local set_weapon = damage_info_meta.SetWeapon;

local effect_data_meta = FindMetaTable("CEffectData");
local set_origin = effect_data_meta.SetOrigin;
local set_scale = effect_data_meta.SetScale;
local set_flags = effect_data_meta.SetFlags;
local set_start = effect_data_meta.SetStart;
local set_surface_prop = effect_data_meta.SetSurfaceProp;
local set_entity = effect_data_meta.SetEntity;
local set_hit_box = effect_data_meta.SetHitBox;
local set_damage_type = effect_data_meta.SetDamageType;
local set_normal = effect_data_meta.SetNormal;

local cusercmd_meta = FindMetaTable("CUserCmd");
local get_command_number = cusercmd_meta.CommandNumber;
local tick_count = cusercmd_meta.TickCount;

local vector_meta = FindMetaTable("Vector");
local get_normalized = vector_meta.GetNormalized;
local vec_len = vector_meta.Length;
local vec_mul = vector_meta.Mul;
local vec_add = vector_meta.Add;
local to_screen = vector_meta.ToScreen;

local BREAKABLE_CLASSES = {
    ["func_breakable_surf"] = true,
    ["func_breakable"] = true,
    ["prop_physics"] = true,
    ["prop_physics_multiplayer"] = true,
};

local BLOOD_COLOR_DECALS = {
    [BLOOD_COLOR_RED] = "Blood",
    [BLOOD_COLOR_YELLOW] = "YellowBlood",
    [BLOOD_COLOR_GREEN] = "YellowBlood",
    [BLOOD_COLOR_MECH] = "BeerSplash",
    [BLOOD_COLOR_ANTLION] = "YellowBlood",
    [BLOOD_COLOR_ZOMBIE] = "Blood",
    [BLOOD_COLOR_ANTLION_WORKER] = "YellowBlood",
};

local PROP_PHYSICS_CLASSES = {
    ["prop_physics"] = true,
    ["prop_physics_multiplayer"] = true,
};

local function should_filter_entity(ent)
    if not _is_valid(ent) then return false; end
    if not PROP_PHYSICS_CLASSES[get_class(ent)] then return true; end
    
    local phys = get_physics_object(ent);
    if not _is_valid(phys) then return true; end
    if not is_motion_enabled(phys) then return false; end
    
    return true;
end

local cv_sv_gravity = get_convar("sv_gravity");

local convar_meta = FindMetaTable("ConVar");
local get_float = convar_meta.GetFloat;

local max = math.max;
local dyn_splatter = dyn_splatter;
local hurt_armorednpcs = hurt_armorednpcs;
local fx_patch_all = fx_patch_all;

local trace_filter = {nil, nil, nil};

local function do_water_trace(projectile_data, new_pos, filter)
    local was_in_water = band(point_contents(projectile_data.pos), CONTENTS_WATER_AND_SLIME) ~= 0;
    local is_in_water = band(point_contents(new_pos), CONTENTS_WATER_AND_SLIME) ~= 0;

    if not was_in_water and is_in_water then
        local water_trace = trace_line_ex({
            start = projectile_data.pos,
            endpos = new_pos,
            mask = MASK_WATER,
            filter = filter
        });

        if water_trace.Hit then
            local effectdata = effect_data();
            set_origin(effectdata, water_trace.HitPos);
            set_scale(effectdata, projectile_data.damage * 0.1);
            set_flags(effectdata, 0);
            effect("gunshotsplash", effectdata);
        end
    end
end

local gravity_vector = vector(0, 0, 0);
local wind_vector = vector(0, 0, 0);
local wind_target_vector = vector(0, 0, 0);

local fire_bullets_config = {
    Attacker = nil,
    Damage = 0,
    Force = 0,
    Distance = 0,
    Dir = vector(0, 0, 0),
    Src = vector(0, 0, 0),
    Tracer = 0,
};

local function debug_projectile_course(projectile_data, enter_trace)
    local dur = projectiles["pro_debug_duration"];
    local col_vec = string_split(projectiles["pro_debug_color"], " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_line(projectile_data.pos, enter_trace.HitPos, dur, col, true);
    
    if enter_trace.Hit then
        debug_box(enter_trace.HitPos, vector(-2, -2, -2), vector(2, 2, 2), dur, col, true);
    end
end

local function debug_penetration(projectile_data, current_hit_damage, current_penetration_power, exit_pos, enter_trace, exit_trace)
    local dur = projectiles["pro_debug_duration"];
    debug_line(enter_trace.HitPos, exit_pos, dur, color(255, 0, 0, 150), true);
    debug_box(exit_pos, vector(-1, -1, -1), vector(1, 1, 1), dur, color(255, 0, 0, 150), true);

    local dmg_lost = current_hit_damage - projectile_data.damage;
    local enter_map_props = enter_trace and enter_trace.SurfaceProps and get_surface_data(enter_trace.SurfaceProps);
    local exit_map_props = exit_trace and exit_trace.SurfaceProps and get_surface_data(exit_trace.SurfaceProps);
    local enter_mat = enter_map_props and enter_map_props.name or "unknown";
    local exit_mat = exit_map_props and exit_map_props.name or "unknown";
    
    debug_text(exit_pos + vector(0, 0, 10), string_format("dmg_lost: %.1f", dmg_lost), dur, false);
    debug_text(exit_pos + vector(0, 0, 20), string_format("dmg_remaining: %.1f", current_hit_damage - dmg_lost), dur, false);
    debug_text(exit_pos + vector(0, 0, 30), string_format("old_penetration_power: %.1f", current_penetration_power), dur, false);
    debug_text(exit_pos + vector(0, 0, 40), string_format("new_penetration_power: %.1f", projectile_data.penetration_power), dur, false);
    debug_text(exit_pos + vector(0, 0, 50), string_format("mat_in: %s", enter_mat), dur, false);
    debug_text(exit_pos + vector(0, 0, 60), string_format("mat_out: %s", exit_mat), dur, false);
end

local do_shellshock = do_shellshock;

local function calculate_damage_dropoff(projectile_data)
    if not projectiles["pro_damage_dropoff_enabled"] then
        return false;
    end

    if projectile_data.distance_traveled < projectile_data.dropoff_start then
        return false;
    end
    
    local multiplier;
    if projectile_data.distance_traveled >= projectile_data.dropoff_end then
        multiplier = projectile_data.dropoff_min_multiplier;
    else
        local range = projectile_data.dropoff_end - projectile_data.dropoff_start;
        local progress = (projectile_data.distance_traveled - projectile_data.dropoff_start) / range;
        progress = clamp(progress, 0.0, 1.0);
        multiplier = 1.0 - (progress * (1.0 - projectile_data.dropoff_min_multiplier));
    end
    
    local target_damage = projectile_data.damage_initial * multiplier;
    
    if target_damage < projectile_data.damage then
        projectile_data.damage = target_damage;
    end

    return projectile_data.damage < 1.0;
end

local function apply_drag(projectile_data)
    if projectiles["pro_drag_enabled"] then
        local drag_factor = projectile_data.drag * tick_interval * projectiles["pro_drag_multiplier"];
        if band(point_contents(projectile_data.pos), CONTENTS_WATER_AND_SLIME) ~= 0 then
            drag_factor = drag_factor * projectiles["pro_drag_water_multiplier"];
        end

        projectile_data.speed = projectile_data.speed - projectile_data.speed * drag_factor;
    end

    if projectile_data.vel then
        projectile_data.old_vel.x = projectile_data.vel.x;
        projectile_data.old_vel.y = projectile_data.vel.y;
        projectile_data.old_vel.z = projectile_data.vel.z;
    end
end

local function apply_damage_info(projectile_data, enter_trace, final_damage, shooter, hit_entity)
    local dmg_info = damage_info();
    set_damage(dmg_info, final_damage);
    if _is_valid(projectile_data.weapon) then 
        set_inflictor(dmg_info, projectile_data.weapon); 
        set_weapon(dmg_info, projectile_data.weapon);
    end
    set_attacker(dmg_info, shooter);
    dmg_set_damage_type(dmg_info, DMG_BULLET);
    set_damage_position(dmg_info, enter_trace.HitPos);
    set_damage_force(dmg_info, projectile_data.dir * final_damage * projectiles["pro_damage_force_multiplier"]);

    if not hurt_armorednpcs(shooter, enter_trace, dmg_info) then
        --dispatch_trace_attack(hit_entity, dmg_info, enter_trace, projectile_data.dir);
        take_damage_info(hit_entity, dmg_info);
    end
end

local function move_projectile(shooter, projectile_data)
    if projectile_data.hit or projectile_data.penetration_count <= 0 or projectile_data.damage < 1.0 or projectile_data.distance_traveled >= projectile_data.max_distance then 
        return true;
    end

    if calculate_damage_dropoff(projectile_data) then
        projectile_data.hit = true;
        return true;
    end

    apply_drag(projectile_data);

    if projectile_data.speed <= projectile_data.min_speed then
        projectile_data.hit = true;
        return true;
    end

    local current_velocity = projectile_data.dir * projectile_data.speed;
    if projectiles["pro_gravity_enabled"] then
        local gravity_strength = get_float(cv_sv_gravity) * projectile_data.drop * projectiles["pro_gravity_multiplier"];
        gravity_vector.z = -gravity_strength;
        if band(point_contents(projectile_data.pos), CONTENTS_WATER_AND_SLIME) ~= 0 then
            gravity_vector.z = gravity_vector.z * projectiles["pro_gravity_water_multiplier"];
        end

        current_velocity.z = current_velocity.z + gravity_vector.z * tick_interval;
    end

    if projectiles["pro_wind_enabled"] then
        current_velocity.x = current_velocity.x + wind_vector.x * tick_interval;
        current_velocity.y = current_velocity.y + wind_vector.y * tick_interval;
    end

    if projectiles["pro_gravity_enabled"] or projectiles["pro_wind_enabled"] then
        projectile_data.dir = get_normalized(current_velocity);
        projectile_data.speed = vec_len(current_velocity);
    end
    
    if projectile_data.vel then
        projectile_data.vel.x = current_velocity.x;
        projectile_data.vel.y = current_velocity.y;
        projectile_data.vel.z = current_velocity.z;
    end
    
    vec_mul(current_velocity, tick_interval);
    local current_pos = projectile_data.pos;
    local new_pos = projectile_data.pos + current_velocity;
    
    trace_filter[1] = not projectile_data.is_gmod_turret and shooter or projectile_data.weapon;
    trace_filter[2] = projectile_data.weapon;
    if projectile_data.last_hit_entity and should_filter_entity(projectile_data.last_hit_entity) then
        trace_filter[3] = projectile_data.last_hit_entity;
    else
        trace_filter[3] = nil;
    end
    if CLIENT then do_water_trace(projectile_data, new_pos, trace_filter); end -- had to move to seperate funcs cuz i hit more than 60 upvalues
    
    local enter_trace = projectile_move_trace(projectile_data.pos, new_pos, trace_filter);

    if projectiles["pro_debug_projectiles"] then debug_projectile_course(projectile_data, enter_trace); end

    local use_firebullets = projectiles["pro_use_firebullets"];
    if enter_trace.Hit then
        local hit_entity = enter_trace.Entity;
        if CLIENT then
            if not use_firebullets then
                local effect_data = effect_data();
                set_origin(effect_data, enter_trace.HitPos);
                set_start(effect_data, enter_trace.StartPos);
                set_surface_prop(effect_data, enter_trace.SurfaceProps);
                set_entity(effect_data, enter_trace.Entity);
                set_hit_box(effect_data, enter_trace.HitBoxBone or 0);
                set_damage_type(effect_data, DMG_BULLET);
                effect("Impact", effect_data);
            end
        end

        local current_hit_damage = projectile_data.damage;
        local current_penetration_power = projectile_data.penetration_power;

        local stop_bullet, exit_pos, exit_trace = handle_penetration(shooter, projectile_data, enter_trace.HitPos, projectile_data.dir, projectile_data.penetration_power, enter_trace);

        -- todo: fix
        if projectiles["pro_debug_penetration"] and exit_pos then
            debug_penetration(projectile_data, current_hit_damage, current_penetration_power, exit_pos, enter_trace, exit_trace);
        end

        if CLIENT and exit_trace and exit_trace.Hit then
            --if not use_firebullets then
                local effect_data = effect_data();
                set_origin(effect_data, exit_trace.HitPos);
                set_start(effect_data, exit_trace.StartPos);
                set_surface_prop(effect_data, exit_trace.SurfaceProps);
                set_entity(effect_data, exit_trace.Entity);
                set_hit_box(effect_data, exit_trace.HitBoxBone or 0);
                set_damage_type(effect_data, DMG_BULLET);
                effect("Impact", effect_data);
            --end
        end

        local final_damage = current_hit_damage * get_damage_multiplier(enter_trace.HitGroup);

        if hit_entity and hit_entity ~= NULL then
            if not use_firebullets then
                if SERVER then
                    if BREAKABLE_CLASSES[get_class(hit_entity)] then
                        projectiles.disable_fire_bullets = true;
                        fire_bullets_config.Attacker = shooter;
                        fire_bullets_config.Inflictor = projectile_data.weapon;
                        fire_bullets_config.Damage = final_damage;
                        fire_bullets_config.Force = final_damage * projectiles["pro_damage_force_multiplier"];
                        fire_bullets_config.Distance = 2;
                        fire_bullets_config.Dir = projectile_data.dir;
                        fire_bullets_config.Src = enter_trace.HitPos - projectile_data.dir;
                        fire_bullets_config.Tracer = 0;
                        fire_bullets_config.AmmoType = projectile_data.ammo_type;
                        fire_bullets(shooter, fire_bullets_config);
                        projectiles.disable_fire_bullets = false;
                    else
                        apply_damage_info(projectile_data, enter_trace, final_damage, shooter, hit_entity);
                    end
                end

                if not dyn_splatter(shooter, hit_entity, enter_trace.HitPos, enter_trace.HitNormal, final_damage) then
                    if CLIENT and projectiles["pro_blood_splatter_enabled"] and hit_entity and _is_valid(hit_entity) then
                        local blood_color = get_blood_color(hit_entity);
                        if blood_color and blood_color ~= DONT_BLEED then
                            local blood_effect = effect_data();
                            set_origin(blood_effect, enter_trace.HitPos);
                            set_normal(blood_effect, enter_trace.HitNormal);
                            set_flags(blood_effect, blood_color);
                            --set_scale(blood_effect, clamp(final_damage * projectiles["pro_blood_splatter_scale"], 1, 10));
                            effect("BloodImpact", blood_effect);
                            
                            --local decal_name = BLOOD_COLOR_DECALS[blood_color] or "Blood";
                            --util_decal(decal_name, enter_trace.HitPos + enter_trace.HitNormal, enter_trace.HitPos - enter_trace.HitNormal);
                        end
                    end
                end
            else
                projectiles.disable_fire_bullets = true;
                fx_patch_all(true);
                fire_bullets_config.Attacker = shooter;
                fire_bullets_config.Inflictor = projectile_data.weapon;
                fire_bullets_config.Damage = final_damage;
                fire_bullets_config.Force = final_damage * projectiles["pro_damage_force_multiplier"];
                fire_bullets_config.Distance = 2;
                fire_bullets_config.Dir = projectile_data.dir;
                fire_bullets_config.Src = enter_trace.HitPos - projectile_data.dir;
                fire_bullets_config.Tracer = 0;
                fire_bullets_config.AmmoType = projectile_data.ammo_type;
                fire_bullets(shooter, fire_bullets_config);
                fx_patch_all(false);
                projectiles.disable_fire_bullets = false;
            end
        end
        
        if stop_bullet then
            projectile_data.hit = true;
            projectile_data.pos = enter_trace.HitPos;

            if SERVER then
                do_shellshock(shooter, current_pos, enter_trace.HitPos, projectile_data.damage);
            end

            return true; 
        else
            if hit_entity and is_valid(hit_entity) then
                projectile_data.last_hit_entity = hit_entity;
            end

            if exit_pos then
                projectile_data.pos = exit_pos;
                projectile_data.distance_traveled = projectile_data.distance_traveled + vec_len(exit_pos - projectile_data.pos);
            end
        end

    else
        projectile_data.pos = new_pos;
        projectile_data.distance_traveled = projectile_data.distance_traveled + vec_len(current_velocity);
    end

    if SERVER then
        do_shellshock(shooter, current_pos, projectile_data.pos, projectile_data.damage);
    end

    projectile_data.old_pos = current_pos;

    return false;
end

local function debug_final_pos(projectile_data)
    local dur = projectiles["pro_debug_duration"];
    local col_vec = string_split(projectiles["pro_debug_color"], " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_box(projectile_data.pos, vector(-1, -1, -1), vector(1, 1, 1), dur, col, true);
end

local cur_time = CurTime;
local sin = math.sin;
local cos = math.cos;
local rad = math.rad;
local lerp_vector = LerpVector;
local floor = math.floor;
local rand = math.Rand;

local gust_end_tick = 0;
local next_wind_update_tick = 0;
local wind_angle = 0;
local wind_start_tick = 0;
local wind_end_tick = 0;
local wind_start_vector = vector(0, 0, 0);
local wind_seed = 0;
local wind_update_counter = 0;
local pending_gust = false;
local pending_gust_angle = 0;
local pending_gust_strength = 0;
local pending_gust_duration = 0;

local clamp = math.Clamp;
local lerp = Lerp;
local min = math.min;
local abs = math.abs;
local fmod = math.fmod;

local function hash_tick(tick, channel)
    local h = tick * 2654435761 + channel * 2246822519;
    h = band(h, 0xFFFFFFFF);
    h = bxor(h, rshift(h, 13));
    h = h * 3266489917;
    h = band(h, 0xFFFFFFFF);
    h = bxor(h, rshift(h, 16));
    return abs(h) / 4294967296.0;
end

local function tick_rand(tick, channel, min_val, max_val)
    local t = hash_tick(tick, channel);
    return min_val + t * (max_val - min_val);
end

local string_byte = string.byte;
local function hash_string(str)
    local h = 2166136261;
    for i = 1, #str do
        h = bxor(h, string.byte(str, i));
        h = h * 16777619;
        h = band(h, 0xFFFFFFFF);
    end
    return h;
end

local map_hash = hash_string(game.GetMap());
if SERVER then
    PROJECTILES_CVARS["pro_wind_seed_random"][1]:SetInt(math.random(1, 2147483647));
end

local function get_wind_seed()
    local random_seed = PROJECTILES_CVARS["pro_wind_seed_random"][1]:GetInt();--projectiles["pro_wind_seed_random"];
    return bxor(map_hash, random_seed);
end

local wind_seed = get_wind_seed();

local function get_turbulence(val, offset)
    local n = 0;
    n = n + sin(val * 1.0 + offset) * 1.0;
    n = n + sin(val * 2.1 + offset * 1.3) * 0.5;
    n = n + sin(val * 4.3 + offset * 1.7) * 0.25;
    n = n + sin(val * 8.7 + offset * 2.1) * 0.125;
    n = n + sin(val * 17.3 + offset * 2.7) * 0.0625;
    n = n + sin(val * 34.9 + offset * 3.1) * 0.03125;
    return n / 1.96875;
end

local function get_wind_at_tick(tick)
    local progress = (tick - wind_start_tick) / (wind_end_tick - wind_start_tick + (wind_start_tick == wind_end_tick and 1 or 0));
    progress = clamp(progress, 0, 1);

    local curve = min(progress * 3.5, 1);
    curve = curve * curve * (3 - 2 * curve);

    local wind_x = lerp(curve, wind_start_vector.x, wind_target_vector.x);
    local wind_y = lerp(curve, wind_start_vector.y, wind_target_vector.y);

    local jitter_amt = projectiles["pro_wind_jitter_amount"];
    local jitter_x = get_turbulence(progress * 10.0, 0);
    local jitter_y = get_turbulence(progress * 10.0, 50);
    local wind_speed = sqrt(wind_x * wind_x + wind_y * wind_y);

    wind_x = wind_x + (wind_speed * jitter_x * jitter_amt);
    wind_y = wind_y + (wind_speed * jitter_y * jitter_amt);

    return vector(wind_x, wind_y, 0.0);
end

local function update_wind_target(is_wind_update, has_gust_finished)
    local base_strength = projectiles["pro_wind_strength"];
    local duration_ticks = 0;
    local update_seed = bxor(wind_seed, wind_update_counter);
    local angle = has_gust_finished and wind_angle or rad(tick_rand(update_seed, 4, 0, 360));
    local strength = 0;

    if has_gust_finished then
        gust_end_tick = 0;
        strength = base_strength;

        --print("gust finished");
    elseif pending_gust then
        angle = pending_gust_angle;
        strength = base_strength * pending_gust_strength;
        gust_end_tick = next_wind_update_tick + floor(pending_gust_duration / tick_interval);
        pending_gust = false;
        --print("gust started");
    elseif is_wind_update then
        wind_update_counter = wind_update_counter + 1;
        strength = base_strength * tick_rand(update_seed, 5, projectiles["pro_wind_strength_min_variance"], projectiles["pro_wind_strength_max_variance"]);
        duration_ticks = floor(tick_rand(update_seed, 6, projectiles["pro_wind_min_update_interval"], projectiles["pro_wind_max_update_interval"]) / tick_interval);

        if tick_rand(update_seed, 7, 0, 1) < projectiles["pro_wind_gust_chance"] then
            pending_gust = true;
            pending_gust_angle = angle;
            pending_gust_strength = tick_rand(update_seed, 8, projectiles["pro_wind_gust_min_strength"], projectiles["pro_wind_gust_max_strength"]);
            pending_gust_duration = tick_rand(update_seed, 9, projectiles["pro_wind_gust_min_duration"], projectiles["pro_wind_gust_max_duration"]);
            --print("gust scheduled");
        end
    end

    local prev_update_tick = next_wind_update_tick;
    next_wind_update_tick = next_wind_update_tick + duration_ticks;

    local start_wind = get_wind_at_tick(prev_update_tick);
    
    wind_start_vector.x = start_wind.x;
    wind_start_vector.y = start_wind.y;
    
    wind_target_vector.x = sin(angle) * strength;
    wind_target_vector.y = cos(angle) * strength;

    wind_start_tick = prev_update_tick;
    wind_end_tick = next_wind_update_tick;

    wind_angle = angle;
end

local wind_initialized = false;
local function initialize_wind()
    if wind_initialized then return; end
    wind_initialized = true;
    
    local base_strength = projectiles["pro_wind_strength"];
    local angle = rad(tick_rand(wind_seed, 1, 0, 360));
    local strength = base_strength * tick_rand(wind_seed, 2, projectiles["pro_wind_strength_min_variance"], projectiles["pro_wind_strength_max_variance"]);
    local init_offset_ticks = floor(tick_rand(wind_seed, 3, projectiles["pro_wind_min_update_interval"], projectiles["pro_wind_max_update_interval"]) / tick_interval);
    
    wind_angle = angle;
    wind_target_vector.x = sin(angle) * strength;
    wind_target_vector.y = cos(angle) * strength;
    wind_start_vector.x = wind_target_vector.x;
    wind_start_vector.y = wind_target_vector.y;
    next_wind_update_tick = init_offset_ticks;
    wind_update_counter = 0;
    
    wind_start_tick = 0;
    wind_end_tick = 0;
    
    --print("wind system initialized (map: " .. game.GetMap() .. ", seed: " .. wind_seed .. ")");
end

local function move_projectiles(ply, mv, cmd)
    local projectiles = projectile_store[ply];
    if not projectiles then return; end

    local active_projectile_count = #projectiles.active_projectiles;
    if active_projectile_count == 0 then return; end

    if SERVER and ply:IsPlayer() then 
        if projectiles["pro_wind_enabled"] and cmd then
            if not wind_initialized then
                initialize_wind();
            end
            
            local cmd_tick = tick_count(cmd);
            while cmd_tick >= next_wind_update_tick do
                local gust = gust_end_tick > 0 and next_wind_update_tick >= gust_end_tick;
                update_wind_target(true, gust);
            end
            
            wind_vector = get_wind_at_tick(cmd_tick);
        end
        
        toggle_lag_compensation(ply, true); 
    end
    
    local idx = 1;
    while idx <= active_projectile_count do
        local hit = move_projectile(ply, projectiles.active_projectiles[idx]);
        if hit then
            if projectiles["pro_debug_projectiles"] then debug_final_pos(projectiles.active_projectiles[idx]); end
            projectiles.active_projectiles[idx] = projectiles.active_projectiles[active_projectile_count];
            projectiles.active_projectiles[active_projectile_count] = nil;
            active_projectile_count = active_projectile_count - 1;
        else
            idx = idx + 1;
        end
    end

    if SERVER and ply:IsPlayer() then toggle_lag_compensation(ply, false); end
end

if SERVER then
    local entity_meta = FindMetaTable("Entity");
    local get_velocity = entity_meta.GetVelocity;

    hook.Add("SetupMove", "projectiles_tick", function(ply, mv, cmd)
        projectiles.shooter_velocities[ply] = get_velocity(ply);

        move_projectiles(ply, mv, cmd);
    end);
    
    hook.Add("Tick", "projectiles_tick", function()
        if projectiles["pro_wind_enabled"] then
            if not wind_initialized then
                initialize_wind();
            end
            
            local tick_count = engine_tick_count();
            while tick_count >= next_wind_update_tick do
                local gust = gust_end_tick > 0 and next_wind_update_tick >= gust_end_tick;
                update_wind_target(true, gust);
            end
    
            wind_vector = get_wind_at_tick(tick_count);
        end
        
        for shooter, _ in next, projectile_store do
            if is_valid(shooter) and shooter:IsNPC() then 
                move_projectiles(shooter, nil, nil);
            end
        end
        
        if not projectiles["pro_wind_enabled"] then
            if wind_target_vector.x ~= 0.0 or wind_target_vector.y ~= 0.0 then
                wind_target_vector.x = 0.0;
                wind_target_vector.y = 0.0;
                wind_start_vector.x = 0.0;
                wind_start_vector.y = 0.0;
                wind_initialized = false;
                wind_seed = 0;
                wind_update_counter = 0;
                gust_end_tick = 0;
                pending_gust = false;
            end
        end
    end);

    hook.Add("EntityRemoved", "projectiles_cleanup", function(ent)
        projectile_store[ent] = nil;
        projectiles.shooter_velocities[ent] = nil;
    end);
else
    local is_first_time_predicted = IsFirstTimePredicted;
    local local_player = LocalPlayer;
    local is_singleplayer = game.SinglePlayer();
    local last_tick_count = engine_tick_count();

    local entity_meta = FindMetaTable("Entity");
    local get_velocity = entity_meta.GetVelocity;
    hook.Add("CreateMove", "projectiles_tick", function(cmd)
        local ply = local_player();
        if _is_valid(ply) then
            projectiles.shooter_velocities[ply] = get_velocity(ply);
        end

        local tick = tick_count(cmd);
        if get_command_number(cmd) ~= 0 and ((tick > last_tick_count) or is_singleplayer) then
            if projectiles["pro_wind_enabled"] then
                if not wind_initialized then
                    initialize_wind();
                end
                
                while tick >= next_wind_update_tick do
                    local gust = gust_end_tick > 0 and next_wind_update_tick >= gust_end_tick;
                    update_wind_target(true, gust);
                end
        
                wind_vector = get_wind_at_tick(tick);
            else
                if wind_target_vector.x ~= 0.0 or wind_target_vector.y ~= 0.0 then
                    wind_target_vector.x = 0.0;
                    wind_target_vector.y = 0.0;
                    wind_start_vector.x = 0.0;
                    wind_start_vector.y = 0.0;
                    wind_initialized = false;
                    wind_seed = 0;
                    wind_update_counter = 0;
                    gust_end_tick = 0;
                    pending_gust = false;
                end
            end

            for shooter, _ in next, projectile_store do
                if not is_valid(shooter) then continue; end
                move_projectiles(shooter, nil, nil);
            end

            last_tick_count = tick;
        end
    end);

    timer.Create("projectiles_cleanup", 120.0, 0, function()
        for ent, _ in next, projectile_store do
            if is_valid(ent) then continue; end
            projectile_store[ent] = nil;
            projectiles.shooter_velocities[ent] = nil;
        end
    end);
end

if CLIENT then
    local scr_w = ScrW;
    local scr_h = ScrH;
    local local_player = LocalPlayer;
    local set_texture = surface.SetTexture;
    local set_draw_color = surface.SetDrawColor;
    local draw_poly = surface.DrawPoly;
    local draw_simple_text = draw.SimpleText;
    local text_align_center = TEXT_ALIGN_CENTER;
    local text_align_top = TEXT_ALIGN_TOP;
    local color_white = color_white;
    local simple_text = draw.SimpleText;
    
    hook.Add("HUDPaint", "projectiles_wind_hud", function()
        if not projectiles["pro_wind_enabled"] or not projectiles["pro_render_wind_hud"] then return; end
    
        local cx, cy = scr_w() / 2, 150;
        local arrow_size = 40;
        local speed = vec_len(wind_vector);
    
        local function get_arrow_poly(x, y, ang_rad, size)
            local pts = {};
            local offsets = {
                {x = size, y = 0},
                {x = -size * 0.6, y = size * 0.5},
                {x = -size * 0.3, y = 0},
                {x = -size * 0.6, y = -size * 0.5}
            };
    
            local s, c = sin(ang_rad), cos(ang_rad)
    
            for idx = 1, #offsets do
                local pt = offsets[idx];
                pts[idx] = {
                    x = x + (pt.x * c - pt.y * s),
                    y = y + (pt.x * s + pt.y * c)
                };
            end
            return pts;
        end
    
        set_texture(0);
    
        local ply_ang = local_player():EyeAngles().y
        local correction = 1.5707963267949;--math.pi / 2;
    
        -- target wind
        local target_ang_deg = wind_target_vector:Angle().y - ply_ang;
        local target_rad = rad(-target_ang_deg) - correction;
        
        local target_poly = get_arrow_poly(cx, cy, target_rad, arrow_size);
        set_draw_color(255, 255, 255, 50);
        draw_poly(target_poly);
    
        -- current wind
        if speed > 0.1 then
            local cur_ang_deg = wind_vector:Angle().y - ply_ang
            local cur_rad = rad(-cur_ang_deg) - correction
    
            local cur_poly = get_arrow_poly(cx, cy, cur_rad, arrow_size)
            set_draw_color(0, 255, 255, 255)
            draw_poly(cur_poly)
        end
    
        simple_text(
            string_format("Wind: %.1fu/s", speed), 
            "DermaDefaultBold",
            cx, 
            cy + arrow_size + 10, 
            color_white, 
            TEXT_ALIGN_CENTER, 
            TEXT_ALIGN_TOP
        );
    end);
end

print("loaded projectiles move");