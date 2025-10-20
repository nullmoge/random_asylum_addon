if SERVER then
    function GM:LoadPlayerAppearance(ply)
        if not IsValid(ply) then return end

        ply:SetupHands()
    end

    function GM:ChangePlayerModel(ply, model, skin, bodygroups)
        if not IsValid(ply) or not model then return false end

        if not file.Exists(model, "GAME") then
            ply:ChatPrint("Error: Model '" .. model .. "' not found!")
            return false
        end
        
        ply:SetModel(model)
        
        if skin then
            ply:SetSkin(skin)
        end
        
        if bodygroups then
            for id, value in pairs(bodygroups) do
                ply:SetBodygroup(id, value)
            end
        end
        
        ply:SetupHands()
        ply:ChatPrint("Appearance changed and saved!")
        
        return true
    end

    net.Receive("RandomAsylum_ChangeModel", function(len, ply)
        if not IsValid(ply) then return end

        local model = net.ReadString()
        if model and model ~= "" then
            GAMEMODE:ChangePlayerModel(ply, model)
        end
    end)

    hook.Add("PlayerSpawn", "RandomAsylum_LoadAppearance", function(ply)
        GAMEMODE:LoadPlayerAppearance(ply)
    end)
end