AddCSLuaFile();

SURFACE_PROPS_PENETRATION = {
    ["default"] = 1.0,
    ["default_silent"] = 1.0,
    ["player"] = 1.0,
    ["player_control_clip"] = 1.0,
    ["no_decal"] = 1.0,
    ["solidmetal"] = 0.27,
    ["metal"] = 0.4,
    ["metal_barrel"] = 0.5,
    ["metal_vehicle"] = 0.4,
    ["metal_survivalCase"] = 0.4,
    ["metal_survivalCase_unpunchable"] = 0.4,
    ["metaldogtags"] = 0.4,
    ["metalgrate"] = 0.95,
    ["Metal_Box"] = 0.5,
    ["metal_bouncy"] = 0.27,
    ["slipperymetal"] = 0.4,
    ["grate"] = 0.95,
    ["metalvent"] = 0.6,
    ["metalpanel"] = 0.5,
    ["canister"] = 0.5,
    ["metal_barrel_exploding"] = 0.5,
    ["floating_metal_barrel"] = 0.5,
    ["roller"] = 0.5,
    ["popcan"] = 0.5,
    ["paintcan"] = 0.5,
    ["slipperyslide"] = 0.27,
    ["strongman_bell"] = 0.27,
    ["grenade"] = 0.5,
    ["weapon"] = 0.4,
    ["metal_shield"] = 0.4,
    ["metalvehicle"] = 0.5,
    ["metal_sand_barrel"] = 0.01,
    ["jalopy"] = 0.4,
    ["brass_bell_large"] = 1.0,
    ["brass_bell_medium"] = 1.0,
    ["brass_bell_small"] = 1.0,
    ["brass_bell_smallest"] = 1.0,
    ["computer"] = 0.4,
    ["weapon_magazine"] = 0.4,
    ["ladder"] = 0.4,
    ["chainlink"] = 0.99,
    ["chain"] = 0.99,
    ["dirt"] = 0.6,
    ["mud"] = 0.6,
    ["slipperyslime"] = 0.6,
    ["grass"] = 0.6,
    ["slowgrass"] = 0.6,
    ["sugarcane"] = 0.6,
    ["sand"] = 0.3,
    ["gravel"] = 0.4,
    ["foliage"] = 0.95,
    ["floatingstandable"] = 0.6,
    ["water"] = 0.3,
    ["wet"] = 1.0,
    ["puddle"] = 1.0,
    ["slime"] = 1.0,
    ["quicksand"] = 0.2,
    ["wade"] = 0.3,
    ["Wood"] = 0.9,
    ["Wood_lowdensity"] = 0.9,
    ["Wood_Box"] = 0.9,
    ["Wood_Basket"] = 0.9,
    ["Wood_Crate"] = 0.9,
    ["Wood_Plank"] = 0.85,
    ["Wood_Solid"] = 0.8,
    ["Wood_Furniture"] = 0.9,
    ["Wood_Panel"] = 0.9,
    ["Wood_Dense"] = 0.5,
    ["woodladder"] = 0.9,
    ["tile"] = 0.7,
    ["tile_survivalCase"] = 0.7,
    ["tile_survivalCase_GIB"] = 0.7,
    ["clay"] = 0.95,
    ["ceiling_tile"] = 0.95,
    ["glass"] = 0.99,
    ["glassfloor"] = 0.99,
    ["glassbottle"] = 0.99,
    ["pottery"] = 0.95,
    ["concrete"] = 0.5,
    ["asphalt"] = 0.55,
    ["rock"] = 0.5,
    ["porcelain"] = 0.95,
    ["boulder"] = 0.5,
    ["brick"] = 0.47,
    ["concrete_block"] = 0.5,
    ["stucco"] = 0.5,
    ["flesh"] = 0.9,
    ["bloodyflesh"] = 0.9,
    ["alienflesh"] = 0.9,
    ["armorflesh"] = 0.5,
    ["watermelon"] = 0.95,
    ["carpet"] = 0.75,
    ["dufflebag_survivalCase"] = 0.75,
    ["upholstery"] = 0.75,
    ["rubber"] = 0.85,
    ["rubbertire"] = 0.85,
    ["jeeptire"] = 0.85,
    ["jalopytire"] = 0.85,
    ["slidingrubbertire"] = 0.85,
    ["brakingrubbertire"] = 0.85,
    ["slidingrubbertire_front"] = 0.85,
    ["slidingrubbertire_rear"] = 0.85,
    ["slidingrubbertire_jalopyfront"] = 0.85,
    ["slidingrubbertire_jalopyrear"] = 0.85,
    ["soccerball"] = 1.0,
    ["plaster"] = 0.7,
    ["sheetrock"] = 0.85,
    ["cardboard"] = 0.95,
    ["paper"] = 0.95,
    ["papercup"] = 0.95,
    ["plastic_barrel"] = 0.7,
    ["plastic_barrel_buoyant"] = 0.7,
    ["Plastic_Box"] = 0.75,
    ["plastic"] = 0.75,
    ["plastic_survivalCase"] = 0.75,
    ["item"] = 0.75,
    ["ice"] = 0.75,
    ["snow"] = 0.85,
    ["blockbullets"] = 0.01
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

    initialize_db();

    hook.Add("PlayerInitialSpawn", "projectile_surfaceprop_full_sync", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            net.Start("projectile_surfaceprop_sync");
            net.WriteTable(SURFACE_PROPS_PENETRATION);
            net.Send(ply);
        end)
    end)

    net.Receive("projectile_surfaceprop_update", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then 
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
    end)
    
    print("loaded surfaceprop sql");
end

if CLIENT then
    net.Receive("projectile_surfaceprop_sync", function()
        SURFACE_PROPS_PENETRATION = net.ReadTable();
        print("received full surfaceprop sync");
    end)

    net.Receive("projectile_surfaceprop_update", function()
        local prop_name = net.ReadString();
        local prop_val = net.ReadFloat();
        SURFACE_PROPS_PENETRATION[prop_name] = prop_val;
        print("updated surfaceprop " .. prop_name .. " to " .. prop_val);
    end)

    local function open_editor()
        local frame = vgui.Create("DFrame");
        frame:SetSize(400, 600);
        frame:Center();
        frame:SetTitle("Surface Prop Penetration Editor");
        frame:MakePopup();

        local search = vgui.Create("DTextEntry", frame);
        search:Dock(TOP);
        search:SetPlaceholderText("Search...");
        
        local scroll = vgui.Create("DScrollPanel", frame);
        scroll:Dock(FILL);

        local list_layout = vgui.Create("DListLayout", scroll);
        list_layout:Dock(FILL);

        local sorted_keys = {};
        for k, v in pairs(SURFACE_PROPS_PENETRATION) do
            table.insert(sorted_keys, k);
        end
        table.sort(sorted_keys);

        local function populate_list(filter)
            list_layout:Clear();

            for idx, key in ipairs(sorted_keys) do
                if filter and not string.find(string.lower(key), string.lower(filter), 1, true) then
                    continue;
                end

                local panel = list_layout:Add("DPanel");
                panel:SetTall(40);
                panel:SetBackgroundColor(Color(40, 40, 40));
                panel:DockPadding(5, 0, 5, 0);
                panel:DockMargin(0, 0, 0, 2);

                local label = vgui.Create("DLabel", panel);
                label:SetText(key);
                label:SetFont("DermaDefaultBold");
                label:SetTextColor(color_white);
                label:Dock(LEFT);
                label:SetWide(150);

                local slider = vgui.Create("DNumSlider", panel);
                slider:Dock(FILL);
                slider:SetMin(0);
                slider:SetMax(1.0);
                slider:SetDecimals(2);
                slider:SetValue(SURFACE_PROPS_PENETRATION[key]);
                
                local function send_update()
                    if not LocalPlayer():IsSuperAdmin() then return; end
                    net.Start("projectile_surfaceprop_update");
                    net.WriteString(key);
                    net.WriteFloat(math.Round(slider:GetValue(), 2));
                    net.SendToServer();
                end

                slider.Think = function(s)
                    local isInteracting = s.Slider:GetDragging() or s.TextArea:IsEditing();
                    if isInteracting then
                        s.HasChanged = true;
                    elseif s.HasChanged then
                        s.HasChanged = false;
                        send_update();
                    end
                end

                slider.TextArea.OnEnter = function()
                    send_update();
                    slider.HasChanged = false;
                end
            end
        end

        populate_list();

        search.OnChange = function(s)
            populate_list(s:GetValue());
        end
    end

    concommand.Add("pro_surfaceprops", function()
        if not LocalPlayer():IsSuperAdmin() then
            chat.AddText(Color(255, 50, 50), "You must be a SuperAdmin to use this menu.");
            return;
        end
        open_editor();
    end)
end