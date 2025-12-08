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

local cv_debug = get_convar("pro_debug_projectiles");
local cv_debug_dur = get_convar("pro_debug_duration");
local cv_debug_col = get_convar("pro_debug_color");
local cv_debug_pen = get_convar("pro_debug_penetration");

local function move_projectile(shooter, projectile_data)
    if not projectile_data or projectile_data.hit or projectile_data.penetration_count <= 0 or projectile_data.damage < 1.0 then 
        return;
    end

    local interval = tick_interval;
    local velocity = projectile_data.dir * projectile_data.speed;
    local drag_offset = vector(0, 0, -projectile_data.drag * interval);
    
    local step = (velocity * interval) + drag_offset;
    local new_pos = projectile_data.pos + step;
    
    local filter = {shooter, projectile_data.weapon, projectile_data.last_hit_entity};

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
            if CLIENT then
                local effectdata = effect_data();
                set_origin(effectdata, water_trace.HitPos);
                set_scale(effectdata, projectile_data.damage * 0.1);
                set_flags(effectdata, 0);
                effect("gunshotsplash", effectdata);
            end
            
            projectile_data.drag = projectile_data.drag * 4;
        end
    end
    
    local enter_trace = projectile_move_trace(projectile_data.pos, new_pos, filter);

    if cv_debug and cv_debug:GetBool() then
        local dur = cv_debug_dur:GetFloat();
        local col_vec = string_split(cv_debug_col:GetString(), " ");
        local col = color(tonumber(col_vec[1]), tonumber(col_vec[2]), tonumber(col_vec[3]), col_vec[4] or 150);

        debug_line(projectile_data.pos, enter_trace.HitPos, dur, col, true);
        
        if enter_trace.Hit then
            debug_box(enter_trace.HitPos, vector(-2, -2, -2), vector(2, 2, 2), dur, col, true);
        end
    end

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

        local stop_bullet, exit_pos, exit_trace = handle_penetration(shooter, projectile_data, enter_trace.HitPos, projectile_data.dir, projectile_data.constpen, enter_trace);

        -- todo: fix
        if cv_debug_pen and cv_debug_pen:GetBool() and exit_pos then
            local dur = cv_debug_dur:GetFloat();
            debug_line(enter_trace.HitPos, exit_pos, dur, color(255, 0, 0, 150), true);
            debug_box(exit_pos, vector(-1, -1, -1), vector(1, 1, 1), dur, color(255, 0, 0, 150), true);

            local dmg_lost = current_hit_damage - projectile_data.damage;
            local enter_mat = enter_trace and enter_trace.SurfaceProps and get_surface_data(enter_trace.SurfaceProps).name or "unknown";
            local exit_mat = exit_trace and exit_trace.SurfaceProps and get_surface_data(exit_trace.SurfaceProps).name or "unknown";
            
            debug_text(exit_pos + vector(0, 0, 10), string_format("lost: %.1f\nremaining: %.1f\nmat_in: %s\nmat_out: %s", dmg_lost, projectile_data.damage, enter_mat, exit_mat), dur, false);
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

        if hit_entity and is_valid(hit_entity) then
            local dmg_mult = get_damage_multiplier(enter_trace.HitGroup);
            local final_damage = current_hit_damage * dmg_mult;
            
            if SERVER then
                if get_class(hit_entity) == "func_breakable_surf" then
                    fire_bullets(hit_entity, {
                        Attacker = shooter,
                        Damage = final_damage,
                        Force = final_damage,
                        Distance = 32,
                        Dir = projectile_data.dir,
                        Src = enter_trace.HitPos,
                        Tracer = 0,
                        AmmoType = "Pistol" 
                    });
                else
                    local dmg_info = damage_info();
                    set_damage(dmg_info, final_damage);
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

            return; 
        else
            if hit_entity and is_valid(hit_entity) then
                projectile_data.last_hit_entity = hit_entity;
            end

            if exit_pos then
                projectile_data.pos = exit_pos;
            end
        end

    else
        projectile_data.pos = new_pos;
    end
    
    projectile_data.drag = projectile_data.drag + (projectile_data.drag * interval);
end

local function move_projectiles(ply, mv, cmd)
    local projectiles = projectile_store[ply];
    if not projectiles then return; end
    
    local projectile_idx = projectiles.last_received_idx;
    local buffer_size = projectiles.buffer_size;

    if SERVER then toggle_lag_compensation(ply, true); end
        
    for idx = 1, buffer_size do
        local data = projectiles.buffer[projectile_idx];
        if data then
            move_projectile(ply, data);
        end

        if projectile_idx == 1 then
            projectile_idx = buffer_size;
        else
            projectile_idx = projectile_idx - 1;
        end
    end

    if SERVER then toggle_lag_compensation(ply, false); end
end

if SERVER then
    hook.Add("SetupMove", "projectiles_tick", move_projectiles)
else    
    hook.Add("CreateMove", "projectiles_tick", function(cmd)
        if get_command_number(cmd) ~= 0 then
            for shooter, _ in next, projectile_store do
                move_projectiles(shooter, nil, nil);
            end
        end
    end)
end

print("loaded projectiles move");