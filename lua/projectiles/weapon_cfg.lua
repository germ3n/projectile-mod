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
}

local WEAPON_BLACKLIST = WEAPON_BLACKLIST;
local WEAPON_SPEEDS = WEAPON_SPEEDS;
local WEAPON_DAMAGES = WEAPON_DAMAGES;

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