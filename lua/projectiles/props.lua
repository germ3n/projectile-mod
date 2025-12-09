AddCSLuaFile();

if SERVER then
    hook.Add("OnEntityCreated", "projectiles_props", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return; end
            if ent:GetClass() ~= "prop_physics" then return; end
            if not ent:GetModel() then return; end
            ent:PrecacheGibs();
            print("precached gibs for " .. ent:GetModel());
        end);
    end);
end 

print("loaded projectiles props");