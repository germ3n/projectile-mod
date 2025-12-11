AddCSLuaFile();

SURFACE_PROPS_PENETRATION = {
    ["popcan"] = 0.9,
    ["concrete_block"] = 0.35,
    ["unknown"] = 0.5,
    ["grenade"] = 0.5,
    ["wade"] = 0.9,
    ["phx_tire_normal"] = 0.5,
    ["canister"] = 0.35,
    ["paper"] = 0.98,
    ["tile"] = 0.5,
    ["dufflebag_survivalCase"] = 0.75,
    ["woodladder"] = 0.7,
    ["plastic_barrel_buoyant"] = 0.8,
    ["rubbertire"] = 0.6,
    ["rubber"] = 0.7,
    ["metalvehicle"] = 0.25,
    ["wood_panel"] = 0.7,
    ["soccerball"] = 0.95,
    ["weapon_magazine"] = 0.4,
    ["metal_shield"] = 0.4,
    ["wood_basket"] = 0.9,
    ["metaldogtags"] = 0.4,
    ["rock"] = 0.3,
    ["wood_furniture"] = 0.75,
    ["slowgrass"] = 0.65,
    ["slidingrubbertire_jalopyrear"] = 0.85,
    ["hunter"] = 0.75,
    ["slidingrubbertire"] = 0.65,
    ["solidmetal"] = 0.15,
    ["metalpanel"] = 0.35,
    ["gravel"] = 0.5,
    ["tile_survivalcase_gib"] = 0.7,
    ["glassbottle"] = 0.95,
    ["flesh"] = 0.85,
    ["crowbar"] = 0.3,
    ["brass_bell_medium"] = 0.25,
    ["combine_metal"] = 0.2,
    ["foliage"] = 0.95,
    ["wood_plank"] = 0.75,
    ["ladder"] = 0.5,
    ["sugarcane"] = 0.7,
    ["slidingrubbertire_front"] = 0.85,
    ["grate"] = 0.95,
    ["brick"] = 0.4,
    ["brass_bell_smallest"] = 0.35,
    ["chainlink"] = 0.98,
    ["concrete"] = 0.35,
    ["antlionsand"] = 0.5,
    ["dirt"] = 0.6,
    ["gm_ps_metaltire"] = 0.25,
    ["strider"] = 0.2,
    ["upholstery"] = 0.9,
    ["player"] = 0.8,
    ["jeeptire"] = 0.6,
    ["tile_survivalcase"] = 0.5,
    ["zombieflesh"] = 0.85,
    ["ceiling_tile"] = 0.9,
    ["brakingrubbertire"] = 0.85,
    ["gm_torpedo"] = 0.4,
    ["wood_lowdensity"] = 0.8,
    ["slipperyslime"] = 0.6,
    ["slipperyslide"] = 0.27,
    ["plastic_barrel"] = 0.7,
    ["snow"] = 0.7,
    ["player_control_clip"] = 1.0,
    ["blockbullets"] = 0.01,
    ["water"] = 0.9,
    ["ice"] = 0.6,
    ["wood"] = 0.7,
    ["slidingrubbertire_rear"] = 0.85,
    ["metal_bouncy"] = 0.15,
    ["metal_barrellight_hl"] = 0.5,
    ["weapon"] = 0.35,
    ["pottery"] = 0.9,
    ["plaster"] = 0.8,
    ["watermelon"] = 0.9,
    ["phx_ww2bomb"] = 0.2,
    ["jalopy"] = 0.25,
    ["metalgrate"] = 0.95,
    ["default"] = 0.5,
    ["metal_survivalcase_unpunchable"] = 0.4,
    ["chain"] = 0.98,
    ["metal_barrel_hl"] = 0.45,
    ["plastic"] = 0.8,
    ["alienflesh"] = 0.85,
    ["wet"] = 0.95,
    ["hay"] = 0.85,
    ["strongman_bell"] = 0.27,
    ["wood_box"] = 0.75,
    ["no_decal"] = 1.0,
    ["slidingrubbertire_jalopyfront"] = 0.85,
    ["clay"] = 0.95,
    ["gmod_ice"] = 0.6,
    ["combine_glass"] = 0.95,
    ["gm_ps_woodentire"] = 0.7,
    ["metal_vehicle"] = 0.4,
    ["papercup"] = 0.98,
    ["gunship"] = 0.2,
    ["mud"] = 0.55,
    ["cement"] = 0.35,
    ["plastic_barrel_verybuoyant"] = 0.9,
    ["phx_explosiveball"] = 0.2,
    ["cavern_rock"] = 0.3,
    ["wood_crate"] = 0.75,
    ["antlion"] = 0.75,
    ["gmod_bouncy"] = 0.6,
    ["slipperymetal"] = 0.35,
    ["gm_ps_egg"] = 0.9,
    ["sheetrock"] = 0.8,
    ["sand"] = 0.5,
    ["metal_barrel_exploding"] = 0.5,
    ["roller"] = 0.5,
    ["grass"] = 0.65,
    ["metal_box"] = 0.4,
    ["bloodyflesh"] = 0.85,
    ["stucco"] = 0.5,
    ["wood_dense"] = 0.5,
    ["floating_metal_barrel"] = 0.45,
    ["carpet"] = 0.9,
    ["plastic_survivalcase"] = 0.75,
    ["floatingstandable"] = 0.6,
    ["plastic_box"] = 0.8,
    ["cardboard"] = 0.95,
    ["metalvent"] = 0.6,
    ["wood_solid"] = 0.6,
    ["metal_survivalcase"] = 0.4,
    ["brass_bell_large"] = 0.2,
    ["default_silent"] = 1.0,
    ["porcelain"] = 0.9,
    ["asphalt"] = 0.4,
    ["armorflesh"] = 0.5,
    ["boulder"] = 0.25,
    ["slime"] = 0.8,
    ["glassfloor"] = 0.98,
    ["metal_sand_barrel"] = 0.01,
    ["computer"] = 0.5,
    ["metal_barrel"] = 0.4,
    ["glass"] = 0.98,
    ["phx_flakshell"] = 0.2,
    ["paintcan"] = 0.85,
    ["item"] = 0.7,
    ["metal"] = 0.35,
    ["jalopytire"] = 0.6,
    ["quicksand"] = 0.4,
    ["puddle"] = 0.95,
    ["brass_bell_small"] = 0.3,
};

if SERVER then
    util.AddNetworkString("projectile_surfaceprop_sync");
    util.AddNetworkString("projectile_surfaceprop_update");

    local function initialize_db()
        if not sql.TableExists("surface_props_data") then
            local res = sql.Query("CREATE TABLE surface_props_data (key TEXT PRIMARY KEY, value FLOAT)");
            if res == false then
                print("sql error creating surfaceprops table: " .. sql.LastError());
            end
        else
            local data = sql.Query("SELECT * FROM surface_props_data");
            if data then
                for idx, row in ipairs(data) do
                    local key = row.key;
                    local val = tonumber(row.value);
                    
                    if SURFACE_PROPS_PENETRATION[key] then
                        SURFACE_PROPS_PENETRATION[key] = val;
                        print("loaded surfaceprop: " .. key .. " -> " .. val);
                    end
                end
                print("loaded " .. #data .. " surfaceprops from database.");
            end
        end
    end

    local function save_surface_prop_to_db(key, val)
        local safe_key = sql.SQLStr(key);
        local safe_val = val;
        
        local query = "REPLACE INTO surface_props_data (key, value) VALUES(" .. safe_key .. ", " .. safe_val .. ")";
        local res = sql.Query(query);
        
        if res == false then
            print("sql error saving surfaceprop: " .. key .. ": " .. sql.LastError());
        end
    end

    local function remove_surface_prop_from_db(key)
        local safe_key = sql.SQLStr(key);
        local query = "DELETE FROM surface_props_data WHERE key = " .. safe_key;
        local res = sql.Query(query);
        
        if res == false then
            print("sql error removing surfaceprop: " .. key .. ": " .. sql.LastError());
        end
    end

    hook.Add("PlayerInitialSpawn", "projectile_surfaceprop_full_sync", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            net.Start("projectile_surfaceprop_sync");
            net.WriteTable(SURFACE_PROPS_PENETRATION);
            net.Send(ply);
        end)
    end)

    net.Receive("projectile_surfaceprop_update", function(len, ply)
        if not IsValid(ply)then 
            return;
        elseif not ply:IsSuperAdmin() then
            ply:ChatPrint("You are not authorized to use this command.");
            return;
        end

        local prop_name = net.ReadString();
        local prop_val = net.ReadFloat();

        if SURFACE_PROPS_PENETRATION[prop_name] then
            print("updated surfaceprop: " .. prop_name .. " -> " .. prop_val);
            
            SURFACE_PROPS_PENETRATION[prop_name] = prop_val;
            save_surface_prop_to_db(prop_name, prop_val);

            net.Start("projectile_surfaceprop_update");
            net.WriteString(prop_name);
            net.WriteFloat(prop_val);
            net.Broadcast();
        end
    end);

    concommand.Add("pro_surfaceprop_list", function()
        PrintTable(SURFACE_PROPS_PENETRATION);
    end, nil, "List all surfaceprops");

    local SURFACE_PROPS_ORIGINAL = table.Copy(SURFACE_PROPS_PENETRATION);
    local NULL = NULL;

    local player_meta = FindMetaTable("Player");
    local is_superadmin = player_meta.IsSuperAdmin;
    
    concommand.Add("pro_surfaceprop_reset_single", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        local prop_name = args[1];
        if SURFACE_PROPS_PENETRATION[prop_name] then
            SURFACE_PROPS_PENETRATION[prop_name] = SURFACE_PROPS_ORIGINAL[prop_name];
            remove_surface_prop_from_db(prop_name);

            net.Start("projectile_surfaceprop_update");
            net.WriteString(prop_name);
            net.WriteFloat(SURFACE_PROPS_ORIGINAL[prop_name]);
            net.Broadcast();
        end

        print("reset surfaceprop: " .. prop_name .. " to " .. SURFACE_PROPS_ORIGINAL[prop_name]);
    end, nil, "Reset a single surfaceprop");

    concommand.Add("pro_surfaceprop_reset_all", function(ply, cmd, args)
        if ply ~= NULL and (not is_superadmin(ply)) then return; end
        sql.Query("DELETE FROM surface_props_data");
        table.CopyFromTo(SURFACE_PROPS_ORIGINAL, SURFACE_PROPS_PENETRATION);

        net.Start("projectile_surfaceprop_sync");
        net.WriteTable(SURFACE_PROPS_PENETRATION);
        net.Broadcast();

        print("reset all surfaceprops");
    end, nil, "Reset all surfaceprops");

    initialize_db();
    
    print("loaded surfaceprop sql");
end

if CLIENT then
    net.Receive("projectile_surfaceprop_sync", function()
        table.CopyFromTo(net.ReadTable(), SURFACE_PROPS_PENETRATION);
        print("received full surfaceprop sync");
    end);

    net.Receive("projectile_surfaceprop_update", function()
        local prop_name = net.ReadString();
        local prop_val = net.ReadFloat();
        SURFACE_PROPS_PENETRATION[prop_name] = prop_val;
        print("updated surfaceprop " .. prop_name .. " to " .. prop_val);
    end);
end