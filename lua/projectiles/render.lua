AddCSLuaFile();

local projectiles = projectiles;

if SERVER then return; end

local projectile_store = projectile_store;
local next = next;
local cur_time = CurTime;
local rand = math.Rand;
local sin = math.sin;
local clamp = math.Clamp;
local set_material = render.SetMaterial;
local draw_sprite = render.DrawSprite;
local draw_beam = render.DrawBeam;

local mat_glow = Material("sprites/light_glow02_add");
local mat_beam = Material("effects/laser1");

local col_core = Color(255, 200, 100, 255);
local col_glow = Color(255, 140, 0, 150);

local function render_projectiles()
    local cur_time = cur_time();
    local pulse_wave = sin(cur_time * 20) * 0.35 + 1.15;
    local flicker = rand(0.9, 1.1);
    local scale_mod = pulse_wave * flicker;

    set_material(mat_glow);

    for shooter, projs in next, projectile_store do
        local projectile_idx = projs.last_received_idx;
        local buffer_size = projs.buffer_size;
        local loop_idx = 0;

        while loop_idx < buffer_size do
            local p_data = projs.buffer[projectile_idx];

            if p_data and not p_data.hit and p_data.penetration_count > 0 and p_data.damage >= 1.0 then
                local base_size = clamp(p_data.damage * 0.05, 5, 20);
                local final_size = base_size * scale_mod;

                set_material(mat_glow);
                draw_sprite(p_data.pos, final_size, final_size, col_core);
                draw_sprite(p_data.pos, final_size * 1.5, final_size * 1.5, col_glow);

                local velocity = p_data.dir * p_data.speed;
                local tail_length = 0.03;
                local tail_end = p_data.pos - (velocity * tail_length);

                set_material(mat_beam);
                draw_beam(p_data.pos, tail_end, final_size * 0.5, 0, 1, col_glow);
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