AddCSLuaFile();

local projectiles = projectiles;
local next = next;
local PROJECTILES_CVARS = PROJECTILES_CVARS;

local convar_meta = FindMetaTable("ConVar");
local get_bool = convar_meta.GetBool;
local get_float = convar_meta.GetFloat;
local get_int = convar_meta.GetInt;
local get_string = convar_meta.GetString;

local get_funcs = {
    ["bool"] = get_bool,
    ["float"] = get_float,
    ["int"] = get_int,
    ["string"] = get_string,
};

for cvar_name, cvar_data in next, PROJECTILES_CVARS do
    local cvar = cvar_data[1];
    local cvar_type = cvar_data[2];
    projectiles[cvar_name] = get_funcs[cvar_type](cvar);
end

if SERVER then
    util.AddNetworkString("projectiles_cache_update");

    local net_start = net.Start;
    local write_bool = net.WriteBool;
    local write_float = net.WriteFloat;
    local write_int = net.WriteInt;
    local write_string = net.WriteString;
    local broadcast = net.Broadcast;

    local write_funcs = {
        ["bool"] = write_bool,
        ["float"] = write_float,
        ["int"] = function(val) write_int(val, 32); end,
        ["string"] = write_string,
    };

    local function change_callback(cvar_name, old_value, new_value)
        local cvar_data = PROJECTILES_CVARS[cvar_name];
        if not cvar_data then return; end

        local cvar = cvar_data[1];
        local cvar_type = cvar_data[2];
        local value = get_funcs[cvar_type](cvar);
        projectiles[cvar_name] = value;

        net_start("projectiles_cache_update");
        write_string(cvar_name);
        write_funcs[cvar_type](value);
        broadcast();
    end

    local IGNORE_CVARS = {
        ["pro_render_enabled"] = true,
        ["pro_render_min_distance"] = true,
        ["pro_spawn_fade_distance"] = true,
        ["pro_spawn_fade_time"] = true,
        ["pro_spawn_offset"] = true,
        ["pro_spawn_offset_max_dist"] = true,
        ["pro_min_trail_length"] = true,
        ["pro_distance_scale_enabled"] = true,
        ["pro_distance_scale_start"] = true,
        ["pro_distance_scale_max"] = true,
        ["pro_render_wind_hud"] = true,
        ["pro_max_interp_distance"] = true,
        ["pro_max_interp_camera_distance"] = true,
    };

    for cvar_name, cvar_data in next, PROJECTILES_CVARS do
        if IGNORE_CVARS[cvar_name] then continue; end
        cvars.AddChangeCallback(cvar_name, change_callback, "projectiles_cache");
    end
end

if CLIENT then
    local read_bool = net.ReadBool;
    local read_float = net.ReadFloat;
    local read_int = net.ReadInt;
    local read_string = net.ReadString;

    local read_funcs = {
        ["bool"] = read_bool,
        ["float"] = read_float,
        ["int"] = function() return read_int(32); end,
        ["string"] = read_string,
    };

    net.Receive("projectiles_cache_update", function()
        local cvar_name = read_string();
        local cvar_data = PROJECTILES_CVARS[cvar_name];
        if not cvar_data then return; end

        local cvar_type = cvar_data[2];
        projectiles[cvar_name] = read_funcs[cvar_type]();

        LocalPlayer():ChatPrint("Updated " .. cvar_name .. " to " .. tostring(projectiles[cvar_name]));
    end);
end

print("loaded projectiles cache");