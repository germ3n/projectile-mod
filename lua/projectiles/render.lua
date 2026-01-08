AddCSLuaFile();

local projectiles = projectiles;

if SERVER then return; end

local projectile_store = projectile_store;
local next = next;
local unpredicted_cur_time = UnPredictedCurTime;
local tick_interval = engine.TickInterval();
local tick_count = engine.TickCount;
local rand = math.Rand;
local sqrt = math.sqrt;
local clamp = math.Clamp;
local lerp_vector = LerpVector;
local set_material = render.SetMaterial;
local draw_sprite = render.DrawSprite;
local draw_beam = render.DrawBeam;
local local_player = LocalPlayer;
local eye_pos = EyePos;

local mat_glow = Material("sprites/light_glow02_add");
local mat_beam = Material("effects/laser1");

local is_valid = IsValid;

local vector_meta = FindMetaTable("Vector");
local distance_to_sqr = vector_meta.DistToSqr;
local length_sqr = vector_meta.LengthSqr;

local cv_render_enabled = GetConVar("pro_render_enabled");
local cv_render_min_distance = GetConVar("pro_render_min_distance");
local cv_spawn_fade_distance = GetConVar("pro_spawn_fade_distance");
local cv_spawn_fade_time = GetConVar("pro_spawn_fade_time");
local cv_spawn_offset = GetConVar("pro_spawn_offset");
local cv_min_trail_length = GetConVar("pro_min_trail_length");
local cv_distance_scale_enabled = GetConVar("pro_distance_scale_enabled");
local cv_distance_scale_start = GetConVar("pro_distance_scale_start");
local cv_distance_scale_max = GetConVar("pro_distance_scale_max");

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;

local cached_render_enabled = get_bool(cv_render_enabled);
local cached_render_min_distance = get_float(cv_render_min_distance);
local cached_spawn_fade_distance = get_float(cv_spawn_fade_distance);
local cached_spawn_fade_time = get_float(cv_spawn_fade_time);
local cached_spawn_offset = get_float(cv_spawn_offset);
local cached_min_trail_length = get_float(cv_min_trail_length);
local cached_distance_scale_enabled = get_bool(cv_distance_scale_enabled);
local cached_distance_scale_start = get_float(cv_distance_scale_start);
local cached_distance_scale_max = get_float(cv_distance_scale_max);

cvars.AddChangeCallback("pro_render_enabled", function(_, _, new) cached_render_enabled = tobool(new); end);
cvars.AddChangeCallback("pro_render_min_distance", function(_, _, new) cached_render_min_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_fade_distance", function(_, _, new) cached_spawn_fade_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_fade_time", function(_, _, new) cached_spawn_fade_time = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_offset", function(_, _, new) cached_spawn_offset = tonumber(new); end);
cvars.AddChangeCallback("pro_min_trail_length", function(_, _, new) cached_min_trail_length = tonumber(new); end);
cvars.AddChangeCallback("pro_distance_scale_enabled", function(_, _, new) cached_distance_scale_enabled = tobool(new); end);
cvars.AddChangeCallback("pro_distance_scale_start", function(_, _, new) cached_distance_scale_start = tonumber(new); end);
cvars.AddChangeCallback("pro_distance_scale_max", function(_, _, new) cached_distance_scale_max = tonumber(new); end);

local sprite_batch_core = {};
local sprite_batch_glow = {};
local sprite_batch_outer = {};
local beam_batch = {};

local function render_projectiles()
    if not cached_render_enabled then return; end
    
    local cur_time_val = tick_count() * tick_interval;
    local real_time = unpredicted_cur_time();
    local time_since_tick = real_time - cur_time_val;
    local interp_fraction = time_since_tick / tick_interval;
    if interp_fraction > 3.0 then interp_fraction = 3.0; end

    local ply = local_player();
    local cam_pos = eye_pos();
    local min_dist_sqr = cached_render_min_distance;
    min_dist_sqr = min_dist_sqr * min_dist_sqr;
    local spawn_fade_dist = cached_spawn_fade_distance;
    local spawn_fade_time = cached_spawn_fade_time;
    local spawn_offset = cached_spawn_offset;
    local min_trail_length = cached_min_trail_length;
    local dist_scale_start = cached_distance_scale_start;
    local dist_scale_max = cached_distance_scale_max;

    local core_idx = 0;
    local glow_idx = 0;
    local outer_idx = 0;
    local beam_idx = 0;
    local max_interp_dist_sqr = 10000 * 10000;
    
    for shooter, projs in next, projectile_store do
        if not is_valid(shooter) then continue; end
        
        local is_local_shooter = shooter == ply;
        local active_projectile_count = #projectile_store[shooter].active_projectiles;

        for idx = 1, active_projectile_count do
            local p_data = projectile_store[shooter].active_projectiles[idx];
            
            local render_pos = p_data.pos;
            
            if p_data.old_pos and p_data.vel then
                local safe_interp = true;
                if distance_to_sqr(p_data.pos, p_data.old_pos) > max_interp_dist_sqr then
                    safe_interp = false;
                end
                
                if safe_interp then
                    if interp_fraction <= 1.0 then
                        local old_vel = p_data.old_vel or p_data.vel;
                        local t = interp_fraction;
                        local t2 = t * t;
                        local t3 = t2 * t;
                        
                        local h1 = 2*t3 - 3*t2 + 1;
                        local h2 = -2*t3 + 3*t2;
                        local h3 = t3 - 2*t2 + t;
                        local h4 = t3 - t2;
                        
                        render_pos = (p_data.old_pos * h1) + (p_data.pos * h2) + 
                                     (old_vel * h3 * tick_interval) + (p_data.vel * h4 * tick_interval);
                    else
                        local over_time = (interp_fraction - 1.0) * tick_interval;
                        render_pos = p_data.pos + (p_data.vel * over_time);
                    end
                end
            end
            
            local dist_to_cam_sqr = distance_to_sqr(render_pos, cam_pos);
            if is_local_shooter and dist_to_cam_sqr < min_dist_sqr then continue; end

            local dist_to_cam = sqrt(dist_to_cam_sqr);
            local distance_scale = 1.0;
            if dist_to_cam > dist_scale_start then
                local dist_ratio = (dist_to_cam - dist_scale_start) / dist_scale_start;
                distance_scale = clamp(1.0 + dist_ratio * 0.5, 1.0, dist_scale_max);
            end

            local flicker = rand(0.8, 1.2);
            local scale_mod = flicker * distance_scale;

            local base_size = clamp(sqrt(p_data.damage) * 0.8, 4, 18);
            local final_size = base_size * scale_mod;

            core_idx = core_idx + 1;
            sprite_batch_core[core_idx] = {render_pos, final_size * 0.4, p_data.tracer_colors[1]};
            
            glow_idx = glow_idx + 1;
            sprite_batch_glow[glow_idx] = {render_pos, final_size, p_data.tracer_colors[1]};
            
            outer_idx = outer_idx + 1;
            sprite_batch_outer[outer_idx] = {render_pos, final_size * 1.8, p_data.tracer_colors[2]};

            local tail_start = render_pos;
            local tail_end = p_data.old_pos or render_pos;
            
            local visual_spawn_pos = p_data.spawn_pos;
            if is_local_shooter and visual_spawn_pos and spawn_offset > 0 then
                local spawn_to_cam_dist = distance_to_sqr(visual_spawn_pos, cam_pos);
                if spawn_to_cam_dist < 1600 then
                    if p_data.vel then
                        local vel_len_sqr = length_sqr(p_data.vel);
                        if vel_len_sqr > 1 then
                            local vel_dir = p_data.vel * (1.0 / sqrt(vel_len_sqr));
                            visual_spawn_pos = visual_spawn_pos + (vel_dir * spawn_offset);
                        end
                    end
                end
            end
            
            if visual_spawn_pos and p_data.spawn_time then
                local time_alive = cur_time_val - p_data.spawn_time;
                local time_fade = clamp(time_alive / spawn_fade_time, 0, 1);
                
                local dist_from_spawn_sqr = distance_to_sqr(p_data.pos, visual_spawn_pos);
                local distance_fade = 0;
                if dist_from_spawn_sqr < (spawn_fade_dist * spawn_fade_dist) then
                    distance_fade = clamp(sqrt(dist_from_spawn_sqr) / spawn_fade_dist, 0, 1);
                else
                    distance_fade = 1;
                end
                
                local fade_alpha = clamp(time_fade + distance_fade * 0.5, 0, 1);
                
                local spawn_influence = 1.0 - fade_alpha;
                local motion_influence = fade_alpha;
                
                if p_data.old_pos then
                    tail_end = (visual_spawn_pos * spawn_influence) + (p_data.old_pos * motion_influence);
                else
                    tail_end = visual_spawn_pos;
                end
            end
            
            if p_data.vel and min_trail_length > 0 then
                local trail_vec = tail_start - tail_end;
                local trail_len_sqr = length_sqr(trail_vec);
                if trail_len_sqr < (min_trail_length * min_trail_length) then
                    local vel_len_sqr = length_sqr(p_data.vel);
                    if vel_len_sqr > 1 then
                        local extend_dir = p_data.vel * (1.0 / sqrt(vel_len_sqr));
                        tail_end = tail_start - (extend_dir * min_trail_length);
                    end
                end
            end
            
            local beam_length_sqr = distance_to_sqr(tail_start, tail_end);
            if beam_length_sqr > 4.0 then
                beam_idx = beam_idx + 1;
                beam_batch[beam_idx] = {tail_start, tail_end, final_size * 0.6, p_data.tracer_colors[2]};
            end
        end
    end

    set_material(mat_glow);
    for i = 1, core_idx do
        local s = sprite_batch_core[i];
        draw_sprite(s[1], s[2], s[2], s[3]);
    end
    
    for i = 1, glow_idx do
        local s = sprite_batch_glow[i];
        draw_sprite(s[1], s[2], s[2], s[3]);
    end
    
    for i = 1, outer_idx do
        local s = sprite_batch_outer[i];
        draw_sprite(s[1], s[2], s[2], s[3]);
    end

    set_material(mat_beam);
    for i = 1, beam_idx do
        local b = beam_batch[i];
        draw_beam(b[1], b[2], b[3], 0, 1, b[4]);
    end
end

hook.Add("PostDrawTranslucentRenderables", "projectiles_render", function(drawing_depth, drawing_skybox)
    if drawing_skybox or drawing_depth then return; end
    render_projectiles();
end);

print("loaded projectiles render");