-- hack for shellshock
-- workshop id: https://steamcommunity.com/sharedfiles/filedetails/?id=695625896
-- just reimplemented part of the code so credits to them

local next = next;
local distance_to_line = util.DistanceToLine;
local clamp = math.Clamp;
local net_start = net.Start;
local net_send = net.Send;
local timer_create = timer.Create;
local random = math.random;
local angle = Angle;
local is_valid = IsValid;
local max = math.max;
local player_iterator = player.Iterator;

local entity_meta = FindMetaTable("Entity");
local get_nw_float = entity_meta.GetNWFloat;
local set_nw_float = entity_meta.SetNWFloat;
local eye_pos = entity_meta.EyePos;
local ent_index = entity_meta.EntIndex; 

local player_meta = FindMetaTable("Player");
local view_punch = player_meta.ViewPunch;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;

local SHOCK_DISTANCE = 30;
local MAX_SHOCK = 10;

local cv_shell_fadespeed = nil;-- = GetConVar("shell_fadespeed");
local cv_shell_enabled = nil;-- = GetConVar("shell_enabled");

local shellshock_backup = nil;
local shellshock_patched = false;

function fx_patch_shellshock(enable)
    if not shellshock_backup then
        return;
    end
        
    if enable then
        hook.Add("EntityFireBullets", "ShellshockGettingBullets", shellshock_backup);
        shellshock_patched = false;
    else
        hook.Remove("EntityFireBullets", "ShellshockGettingBullets");
        shellshock_patched = true;
    end
end

function do_shellshock(shooter, start_pos, end_pos, damage)
    if not cv_shell_enabled or not get_bool(cv_shell_enabled) then return; end
    --print(shooter, start_pos, end_pos, damage);

    for idx, ply in player_iterator() do
        if ply == shooter then continue; end
        
        local dist = distance_to_line(start_pos, end_pos, eye_pos(ply));
        if dist <= SHOCK_DISTANCE then
            local shock = clamp(get_nw_float(ply, "ShellshockLevel", 0.0) + ((SHOCK_DISTANCE - dist) / SHOCK_DISTANCE) * (1 + damage / 750), 0, MAX_SHOCK);
            set_nw_float(ply, "ShellshockLevel", shock);

            net_start("ShotAt");
            net_send(ply);

            view_punch(ply, angle(random(-1, 1) / (MAX_SHOCK + 1 - shock), random(-1, 1) / (MAX_SHOCK + 1 - shock), random(-1, 1) / (MAX_SHOCK + 1 - shock)));

            timer_create("Shellshock" .. ent_index(ply), 0.25, 0, function()
                if not is_valid(ply) then return; end
                local shock = max(get_nw_float(ply, "ShellshockLevel", 0.0) - get_float(cv_shell_fadespeed), 0.0);
                set_nw_float(ply, "ShellshockLevel", shock);
            end);
        end
    end
end

timer.Create("projectiles_hack_shellshock", 3, 0, function()
    if not cv_shell_fadespeed then cv_shell_fadespeed = GetConVar("shell_fadespeed"); end
    if not cv_shell_enabled then cv_shell_enabled = GetConVar("shell_enabled"); end

    if not shellshock_backup and hook.GetTable()["EntityFireBullets"] then
        shellshock_backup = hook.GetTable()["EntityFireBullets"]["ShellshockGettingBullets"];
    end

    if not shellshock_backup then
        return;
    end

    if projectiles["pro_projectiles_enabled"] then
        if not shellshock_patched then
            hook.Remove("EntityFireBullets", "ShellshockGettingBullets");
            shellshock_patched = true;
            print("patched shellshock");
        end
    else
        if shellshock_patched then
            hook.Add("EntityFireBullets", "ShellshockGettingBullets", shellshock_backup);
            shellshock_patched = false;
            print("unpatched shellshock");
        end
    end
end);

print("loaded shellshock hack");