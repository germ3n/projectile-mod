AddCSLuaFile();

local projectiles = projectiles;

local vector_meta = FindMetaTable("Vector");
local vector = Vector;

local MASK_SHOT_HULL = 0x600400B;
local CONTENTS_HITBOX = 0x40000000;
local MASK_TRACE = 0x4600400B;
local SURF_HITBOX = 0x8000

local trace_line_ex = util.TraceLine;
local point_contents = util.PointContents;
local band = bit.band;
local is_valid = IsValid;

local projectile_trace_config = {
    start = vector(0, 0, 0),
    endpos = vector(0, 0, 0),
    mask = MASK_TRACE,
    filter = {},
};

function trace_to_exit(enter_trace, start_pos, dir, mins, maxs, shooter)
    local dist = 0;
    local first_contents = 0;
    
    while dist <= 90 do
        dist = dist + 4.0;
        local check_pos = start_pos + (dir * dist);

        if first_contents == 0 then
            first_contents = point_contents(check_pos);
        end

        local current_contents = point_contents(check_pos);

        if (band(current_contents, MASK_SHOT_HULL) == 0) or (band(current_contents, CONTENTS_HITBOX) ~= 0 and current_contents ~= first_contents) then
            local exit_trace = trace_line_ex({
                start = check_pos,
                endpos = check_pos - (dir * 4.0),
                mask = MASK_SHOT_HULL,
                filter = shooter,
                mins = mins,
                maxs = maxs
            });

            if exit_trace.StartSolid and band(exit_trace.SurfaceFlags, SURF_HITBOX) ~= 0 then
                local box_trace = trace_line_ex({
                    start = check_pos,
                    endpos = start_pos,
                    mask = MASK_SHOT_HULL,
                    filter = exit_trace.Entity,
                    mins = mins,
                    maxs = maxs
                });

                if (box_trace.Fraction < 1.0 or box_trace.AllSolid) and not box_trace.StartSolid then
                    return box_trace.HitPos, box_trace;
                end
                
                goto _continue;
            end

            if not (exit_trace.Fraction < 1.0 or exit_trace.AllSolid or exit_trace.StartSolid) or exit_trace.StartSolid then
                if enter_trace.Entity and is_valid(enter_trace.Entity) then
                    local class = enter_trace.Entity:GetClass();
                    if class:find("func_breakable") or class:find("prop_physics") then
                        return start_pos + dir, enter_trace;
                    end
                end
                goto _continue;
            end

            if band(exit_trace.SurfaceFlags, 0x80) ~= 0 then -- NODRAW
                if band(enter_trace.SurfaceFlags, 0x80) ~= 0 then
                    return check_pos, exit_trace;
                end
            end

            if exit_trace.HitNormal:Dot(dir) <= 1.0 then
                return exit_trace.HitPos, exit_trace;
            end
        end
        
        ::_continue::
    end

    return nil, nil;
end

function projectile_move_trace(start, endpos, ignore_ents)
    projectile_trace_config.start = start;
    projectile_trace_config.endpos = endpos;
    projectile_trace_config.filter = ignore_ents;

    return trace_line_ex(projectile_trace_config);
end

print("loaded projectiles ray");