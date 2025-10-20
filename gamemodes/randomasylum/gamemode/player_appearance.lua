if SERVER then
    local function GetPlayerModelPool()
        local pool = {}
        local raw = list.Get("PlayerOptionsModel") or {}

        for k, v in pairs(raw) do
            if isstring(k) and k:find("%.mdl$") then
                table.insert(pool, k)
            else
                if isstring(v) and v:find("%.mdl$") then
                    table.insert(pool, v)
                elseif istable(v) then
                    if isstring(v.model) and v.model:find("%.mdl$") then
                        table.insert(pool, v.model)
                    else
                        for _, maybe in pairs(v) do
                            if isstring(maybe) and maybe:find("%.mdl$") then
                                table.insert(pool, maybe)
                            end
                        end
                    end
                end
            end
        end

        local seen = {}
        local uniq = {}
        for _, m in ipairs(pool) do
            if not seen[m] then
                seen[m] = true
                table.insert(uniq, m)
            end
        end

        return uniq
    end

    function GM:SavePlayerAppearance(ply)
        if not IsValid(ply) then return end
        
        ply:SetPData("ra_playermodel", ply:GetModel())
        
        ply:SetPData("ra_playerskin", tostring(ply:GetSkin()))
        
        local bodygroups = {}
        for k, v in pairs(ply:GetBodyGroups()) do
            bodygroups[v.id] = ply:GetBodygroup(v.id)
        end
        ply:SetPData("ra_playerbodygroups", util.TableToJSON(bodygroups))
        
        print("[Random Asylum] Saved appearance for " .. ply:Nick() .. 
              ": Model=" .. ply:GetModel() .. 
              ", Skin=" .. ply:GetSkin())
    end

    function GM:LoadPlayerAppearance(ply)
        if not IsValid(ply) then return end

        local model = ply:GetPData("ra_playermodel")
        local skin = ply:GetPData("ra_playerskin")
        local bodygroupsJSON = ply:GetPData("ra_playerbodygroups")

        if not model or not file.Exists(model, "GAME") then
            local models = GetPlayerModelPool()
            model = "models/player/kleiner.mdl"
            if #models > 0 then
                model = models[math.random(#models)]
            end
            ply:SetPData("ra_playermodel", model)
            ply:SetPData("ra_playerskin", "0")
            ply:SetPData("ra_playerbodygroups", "[]")
        end

        ply:SetModel(model)

        if skin then
            ply:SetSkin(tonumber(skin) or 0)
        end

        if bodygroupsJSON then
            local bodygroups = util.JSONToTable(bodygroupsJSON)
            if bodygroups then
                for id, value in pairs(bodygroups) do
                    ply:SetBodygroup(id, value)
                end
            end
        end

        ply:SetupHands()

        ply:SetNWString("ra_playermodel", ply:GetModel())
        ply:SetNWInt("ra_playerskin", ply:GetSkin())

        print("[Random Asylum] Loaded appearance for " .. ply:Nick() .. ": " .. model)
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
        
        self:SavePlayerAppearance(ply)
        
        ply:SetupHands()
        
        ply:SetNWString("ra_playermodel", ply:GetModel())
        ply:SetNWInt("ra_playerskin", ply:GetSkin())
        
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

    concommand.Add("ra_saveappearance", function(ply)
        if IsValid(ply) then
            GAMEMODE:SavePlayerAppearance(ply)
            ply:ChatPrint("Appearance saved!")
        end
    end)

    concommand.Add("ra_resetappearance", function(ply)
        if IsValid(ply) then
            ply:RemovePData("ra_playermodel")
            ply:RemovePData("ra_playerskin")
            ply:RemovePData("ra_playerbodygroups")
            ply:ChatPrint("Saved appearance reset. Random model will be chosen on next spawn.")
        end
    end)

    hook.Add("PlayerSetModel", "RandomAsylum_SaveCustomModel", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                GAMEMODE:SavePlayerAppearance(ply)
            end
        end)
    end)

    hook.Add("PlayerSpawn", "RandomAsylum_LoadAppearance", function(ply)
        GAMEMODE:LoadPlayerAppearance(ply)
    end)

    hook.Add("PlayerInitialSpawn", "RandomAsylum_FirstAppearance", function(ply)
        timer.Simple(1, function()
            if IsValid(ply) then
                GAMEMODE:LoadPlayerAppearance(ply)
            end
        end)
    end)
end