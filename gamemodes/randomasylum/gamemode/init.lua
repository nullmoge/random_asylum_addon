AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("RandomAsylum_RoundTime")
util.AddNetworkString("RandomAsylum_RoundStart")
util.AddNetworkString("RandomAsylum_RoundEnd")
util.AddNetworkString("RandomAsylum_RoundResults")
util.AddNetworkString("RandomAsylum_MapVoteActive")
util.AddNetworkString("RandomAsylum_ChangeModel")

local bannedWeapons = {
    "weapon_physgun",
    "gmod_tool",
    "gmod_camera"
}

local playerModelCache = {}
if not PLAYER_MODELS then
    PLAYER_MODELS = {}
end

local function LoadPlayerModels()
    if file.Exists("random_asylum/playermodels.txt", "DATA") then
        local data = file.Read("random_asylum/playermodels.txt", "DATA")
        if data then
            PLAYER_MODELS = util.JSONToTable(data) or {}
        end
    end
end

local function SavePlayerModels()
    if not file.IsDir("random_asylum", "DATA") then
        file.CreateDir("random_asylum")
    end
    file.Write("random_asylum/playermodels.txt", util.TableToJSON(PLAYER_MODELS))
end

hook.Add("Initialize", "LoadPlayerModels", function()
    LoadPlayerModels()
    print("[Random Asylum] Loaded " .. table.Count(PLAYER_MODELS) .. " player models")
end)

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

local function GetValidModel(model)
    if isstring(model) and file.Exists(model, "GAME") then
        return model
    end
    return "models/player/kleiner.mdl"
end

function GM:PlayerSetModel(ply)
    local steamID = ply:SteamID()
    if not steamID then return end
    
    local finalModel = "models/player/kleiner.mdl"
    
    if PLAYER_MODELS[steamID] then
        finalModel = PLAYER_MODELS[steamID]
    else
        local saved = ply:GetPData("ra_playermodel")
        if saved and file.Exists(saved, "GAME") then
            finalModel = saved
            PLAYER_MODELS[steamID] = finalModel
            SavePlayerModels()
        else
            local models = GetPlayerModelPool()
            if #models > 0 then
                finalModel = GetValidModel(models[math.random(#models)])
            end
            
            PLAYER_MODELS[steamID] = finalModel
            ply:SetPData("ra_playermodel", finalModel)
            SavePlayerModels()
        end
    end

    if not file.Exists(finalModel, "GAME") then
        print("[Random Asylum] WARNING: Model " .. finalModel .. " doesn't exist for " .. ply:Nick())
        finalModel = "models/player/kleiner.mdl"
        PLAYER_MODELS[steamID] = finalModel
        SavePlayerModels()
    end

    ply:SetModel(finalModel)
    ply:SetupHands()
    ply:SetNWString("ra_playermodel", finalModel)
    
    print("[Random Asylum] Set model for " .. ply:Nick() .. ": " .. finalModel)
end

function GM:ChangePlayerModel(ply, model)
    if not IsValid(ply) or not model then return false end
    
    local steamID = ply:SteamID()
    if not steamID then return false end
    
    if not file.Exists(model, "GAME") then
        ply:ChatPrint("Error: model '" .. model .. "' not found!")
        return false
    end
    
    PLAYER_MODELS[steamID] = model
    ply:SetPData("ra_playermodel", model)
    SavePlayerModels()
    
    if ply:Alive() then
        ply:SetModel(model)
        ply:SetupHands()
    end
    
    ply:SetNWString("ra_playermodel", model)
    ply:ChatPrint("Model changed on: " .. model)
    
    print("[Random Asylum] " .. ply:Nick() .. " changed model to: " .. model)
    
    return true
end

net.Receive("RandomAsylum_ChangeModel", function(len, ply)
    if not IsValid(ply) then return end
    local model = net.ReadString()
    if model and model ~= "" then
        GAMEMODE:ChangePlayerModel(ply, model)
    end
end)

concommand.Add("ra_resetmodel", function(ply)
    if not IsValid(ply) then return end
    
    local steamID = ply:SteamID()
    if PLAYER_MODELS[steamID] then
        PLAYER_MODELS[steamID] = nil
    end
    ply:RemovePData("ra_playermodel")
    SavePlayerModels()
end)

function GM:PlayerInitialSpawn(ply)
    ply:SetNWInt("ra_kills", 0)
    ply:SetNWInt("ra_deaths", 0)
    timer.Simple(1, function()
        if IsValid(ply) then
            self:PlayerSetModel(ply)
        end
    end)
end

function GM:PlayerLoadout(ply)
    return true
end

hook.Add("PlayerSpawn", "RandomAsylum_SetModelAndGiveSWEP", function(ply)
    GAMEMODE:PlayerSetModel(ply)

    ply:StripWeapons()
    ply:StripAmmo()

    for _, ban in ipairs(bannedWeapons) do
        if ply:HasWeapon(ban) then
            ply:StripWeapon(ban)
        end
    end

    local allowAdmin = GetConVar("ra_allow_admin_weapons"):GetBool()
    local swepCount = math.max(1, GetConVar("ra_swep_count"):GetInt())

    local allWeapons = weapons.GetList()
    local availableWeapons = {}

    for _, wep in ipairs(allWeapons) do
        if wep.ClassName and not table.HasValue(bannedWeapons, wep.ClassName) then
            if allowAdmin or not wep.AdminOnly then
                table.insert(availableWeapons, wep.ClassName)
            end
        end
    end

    if #availableWeapons == 0 then
        ply:Give("weapon_crowbar")
        return
    end

    for i = 1, swepCount do
        if #availableWeapons <= 0 then break end
        local randomIndex = math.random(1, #availableWeapons)
        local randomSWEP = table.remove(availableWeapons, randomIndex)

        if isstring(randomSWEP) then
            ply:Give(randomSWEP)

            local ws = weapons.GetStored(randomSWEP) or weapons.Get(randomSWEP)
            if ws and ws.Primary and isstring(ws.Primary.Ammo) and ws.Primary.Ammo ~= "" then
                ply:GiveAmmo(64, ws.Primary.Ammo, true)
            else
                ply:GiveAmmo(32, "Pistol", true)
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "RandomAsylum_ClearModelCache", function(ply)
    if ply and ply:SteamID64() then
        playerModelCache[ply:SteamID64()] = nil
    end
end)

hook.Add("PlayerDeath", "RandomAsylum_TrackStats", function(victim, inflictor, attacker)
    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        attacker:SetNWInt("ra_kills", attacker:GetNWInt("ra_kills") + 1)
    end
    victim:SetNWInt("ra_deaths", victim:GetNWInt("ra_deaths") + 1)
end)

hook.Add("ShutDown", "SavePlayerModelsOnShutdown", function()
    SavePlayerModels()
    print("[Random Asylum] Saved player models on shutdown")
end)

local function EndRound()
    net.Start("RandomAsylum_RoundEnd")
    net.Broadcast()

    local topKiller = {name = "Nobody", kills = 0}
    local topDeather = {name = "Nobody", deaths = 0}

    for _, ply in ipairs(player.GetAll()) do
        local kills = ply:GetNWInt("ra_kills")
        if kills > topKiller.kills then
            topKiller.name = ply:Nick()
            topKiller.kills = kills
        end

        local deaths = ply:GetNWInt("ra_deaths")
        if deaths > topDeather.deaths then
            topDeather.name = ply:Nick()
            topDeather.deaths = deaths
        end
    end

    net.Start("RandomAsylum_RoundResults")
    net.WriteString(topKiller.name)
    net.WriteInt(topKiller.kills, 16)
    net.WriteString(topDeather.name)
    net.WriteInt(topDeather.deaths, 16)
    net.Broadcast()

    GAMEMODE.IsWaitingForPlayers = true
    GAMEMODE.RoundStartTime = 0
    GAMEMODE.RoundDuration = 0
    GAMEMODE.ShowResultsUntil = CurTime() + 5

    net.Start("RandomAsylum_RoundTime")
    net.WriteBool(true)
    net.WriteInt(#player.GetAll(), 8)
    net.WriteInt(GAMEMODE.MinPlayers, 8)
    net.WriteFloat(0)
    net.WriteInt(0, 32)
    net.Broadcast()

    PrintMessage(HUD_PRINTTALK, "[Random Asylum] Round over! Showing results...")

    timer.Simple(5, function()
        if not GAMEMODE.MapVoteActive then
            PrintMessage(HUD_PRINTTALK, "[Random Asylum] Starting mapvote!")
            GAMEMODE.MapVoteActive = true
            net.Start("RandomAsylum_MapVoteActive")
            net.WriteBool(true)
            net.Broadcast()
            RunConsoleCommand("mapvote")
        end
    end)
end

local function StartRound()
    GAMEMODE.MapVoteActive = false
    net.Start("RandomAsylum_MapVoteActive")
    net.WriteBool(false)
    net.Broadcast()

    for _, ply in ipairs(player.GetAll()) do
        ply:SetNWInt("ra_kills", 0)
        ply:SetNWInt("ra_deaths", 0)
    end

    GAMEMODE.IsWaitingForPlayers = false
    GAMEMODE.RoundDuration = GetConVar("ra_round_time"):GetInt()
    GAMEMODE.RoundStartTime = CurTime()

    PrintMessage(HUD_PRINTTALK, "[Random Asylum] Fight!")

    net.Start("RandomAsylum_RoundTime")
    net.WriteBool(false)
    net.WriteInt(#player.GetAll(), 8)
    net.WriteInt(GAMEMODE.MinPlayers, 8)
    net.WriteFloat(0)
    net.WriteInt(GAMEMODE.RoundDuration, 32)
    net.Broadcast()

    net.Start("RandomAsylum_RoundStart")
    net.Broadcast()

    timer.Create("RandomAsylum_RoundTimer", GAMEMODE.RoundDuration, 1, EndRound)
end

hook.Add("InitPostEntity", "RandomAsylum_InitWaiting", function()
    GAMEMODE.MinPlayers = GetConVar("ra_min_players"):GetInt()
    GAMEMODE.MapVoteActive = false
    GAMEMODE.IsWaitingForPlayers = true
    GAMEMODE.RoundStartTime = 0
    GAMEMODE.RoundDuration = 0
    GAMEMODE.ShowResultsUntil = 0

    PrintMessage(HUD_PRINTTALK, "[Random Asylum] Waiting for players... Need at least " .. GAMEMODE.MinPlayers)
    print("[RandomAsylum Debug] MinPlayers: " .. GAMEMODE.MinPlayers .. ", Players: " .. #player.GetAll())

    if timer.Exists("RandomAsylum_BroadcastTimer") then timer.Remove("RandomAsylum_BroadcastTimer") end
    timer.Create("RandomAsylum_BroadcastTimer", 1, 0, function()
        net.Start("RandomAsylum_RoundTime")
        net.WriteBool(GAMEMODE.IsWaitingForPlayers)
        net.WriteInt(#player.GetAll(), 8)
        net.WriteInt(GAMEMODE.MinPlayers, 8)

        if not GAMEMODE.IsWaitingForPlayers then
            net.WriteFloat(CurTime() - GAMEMODE.RoundStartTime)
            net.WriteInt(GAMEMODE.RoundDuration, 32)
        else
            net.WriteFloat(0)
            net.WriteInt(0, 32)
        end
        net.Broadcast()
    end)
end)

hook.Add("Think", "RandomAsylum_CheckStartRound", function()
    if GAMEMODE.IsWaitingForPlayers and not GAMEMODE.MapVoteActive then
        local playerCount = #player.GetAll()
        if playerCount >= GAMEMODE.MinPlayers then
            StartRound()
        end
    end
end)