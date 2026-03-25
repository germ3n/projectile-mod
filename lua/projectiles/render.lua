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
local band = bit.band;

local mat_glow = Material("sprites/light_glow02_add");
local mat_beam = Material("effects/pro_tracer");

local is_valid = IsValid;

local vector_meta = FindMetaTable("Vector");
local distance_to_sqr = vector_meta.DistToSqr;
local length_sqr = vector_meta.LengthSqr;

local entity_meta = FindMetaTable("Entity");
local entindex = entity_meta.EntIndex;

local cv_render_enabled = GetConVar("pro_render_enabled");
local cv_render_min_distance = GetConVar("pro_render_min_distance");
local cv_spawn_fade_distance = GetConVar("pro_spawn_fade_distance");
local cv_spawn_fade_time = GetConVar("pro_spawn_fade_time");
local cv_spawn_offset = GetConVar("pro_spawn_offset");
local cv_spawn_offset_max_dist = GetConVar("pro_spawn_offset_max_dist");
local cv_min_trail_length = GetConVar("pro_min_trail_length");
local cv_distance_scale_enabled = GetConVar("pro_distance_scale_enabled");
local cv_distance_scale_start = GetConVar("pro_distance_scale_start");
local cv_distance_scale_max = GetConVar("pro_distance_scale_max");
local cv_max_interp_distance = GetConVar("pro_max_interp_distance");
local cv_max_interp_camera_distance = GetConVar("pro_max_interp_camera_distance");
local cv_render_disable_tracers = GetConVar("pro_render_disable_tracers");
local cv_render_disable_tracer_smoke = GetConVar("pro_render_disable_tracer_smoke");
local cv_render_tracer_size = GetConVar("pro_render_tracer_size");

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;

local cached_render_enabled = get_bool(cv_render_enabled);
local cached_render_min_distance = get_float(cv_render_min_distance);
local cached_spawn_fade_distance = get_float(cv_spawn_fade_distance);
local cached_spawn_fade_time = get_float(cv_spawn_fade_time);
local cached_spawn_offset = get_float(cv_spawn_offset);
local cached_spawn_offset_max_dist = get_float(cv_spawn_offset_max_dist);
local cached_min_trail_length = get_float(cv_min_trail_length);
local cached_distance_scale_enabled = get_bool(cv_distance_scale_enabled);
local cached_distance_scale_start = get_float(cv_distance_scale_start);
local cached_distance_scale_max = get_float(cv_distance_scale_max);
local cached_max_interp_distance = get_float(cv_max_interp_distance);
local cached_max_interp_camera_distance = get_float(cv_max_interp_camera_distance);
local cached_render_disable_tracers = get_bool(cv_render_disable_tracers);
local cached_render_disable_tracer_smoke = get_bool(cv_render_disable_tracer_smoke);
local cached_render_tracer_size = get_float(cv_render_tracer_size);



cvars.AddChangeCallback("pro_render_enabled", function(_, _, new) cached_render_enabled = tobool(new); end);
cvars.AddChangeCallback("pro_render_min_distance", function(_, _, new) cached_render_min_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_fade_distance", function(_, _, new) cached_spawn_fade_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_fade_time", function(_, _, new) cached_spawn_fade_time = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_offset", function(_, _, new) cached_spawn_offset = tonumber(new); end);
cvars.AddChangeCallback("pro_spawn_offset_max_dist", function(_, _, new) cached_spawn_offset_max_dist = tonumber(new); end);
cvars.AddChangeCallback("pro_min_trail_length", function(_, _, new) cached_min_trail_length = tonumber(new); end);
cvars.AddChangeCallback("pro_distance_scale_enabled", function(_, _, new) cached_distance_scale_enabled = tobool(new); end);
cvars.AddChangeCallback("pro_distance_scale_start", function(_, _, new) cached_distance_scale_start = tonumber(new); end);
cvars.AddChangeCallback("pro_distance_scale_max", function(_, _, new) cached_distance_scale_max = tonumber(new); end);
cvars.AddChangeCallback("pro_max_interp_distance", function(_, _, new) cached_max_interp_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_max_interp_camera_distance", function(_, _, new) cached_max_interp_camera_distance = tonumber(new); end);
cvars.AddChangeCallback("pro_render_disable_tracers", function(_, _, new) cached_render_disable_tracers = tobool(new); end);
cvars.AddChangeCallback("pro_render_tracer_size", function(_, _, new) cached_render_tracer_size = tonumber(new); end);

local sprite_batch_core = {};
local sprite_batch_glow = {};
local sprite_batch_outer = {};
local beam_batch = {};

local last_cvar_update = 0;
local cvar_update_interval = 1.0;

local RealTime = RealTime
local vector_origin = Vector(0,0,0)



local function update_cached_cvars()
    cached_render_enabled = get_bool(cv_render_enabled);
    cached_render_min_distance = get_float(cv_render_min_distance);
    cached_spawn_fade_distance = get_float(cv_spawn_fade_distance);
    cached_spawn_fade_time = get_float(cv_spawn_fade_time);
    cached_spawn_offset = get_float(cv_spawn_offset);
    cached_spawn_offset_max_dist = get_float(cv_spawn_offset_max_dist);
    cached_min_trail_length = get_float(cv_min_trail_length);
    cached_distance_scale_enabled = get_bool(cv_distance_scale_enabled);
    cached_distance_scale_start = get_float(cv_distance_scale_start);
    cached_distance_scale_max = get_float(cv_distance_scale_max);
    cached_max_interp_distance = get_float(cv_max_interp_distance);
    cached_max_interp_camera_distance = get_float(cv_max_interp_camera_distance);
    cached_render_disable_tracers = get_bool(cv_render_disable_tracers);
    cached_render_disable_tracer_smoke = get_bool(cv_render_disable_tracer_smoke);
    cached_render_tracer_size = get_float(cv_render_tracer_size);
end

local function render_projectiles()
    local cur_real_time = unpredicted_cur_time();
    if cur_real_time - last_cvar_update > cvar_update_interval then
        update_cached_cvars();
        last_cvar_update = cur_real_time;
    end

    if not cached_render_enabled then return; end
    
    local cur_time_val = tick_count() * tick_interval;
    local real_time = unpredicted_cur_time();
    local time_since_tick = real_time - cur_time_val;
    local interp_fraction = time_since_tick / tick_interval;
    if interp_fraction > 3.0 then interp_fraction = 3.0; end

    local ply = local_player();
    local local_entindex = entindex(ply);
    local cam_pos = eye_pos();
    local min_dist_sqr = cached_render_min_distance;
    min_dist_sqr = min_dist_sqr * min_dist_sqr;
    local spawn_fade_dist = cached_spawn_fade_distance;
    local spawn_fade_time = cached_spawn_fade_time;
    local spawn_offset = cached_spawn_offset;
    local spawn_offset_max_dist = cached_spawn_offset_max_dist;
    local spawn_offset_max_dist_sqr = spawn_offset_max_dist * spawn_offset_max_dist;
    local min_trail_length = cached_min_trail_length;
    local dist_scale_start = cached_distance_scale_start;
    local dist_scale_max = cached_distance_scale_max;
    local tracer_size = cached_render_tracer_size;

    local core_idx = 0;
    local glow_idx = 0;
    local outer_idx = 0;
    local beam_idx = 0;
    local max_interp_dist = cached_max_interp_distance;
    local max_interp_dist_sqr = max_interp_dist * max_interp_dist;
    local max_interp_cam_dist = cached_max_interp_camera_distance;
    local max_interp_cam_dist_sqr = max_interp_cam_dist * max_interp_cam_dist;


    local function GetMuzzlePos(shooter)
        
        shooter = shooter or LocalPlayer()  -- fallback to local player if no arg given
    
        if not IsValid(shooter) then return nil end
    
        local wep = shooter:GetActiveWeapon()
        if not IsValid(wep) then return nil end
    
        local attachments = {"muzzle", "muzzle_flash", "barrel", "flash", "muzzle_1", "1" , "0", "muzzle_attach"}
    
        -- First-person viewmodel (only relevant for local player)
        if shooter == LocalPlayer() and not shooter:ShouldDrawLocalPlayer() then
            local vm = shooter:GetViewModel()
            if IsValid(vm) then
                for _, name in ipairs(attachments) do
                    local att = vm:LookupAttachment(name)
                    if att > 0 then
                        local attData = vm:GetAttachment(att)
                        if attData and attData.Pos then return attData.Pos end
                    end
                end
            end
        end
    
        -- World model muzzle (NPCs, third-person players, fallback)
        for _, name in ipairs(attachments) do
            local att = wep:LookupAttachment(name)
            if att > 0 then
                local attData = wep:GetAttachment(att)
                if attData and attData.Pos then
                    -- Optional sanity check: if suspiciously low (feet level), fallback
                    local feetZ = shooter:GetPos().z + 8
                    if attData.Pos.z < feetZ + 25 then goto next_att end
                    return attData.Pos
                end
            end
            ::next_att::
        end
    
        -- Ultimate fallback: eye pos + forward (safe for NPCs without proper attachments)
        local eye = shooter:EyePos()
        return eye + shooter:EyeAngles():Forward() * 24
    end
    
    for entindex, projs in next, projectile_store do
        --if not is_valid(entindex) then continue; end
        
        local is_local_shooter = entindex == local_entindex;
        local active_projectiles = projectile_store[entindex].active_projectiles;
        local active_projectile_count = #active_projectiles;

        for idx = 1, active_projectile_count do
            local p_data = active_projectiles[idx];
            
            local render_pos = p_data.pos;
            local safe_interp = false;
            
            --if p_data.old_pos and p_data.vel then
                safe_interp = true;
                if distance_to_sqr(p_data.pos, p_data.old_pos) > max_interp_dist_sqr then
                    safe_interp = false;
                end

                if distance_to_sqr(p_data.pos, cam_pos) > max_interp_cam_dist_sqr then
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
            --end
            
            --Sounds
            -- Improved Flyby Detection (ray from old_pos to current_pos)
            if projectiles["pro_flyby_sounds_enabled"] then
                local ply = LocalPlayer()
                if not IsValid(ply) then goto end_flyby end
                if p_data._crack_has_fired then goto end_flyby end

                if not ply.flybyShakeCooldownUntil then
                    ply.flybyShakeCooldownUntil = CurTime() + 0.5
                end

                local ply_pos = ply:EyePos()

                local flyby_dist = projectiles["pro_flyby_distance"] or 300
                local crack_dist = flyby_dist + 10 * (p_data.damage or 10)^0.5

                local flyby_max_dist_sq = flyby_dist * flyby_dist
                local crack_max_dist_sq = crack_dist * crack_dist

                -- Use the actual segment the bullet just traveled this frame
                local start_pos = p_data.old_pos or p_data.spawn_pos or p_data.pos
                local end_pos   = p_data.pos

                local segment_dir = end_pos - start_pos
                local segment_len = segment_dir:Length()

                if segment_len < 1 then goto end_flyby end

                segment_dir:Normalize()

                local to_player = ply_pos - start_pos
                local t = to_player:Dot(segment_dir)   -- <-- FIXED: use :Dot()

                -- Clamp t to the actual segment traveled this frame
                t = math.Clamp(t, 0, segment_len)

                local closest = start_pos + segment_dir * t
                local dist_sq = ply_pos:DistToSqr(closest)
                local dist = math.sqrt(dist_sq)

                -- Too close = ignore (prevents ear rape)
                --if dist < 180 then goto end_flyby end

                if t > 5 then

                    -- FLYBY WHIZZ (subsonic whoosh)
                    if dist_sq < flyby_max_dist_sq and p_data.speed > 800 then
                        local min_dist = p_data._flyby_min_dist or math.huge
                        if dist_sq < min_dist * 0.92 then
                            p_data._flyby_min_dist = dist_sq

                            local whizz_sounds = {
                                "weapons/fx/nearmiss/bulletLtoR03.wav",
                                "weapons/fx/nearmiss/bulletLtoR04.wav",
                                "weapons/fx/nearmiss/bulletLtoR05.wav",
                                "weapons/fx/nearmiss/bulletLtoR06.wav",
                                "weapons/fx/nearmiss/bulletLtoR07.wav",
                                "weapons/fx/nearmiss/bulletLtoR09.wav",
                                "weapons/fx/nearmiss/bulletLtoR10.wav",
                                "weapons/fx/nearmiss/bulletLtoR11.wav",
                                "weapons/fx/nearmiss/bulletLtoR12.wav",
                                "weapons/fx/nearmiss/bulletLtoR13.wav",
                                "weapons/fx/nearmiss/bulletLtoR14.wav"
                            }

                            local snd = whizz_sounds[math.random(#whizz_sounds)]
                            local dist_norm = dist / flyby_dist
                            local vol = Lerp(dist_norm, 0, (projectiles["pro_flyby_volume_scale"] or 1) * (p_data.speed / 15000))

                            sound.Play(snd, closest, SNDLVL_90dB, math.Rand(0.95, 1.05) * 100, vol)
                        end
                    else
                        p_data._flyby_min_dist = nil
                    end

                    -- SUPERSONIC CRACK
                    local cooldownUntil = ply.flybyShakeCooldownUntil or 0
                    if CurTime() >= cooldownUntil then
                        if dist_sq < crack_max_dist_sq and p_data.speed > (projectiles["pro_sound_speed"] or 13500) then
                            local min_crack_dist = p_data._crack_min_dist or math.huge

                            if dist_sq < min_crack_dist * 0.85 then
                                p_data._crack_min_dist = dist_sq

                                local crack_sounds = {
                                    "weapons/pistol/pistol_fire2.wav",
                                    "weapons/pistol/pistol_fire3.wav",
                                }

                                local snd = crack_sounds[math.random(#crack_sounds)]
                                local snd2 = "weapons/ar1/ar1_dist1.wav"

                                local dist_norm = dist / crack_dist
                                local vol = (p_data.damage or 20) * (projectiles["pro_flyby_volume_scale"] or 0.6)

                                sound.Play(snd, closest, SNDLVL_180dB, math.Rand(0.96, 1.04) * 110, vol)
                                sound.Play(snd2, closest, SNDLVL_180dB, 400, vol * 0.8)

                                local strength = (1.0 - dist_norm) * math.Clamp((p_data.damage or 20) / 50, 0.4, 2.0)

                                util.ScreenShake(p_data.pos, strength * (projectiles["pro_flyby_shake_strenght"] or 1), 10, 0.25, strength * 120)
                                ply:ViewPunch(Angle(math.Rand(-strength*1.2, strength*1.2), math.Rand(-strength*2, strength*2), 0))

                                p_data._crack_has_fired = true
                                ply.flybyShakeCooldownUntil = CurTime() + (projectiles["pro_flyby_shake_cooldown"] or 0.4)
                            end
                        end
                    else
                        p_data._crack_min_dist = nil
                    end
                end
            end
            ::end_flyby::

            local visual_pos = render_pos

            local TURRET_CLASSES = {
                ["npc_turret_floor"]   = true,
                ["npc_turret_ceiling"] = true,
                ["npc_turret_ground"]  = true,
                ["gmod_turret"]        = true,
                ["func_tank"]          = true,
                ["prop_vehicle_airboat"] = true,  -- if airboat gun is used
            };

            local shooter_ent = Entity(entindex)
            local class = IsValid(shooter_ent) and shooter_ent:GetClass() or ""

            local is_turret_bullet = false
            if TURRET_CLASSES[class] then
                is_turret_bullet = true
            else
                -- Check active weapon (critical for gmod_turret + func_tank controlled by player)
                local wep = shooter_ent:GetActiveWeapon()
                if IsValid(wep) then
                    local wep_class = wep:GetClass()
                    if wep_class == "gmod_turret" or 
                       wep_class == "func_tank" or 
                       TURRET_CLASSES[wep_class] then
                        is_turret_bullet = true
                    end
                end
            end
            if not is_turret_bullet then
                local muzzle = GetMuzzlePos(shooter_ent)
                if muzzle then
                    
                    local traveled = (render_pos - muzzle):Length()
                    local converge_dist = p_data.speed^0.5 * 10   -- short but visible window

                    if traveled < converge_dist then
                        local frac = traveled / converge_dist
                        
                        local eased_frac = 1 - (1 - frac)^3   -- cubic ease-out

                        visual_pos = LerpVector(eased_frac, muzzle, render_pos)
                    end
                end
            end

            local dist_to_cam_sqr = distance_to_sqr(render_pos, cam_pos);
            if is_local_shooter and dist_to_cam_sqr < min_dist_sqr * p_data.speed/30000 then continue; end --prevents tracers from spawning behind minimum render distance

            
            local dist_to_cam = sqrt(dist_to_cam_sqr);
            local distance_scale = 1.0;
            if cached_distance_scale_enabled then
                if dist_to_cam > dist_scale_start then
                    local dist_ratio = (dist_to_cam - dist_scale_start) / dist_scale_start;
                    distance_scale = clamp(1.0 + dist_ratio * 0.5, 1.0, dist_scale_max);
                end
            end

            local speed_mod =  p_data.speed/p_data.speed_initial;

            local flicker = rand(0.8, 1.2*speed_mod);
            local scale_mod = flicker * distance_scale;

            local base_size = p_data.caliber * 0.5 or clamp(sqrt(p_data.damage) * 0.8, 4, 18);
            local final_size = base_size * scale_mod * tracer_size;

            local tracer_flags = p_data.tracer_flags;
            local disable_completely = band(tracer_flags, 0x2) ~= 0;
            local no_tracer = band(tracer_flags, 0x1) ~= 0;

            
            --Smoke trail
            if not disable_completely and not no_tracer and not cached_render_disable_tracers and not cached_render_disable_tracer_smoke then
                if p_data.tracer ~= 0 then
                    local now = RealTime()
                
                    p_data.next_smoke = p_data.next_smoke or 0
                
                    if now > p_data.next_smoke then
                        local rate = 0.1
                        p_data.next_smoke = now + rate
                
                        if not projectiles._smoke_emitter then
                            projectiles._smoke_emitter = ParticleEmitter(visual_pos)
                        end
                
                        local emitter = projectiles._smoke_emitter
                
                        local part = emitter:Add("particle/smokesprites_0001", visual_pos)
                
                        if part then
                            local wind_vector = p_data.wind or Vector(0, 0, 0)

                            local wind = wind_vector or vector_origin
                
                            part:SetVelocity(p_data.vel * 1)
                            if not projectiles["pro_wind_enabled"] then
                                wind = Vector(0, 0, 0)
                            end
                                part:SetThinkFunction(function(part)
                                    local vel = part:GetVelocity()
                                    local toward_wind = (wind - vel) * 50 * FrameTime()
                                    part:SetVelocity(vel*0.5 + toward_wind)
                                    
                                    part:SetNextThink(CurTime() + 0.025)
                                end)
                                part:SetNextThink(CurTime() + 0.025)               
                            part:SetLifeTime(0)
                            part:SetDieTime(0.1 + (p_data.damage^0.5) / 5)
                
                            part:SetStartAlpha(80)
                            part:SetEndAlpha(0)
                
                            part:SetStartSize(final_size * 0.22 + math.Rand(-0.8, 0.8))
                            part:SetEndSize(5.5 + math.Rand(1, 5))
                            
                
                            part:SetRoll(math.Rand(0,360))
                            part:SetRollDelta(math.Rand(-2,2))
                
                            part:SetAirResistance(0)

                            part:SetGravity(Vector(math.random(-5, 5),  math.random(-5, 5), -12 + math.random(-5, 3)))
                
                            part:SetColor(200,200,200)

                            part:SetCollide(true)
                            part:SetBounce(0.02)
                        end
                    end
                end
            end


            if not disable_completely then
                core_idx = core_idx + 1;
                sprite_batch_core[core_idx] = {visual_pos, final_size * 0.4, p_data.tracer_colors[1]};
                
                glow_idx = glow_idx + 1;
                sprite_batch_glow[glow_idx] = {visual_pos, final_size, p_data.tracer_colors[1]};
                
                outer_idx = outer_idx + 1;
                sprite_batch_outer[outer_idx] = {visual_pos, final_size * 1.8, p_data.tracer_colors[2]};
            end

            if not disable_completely and not no_tracer and not cached_render_disable_tracers then
                local tail_start = visual_pos;
                local tail_end = p_data.old_pos or visual_pos;
                local tail_end_interpolated = tail_end;

                local effective_spawn_pos = p_data.spawn_pos

                local muzzle_for_tail = GetMuzzlePos(Entity(entindex))
                if muzzle_for_tail then
                    effective_spawn_pos = muzzle_for_tail
                end

            local max_tracer_len = nil
            if effective_spawn_pos then
                local traveled_vec = tail_start - effective_spawn_pos
                local traveled_len_sqr = length_sqr(traveled_vec)
                if traveled_len_sqr > 1 then
                    max_tracer_len = sqrt(traveled_len_sqr)
                else
                    max_tracer_len = 0
                end
            end

           --[[ if not disable_completely and not no_tracer and not cached_render_disable_tracers then
                glow_idx = glow_idx + 1

                    sprite_batch_glow[glow_idx] = {
                        visual_pos,
                        final_size,
                        ColorAlpha(p_data.tracer_colors[2])
                    }

                    outer_idx = outer_idx + 1
                    sprite_batch_outer[outer_idx] = {
                        visual_pos,
                        final_size,
                        ColorAlpha(p_data.tracer_colors[2])
                    }


                local base_width  = final_size          
                local taper_color = ColorAlpha(p_data.tracer_colors[2])

                local max_tracer_len = nil
                if effective_spawn_pos then
                    local traveled_vec = tail_start - effective_spawn_pos
                    local traveled_len_sqr = length_sqr(traveled_vec)
                    if traveled_len_sqr > 1 then
                        max_tracer_len = sqrt(traveled_len_sqr)
                    else
                        max_tracer_len = 0
                    end
                end

                local desired_length = 5 + (p_data.speed / 50)
                if max_tracer_len then
                    desired_length = math.min(desired_length, max_tracer_len)
                end

                local base_length = desired_length
                local base_end = tail_start - (p_data.vel:GetNormalized() * base_length)

                if base_end:DistToSqr(tail_start) > 4 then
                    beam_idx = beam_idx + 1
                    beam_batch[beam_idx] = {
                        tail_start,
                        base_end,
                        base_width,
                        taper_color
                    }
                end
            end]]

                if p_data.old_pos and p_data.old_vel and safe_interp then
                    if interp_fraction <= 1.0 then
                        local prev_old_pos = p_data.old_pos - (p_data.old_vel * tick_interval);
                        local t = interp_fraction;
                        local t2 = t * t;
                        local t3 = t2 * t;

                        local h1 = 2*t3 - 3*t2 + 1;
                        local h2 = -2*t3 + 3*t2;
                        local h3 = t3 - 2*t2 + t;
                        local h4 = t3 - t2;

                        tail_end_interpolated = (prev_old_pos * h1) + (p_data.old_pos * h2) + 
                                                (p_data.old_vel * h3 * tick_interval) + (p_data.old_vel * h4 * tick_interval);
                        tail_end = tail_end_interpolated;
                    else
                        local over_time = (interp_fraction - 1.0) * tick_interval;
                        tail_end_interpolated = p_data.old_pos + (p_data.vel * over_time);
                        tail_end = tail_end_interpolated;
                    end
                end
                
                local visual_spawn_pos = effective_spawn_pos;
                if visual_spawn_pos and spawn_offset > 0 then
                    local spawn_to_cam_dist = distance_to_sqr(visual_spawn_pos, cam_pos);
                    if spawn_to_cam_dist < spawn_offset_max_dist_sqr then
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
                    local time_alive = cur_time_val - p_data.spawn_time
                    local time_fade = clamp(time_alive / spawn_fade_time, 0, 1)
                    
                    local dist_from_spawn_sqr = distance_to_sqr(render_pos, visual_spawn_pos)
                    local distance_fade = 0
                    if dist_from_spawn_sqr < (spawn_fade_dist * spawn_fade_dist) then
                        distance_fade = clamp(sqrt(dist_from_spawn_sqr) / spawn_fade_dist, 0, 1)
                    else
                        distance_fade = 1
                    end
                    
                    local fade_alpha = clamp(time_fade + distance_fade * 0.5, 0, 1)
                    
                    local spawn_influence = 1.0 - fade_alpha
                    local motion_influence = fade_alpha
                    
                    if p_data.old_pos then
                        tail_end = (visual_spawn_pos * spawn_influence) + (tail_end_interpolated * motion_influence)
                    else
                        tail_end = visual_spawn_pos
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
                --print(string.format("%.3f", CurTime() - p_data.spawn_time))

               if effective_spawn_pos then
                    local to_head = tail_start - effective_spawn_pos
                    local traveled_len_sqr = to_head:LengthSqr()
                    
                    if traveled_len_sqr > 1 then
                        local traveled_len = math.sqrt(traveled_len_sqr)
                        local current_tracer_len_sqr = tail_start:DistToSqr(tail_end)
                        
                        if current_tracer_len_sqr > traveled_len_sqr + 0.1 then
                            local backward_dir = to_head:GetNormalized()
                            tail_end = tail_start - (backward_dir * traveled_len)
                        end
                    end
                end

                local beam_length_sqr = distance_to_sqr(tail_start, tail_end);
               if beam_length_sqr > 4.0 then
                    
                    beam_idx = beam_idx + 1;
                    beam_batch[beam_idx] = {tail_start, tail_end, final_size, p_data.tracer_colors[2]};
                end
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