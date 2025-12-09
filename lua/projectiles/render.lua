AddCSLuaFile();

local projectiles = projectiles;

if SERVER then return; end

local projectile_store = projectile_store;
local next = next;
local cur_time = CurTime;
local unpredicted_cur_time = UnPredictedCurTime;
local tick_interval = engine.TickInterval();
local tick_count = engine.TickCount;
local rand = math.Rand;
local sin = math.sin;
local clamp = math.Clamp;
local lerp_vector = LerpVector;
local set_material = render.SetMaterial;
local draw_sprite = render.DrawSprite;
local draw_beam = render.DrawBeam;

local mat_glow = Material("sprites/light_glow02_add");
local mat_beam = Material("effects/laser1");

local col_core = Color(255, 200, 100, 255);
local col_glow = Color(255, 140, 0, 150);

local function render_projectiles()
    local cur_time_val = tick_count() * tick_interval;
    local real_time = unpredicted_cur_time();

    local pulse_wave = sin(real_time * 20) * 0.35 + 1.15;
    local flicker = rand(0.9, 1.1);
    local scale_mod = pulse_wave * flicker;

    local time_since_tick = real_time - cur_time_val;
    local interp_fraction = time_since_tick / tick_interval;--clamp(time_since_tick / tick_interval, 0, 1);

    if interp_fraction > 3.0 then interp_fraction = 3.0; end

    --print(cur_time_val, real_time, time_since_tick, tick_interval, interp_fraction);
    
    for shooter, projs in next, projectile_store do
        local projectile_idx = projs.last_received_idx;
        local buffer_size = projs.buffer_size;
        local loop_idx = 0;

        while loop_idx < buffer_size do
            local p_data = projs.buffer[projectile_idx];
            if p_data and not p_data.hit and p_data.penetration_count > 0 and p_data.damage >= 1.0 then
                local render_pos = p_data.pos;
                if p_data.old_pos then
                    render_pos = lerp_vector(interp_fraction, p_data.old_pos, p_data.pos);
                end

                local base_size = clamp(p_data.damage * 0.05, 5, 20);
                local final_size = base_size * scale_mod;

                set_material(mat_glow);
                draw_sprite(render_pos, final_size, final_size, col_core);
                draw_sprite(render_pos, final_size * 1.5, final_size * 1.5, col_glow);

                local velocity = p_data.dir * p_data.speed;
                local tail_length = 0.03;
                local tail_end = render_pos - (velocity * tail_length);

                set_material(mat_beam);
                draw_beam(render_pos, tail_end, final_size * 0.5, 0, 1, col_glow);
            end

            if projectile_idx == 1 then 
                projectile_idx = buffer_size;
            else
                projectile_idx = projectile_idx - 1;
            end

            loop_idx = loop_idx + 1;
        end
    end
end

hook.Add("PostDrawTranslucentRenderables", "projectiles_render", function(drawing_depth, drawing_skybox)
    if drawing_skybox or drawing_depth then return; end
    render_projectiles();
end);

print("loaded projectiles render");