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
local set_blend = render.SetBlend;

local mat_glow = Material("sprites/light_glow02_add");
local mat_beam = Material("effects/laser1");

local entity_meta = FindMetaTable("Entity");
local entindex = entity_meta.EntIndex;
local is_valid = IsValid;

local cv_render_enabled = GetConVar("pro_render_enabled");

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;

local function render_projectiles()
    if not get_bool(cv_render_enabled) then return; end
    local cur_time_val = tick_count() * tick_interval;
    local real_time = unpredicted_cur_time();

    local time_since_tick = real_time - cur_time_val;
    local interp_fraction = time_since_tick / tick_interval;--clamp(time_since_tick / tick_interval, 0, 1);

    if interp_fraction > 3.0 then interp_fraction = 3.0; end

    --print(cur_time_val, real_time, time_since_tick, tick_interval, interp_fraction);

    --randomseed(real_time * 1000);

    for shooter, projs in next, projectile_store do
        if not is_valid(shooter) then continue; end

        local idx = 1;
        local active_projectile_count = #projectile_store[shooter].active_projectiles;
        local shooter_entindex = entindex(shooter) * 13;

        for idx = 1, active_projectile_count do
            local p_data = projectile_store[shooter].active_projectiles[idx];
            --if p_data and not p_data.hit and p_data.penetration_count > 0 and p_data.damage >= 1.0 then
                local pulse_offset = shooter_entindex + idx;
                local pulse_wave = sin(real_time * 20 + pulse_offset) * 0.35 + 1.15;
                local flicker = rand(0.8, 1.2);
                local scale_mod = pulse_wave * flicker;

                local render_pos = p_data.pos;
                if p_data.old_pos then
                    render_pos = lerp_vector(interp_fraction, p_data.old_pos, p_data.pos);
                end

                local base_size = clamp(p_data.damage * 0.05, 5, 20);
                local final_size = base_size * scale_mod;

                set_material(mat_glow);
                set_blend(p_data.tracer_colors[1].a / 255.0);
                draw_sprite(render_pos, final_size, final_size, p_data.tracer_colors[1]);
                draw_sprite(render_pos, final_size * 1.5, final_size * 1.5, p_data.tracer_colors[2]);

                local velocity = p_data.dir * p_data.speed;
                local tail_length = 0.03;
                local tail_end = render_pos - (velocity * tail_length);

                set_material(mat_beam);
                set_blend(p_data.tracer_colors[2].a / 255.0);
                draw_beam(render_pos, tail_end, final_size * 0.5, 0, 1, p_data.tracer_colors[2]);
            --end
        end

        set_blend(1.0);
    end
end

hook.Add("PostDrawTranslucentRenderables", "projectiles_render", function(drawing_depth, drawing_skybox)
    if drawing_skybox or drawing_depth then return; end
    render_projectiles();
end);

print("loaded projectiles render");