AddCSLuaFile();

WEAPON_BLACKLIST = {
};

WEAPON_SPEEDS = {
    ["weapon_pistol"] = function(weapon) return 2000 end,
    ["weapon_357"] = function(weapon) return 500 end,
    ["weapon_shotgun"] = function(weapon) return 2000 end,
    ["weapon_smg1"] = function(weapon) return 2000 end,
    ["weapon_ar2"] = function(weapon) return 2000 end,
    ["default"] = function(weapon) return 2000 end,
};

WEAPON_DAMAGES = {
    ["weapon_pistol"] = function(weapon, damage) return 10 end,
    ["weapon_357"] = function(weapon, damage) return 80 end,
    ["weapon_shotgun"] = function(weapon, damage) return 8 end,
    ["weapon_smg1"] = function(weapon, damage) return 20 end,
    ["weapon_ar2"] = function(weapon, damage) return 30 end,
    ["default"] = function(weapon, damage) return damage end,
};

local zero_vec = Vector(0, 0, 0);
local rand = math.Rand;
local abs = math.abs;

local angle_meta = FindMetaTable("Angle");
local right = angle_meta.Right;
local up = angle_meta.Up;

local vector_meta = FindMetaTable("Vector");
local angle = vector_meta.Angle;

local function calc_spread(weapon, dir, spread, bias)
    if spread == zero_vec then
        return dir;
    end

    bias = bias or 1.0;
    local flatness = abs(bias * 0.5);
    local final_spread_x, final_spread_y;
    local angle_dir = angle(dir);
    local vec_right = right(angle_dir);
    local vec_up = up(angle_dir);

    repeat
        final_spread_x = rand(-1, 1) * flatness + rand(-1, 1) * (1.0 - flatness);
        final_spread_y = rand(-1, 1) * flatness + rand(-1, 1) * (1.0 - flatness);
        if bias < 0.0 then
            final_spread_x = final_spread_x >= 0.0 and 1.0 - final_spread_x or -1.0 -final_spread_x;
            final_spread_y = final_spread_y >= 0.0 and 1.0 - final_spread_y or -1.0 -final_spread_y;
        end
    until (final_spread_x * final_spread_x + final_spread_y * final_spread_y) <= 1.0;

    local final_dir = dir + (final_spread_x * spread.x * vec_right) + (final_spread_y * spread.y * vec_up);
    return final_dir;
end

SPREAD_VALUES = {
    ["default"] = calc_spread,
    ["weapon_shotgun"] = function(weapon, dir, spread, bias)
        return calc_spread(weapon, dir, spread, 0.0);
    end,
};

local WEAPON_BLACKLIST = WEAPON_BLACKLIST;
local WEAPON_SPEEDS = WEAPON_SPEEDS;
local WEAPON_DAMAGES = WEAPON_DAMAGES;
local SPREAD_VALUES = SPREAD_VALUES;

function get_weapon_speed(weapon, class_name)
    local speed_func = WEAPON_SPEEDS[class_name];
    if speed_func then return speed_func(weapon); end

    return WEAPON_SPEEDS["default"](weapon);
end

function get_weapon_damage(weapon, class_name, damage)
    local damage_func = WEAPON_DAMAGES[class_name];
    if damage_func then return damage_func(weapon, damage); end

    return WEAPON_DAMAGES["default"](weapon, damage);
end

function get_weapon_spread(weapon, class_name, dir, spread, bias)
    local spread_func = SPREAD_VALUES[class_name];
    if spread_func then return spread_func(weapon, dir, spread, bias); end

    return SPREAD_VALUES["default"](weapon, dir, spread, bias);
end