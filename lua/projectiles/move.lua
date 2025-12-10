AddCSLuaFile();

local CLIENT = CLIENT;
local SERVER = SERVER;
local next = next;
local tick_interval = engine.TickInterval();
local projectile_store = projectile_store;
local handle_penetration = handle_penetration;
local projectile_move_trace = projectile_move_trace;
local get_damage_multiplier = get_damage_multiplier;
local band = bit.band;
local point_contents = util.PointContents;
local trace_line_ex = util.TraceLine;
local get_surface_data = util.GetSurfaceData;
local string_format = string.format;
local CONTENTS_WATER = CONTENTS_WATER;
local MASK_WATER = MASK_WATER;
local DMG_BULLET = DMG_BULLET;
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

local entity_meta = FindMetaTable("Entity");
local is_valid = entity_meta.IsValid;
local take_damage_info = entity_meta.TakeDamageInfo;
local fire_bullets = entity_meta.FireBullets;
local get_class = entity_meta.GetClass;

local player_meta = FindMetaTable("Player");
local toggle_lag_compensation = player_meta.LagCompensation;

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

local cusercmd_meta = FindMetaTable("CUserCmd");
local get_command_number = cusercmd_meta.CommandNumber;

local vector_meta = FindMetaTable("Vector");
local get_normalized = vector_meta.GetNormalized;
local vec_len = vector_meta.Length;
local vec_mul = vector_meta.Mul;
local vec_add = vector_meta.Add;
local to_screen = vector_meta.ToScreen;

local cv_debug = get_convar("pro_debug_projectiles");
local cv_debug_dur = get_convar("pro_debug_duration");
local cv_debug_col = get_convar("pro_debug_color");
local cv_debug_pen = get_convar("pro_debug_penetration");

local BREAKABLE_CLASSES = {
    ["func_breakable_surf"] = true,
    ["func_breakable"] = true,
    ["prop_physics"] = true,
    ["prop_physics_multiplayer"] = true,
};

local cv_drag_enabled = get_convar("pro_drag_enabled");
local cv_drag_multiplier = get_convar("pro_drag_multiplier");
local cv_drag_water_multiplier = get_convar("pro_drag_water_multiplier");
local cv_gravity_enabled = get_convar("pro_gravity_enabled");
local cv_gravity_multiplier = get_convar("pro_gravity_multiplier");
local cv_gravity_water_multiplier = get_convar("pro_gravity_water_multiplier");
local cv_drop_multiplier = get_convar("pro_drop_multiplier");
local cv_sv_gravity = get_convar("sv_gravity");

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;
local get_int = convar_meta.GetInt;
local get_string = convar_meta.GetString;

local max = math.max;

local trace_filter = {nil, nil, nil};

local function do_water_trace(projectile_data, new_pos, filter)
    local was_in_water = band(point_contents(projectile_data.pos), CONTENTS_WATER) ~= 0;
    local is_in_water = band(point_contents(new_pos), CONTENTS_WATER) ~= 0;

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
    local dur = get_float(cv_debug_dur);
    local col_vec = string_split(get_string(cv_debug_col), " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_line(projectile_data.pos, enter_trace.HitPos, dur, col, true);
    
    if enter_trace.Hit then
        debug_box(enter_trace.HitPos, vector(-2, -2, -2), vector(2, 2, 2), dur, col, true);
    end
end

local function debug_penetration(projectile_data, current_hit_damage, current_penetration_power, exit_pos, enter_trace, exit_trace)
    local dur = get_float(cv_debug_dur);
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

local function move_projectile(shooter, projectile_data)
    if projectile_data.hit or projectile_data.penetration_count <= 0 or projectile_data.damage < 1.0 or projectile_data.distance_traveled >= projectile_data.max_distance then 
        return true;
    end

    if get_bool(cv_drag_enabled) then
        local drag_factor = projectile_data.drag * tick_interval * get_float(cv_drag_multiplier);
        if band(point_contents(projectile_data.pos), CONTENTS_WATER) ~= 0 then
            drag_factor = drag_factor * get_float(cv_drag_water_multiplier);
        end

        projectile_data.speed = projectile_data.speed - projectile_data.speed * drag_factor;
    end

    if projectile_data.speed <= 50.0 then
        projectile_data.hit = true;
        return true;
    end

    local current_velocity = projectile_data.dir * projectile_data.speed;
    
    if get_bool(cv_gravity_enabled) then
        local gravity_strength = get_float(cv_sv_gravity) * projectile_data.drop * get_float(cv_gravity_multiplier);
        gravity_vector.z = -gravity_strength;
        if band(point_contents(projectile_data.pos), CONTENTS_WATER) ~= 0 then
            gravity_vector.z = gravity_vector.z * get_float(cv_gravity_water_multiplier);
        end

        current_velocity.z = current_velocity.z + gravity_vector.z * tick_interval;

        projectile_data.dir = get_normalized(current_velocity);
        projectile_data.speed = vec_len(current_velocity);
    end
    
    vec_mul(current_velocity, tick_interval);
    local current_pos = projectile_data.pos;
    local new_pos = projectile_data.pos + current_velocity;
    
    trace_filter[1] = shooter;
    trace_filter[2] = projectile_data.weapon;
    trace_filter[3] = projectile_data.last_hit_entity;
    if CLIENT then do_water_trace(projectile_data, new_pos, trace_filter); end -- had to move to seperate funcs cuz i hit more than 60 upvalues
    
    local enter_trace = projectile_move_trace(projectile_data.pos, new_pos, trace_filter);

    if get_bool(cv_debug) then debug_projectile_course(projectile_data, enter_trace); end

    if enter_trace.Hit then
        if CLIENT then
            local effect_data = effect_data();
            set_origin(effect_data, enter_trace.HitPos);
            set_start(effect_data, enter_trace.StartPos);
            set_surface_prop(effect_data, enter_trace.SurfaceProps);
            set_entity(effect_data, enter_trace.Entity);
            set_hit_box(effect_data, enter_trace.HitBoxBone or 0);
            set_damage_type(effect_data, DMG_BULLET);
            effect("Impact", effect_data);
        end
    
        local hit_entity = enter_trace.Entity;
        local current_hit_damage = projectile_data.damage;
        local current_penetration_power = projectile_data.penetration_power;

        local stop_bullet, exit_pos, exit_trace = handle_penetration(shooter, projectile_data, enter_trace.HitPos, projectile_data.dir, projectile_data.constpen, projectile_data.penetration_power, enter_trace);

        -- todo: fix
        if get_bool(cv_debug_pen) and exit_pos then
            debug_penetration(projectile_data, current_hit_damage, current_penetration_power, exit_pos, enter_trace, exit_trace);
        end

        if CLIENT and exit_trace and exit_trace.Hit then
            local effect_data = effect_data();
            set_origin(effect_data, exit_trace.HitPos);
            set_start(effect_data, exit_trace.StartPos);
            set_surface_prop(effect_data, exit_trace.SurfaceProps);
            set_entity(effect_data, exit_trace.Entity);
            set_hit_box(effect_data, exit_trace.HitBoxBone or 0);
            set_damage_type(effect_data, DMG_BULLET);
            effect("Impact", effect_data);
        end

        if hit_entity and hit_entity ~= NULL then
            local final_damage = current_hit_damage * get_damage_multiplier(enter_trace.HitGroup);
            
            if SERVER then
                if BREAKABLE_CLASSES[get_class(hit_entity)] then
                    projectiles.disable_fire_bullets = true;
                    fire_bullets_config.Attacker = shooter;
                    fire_bullets_config.Damage = final_damage;
                    fire_bullets_config.Force = final_damage;
                    fire_bullets_config.Distance = 1;
                    fire_bullets_config.Dir = projectile_data.dir;
                    fire_bullets_config.Src = enter_trace.HitPos - (projectile_data.dir * 0.5);
                    fire_bullets_config.Tracer = 0;
                    fire_bullets_config.AmmoType = "Pistol";
                    fire_bullets(shooter, fire_bullets_config);
                    projectiles.disable_fire_bullets = false;
                else
                    local dmg_info = damage_info();
                    set_damage(dmg_info, final_damage);
                    set_inflictor(dmg_info, projectile_data.weapon);
                    set_weapon(dmg_info, projectile_data.weapon);
                    set_attacker(dmg_info, shooter);
                    dmg_set_damage_type(dmg_info, DMG_BULLET);
                    set_damage_position(dmg_info, enter_trace.HitPos);
                    set_damage_force(dmg_info, projectile_data.dir * final_damage * 50);

                    take_damage_info(hit_entity, dmg_info);
                end
            end
        end
        
        if stop_bullet then
            projectile_data.hit = true;
            projectile_data.pos = enter_trace.HitPos;

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

    projectile_data.old_pos = current_pos;

    return false;
end


local function debug_final_pos(projectile_data)
    local dur = get_float(cv_debug_dur);
    local col_vec = string_split(get_string(cv_debug_col), " ");
    local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] and tonumber(col_vec[4]) or 150);

    debug_box(projectile_data.pos, vector(-1, -1, -1), vector(1, 1, 1), dur, col, true);
end

local function move_projectiles(ply, mv, cmd)
    local projectiles = projectile_store[ply];
    if not projectiles then return; end

    if SERVER and ply:IsPlayer() then toggle_lag_compensation(ply, true); end
    
    local active_projectile_count = #projectiles.active_projectiles;
    local idx = 1;
    while idx <= active_projectile_count do
        local hit = move_projectile(ply, projectiles.active_projectiles[idx]);
        if hit then
            if get_bool(cv_debug) then debug_final_pos(projectiles.active_projectiles[idx]); end
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
    local is_valid = IsValid;
    hook.Add("SetupMove", "projectiles_tick", move_projectiles)
    hook.Add("Tick", "projectiles_tick", function()
        for shooter, _ in next, projectile_store do
            if is_valid(shooter) and shooter:IsNPC() then 
                move_projectiles(shooter, nil, nil);
            end
        end
    end)
else    
    local is_valid = IsValid;
    hook.Add("CreateMove", "projectiles_tick", function(cmd)
        if get_command_number(cmd) ~= 0 then
            for shooter, _ in next, projectile_store do
                if not is_valid(shooter) then continue; end
                move_projectiles(shooter, nil, nil);
            end
        end
    end)
end

print("loaded projectiles move");