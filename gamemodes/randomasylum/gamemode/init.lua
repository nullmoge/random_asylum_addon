AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("RandomAsylum_RoundTime")

local bannedWeapons = {
    "weapon_physgun",
    "gmod_tool",
    "gmod_camera"
}

function GM:PlayerLoadout(ply)
    return true
end

function GM:PlayerSetModel(ply)
    local playerModels = list.Get("PlayerOptionsModel")
    if table.IsEmpty(playerModels) then
        ply:SetModel("models/player/kleiner.mdl")
    else
        local models = table.GetKeys(playerModels)
        local randomModel = models[math.random(1, #models)]
        ply:SetModel(randomModel)
    end
    ply:SetupHands()
end

hook.Add("PlayerSpawn", "RandomAsylum_GiveSWEP", function(ply)
    ply:StripWeapons()
    ply:StripAmmo()

    for _, ban in ipairs(bannedWeapons) do
        if ply:HasWeapon(ban) then
            ply:StripWeapon(ban)
        end
    end

    local allowAdmin = GetConVar("ra_allow_admin_weapons"):GetBool()
    local swepCount = GetConVar("ra_swep_count"):GetInt()

    local allWeapons = weapons.GetList()
    local availableWeapons = {}

    for _, wep in ipairs(allWeapons) do
        if wep.ClassName and not table.HasValue(bannedWeapons, wep.ClassName) and wep.Category and wep.Category ~= "Admin" then
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
        if #availableWeapons > 0 then
            local randomIndex = math.random(1, #availableWeapons)
            local randomSWEP = availableWeapons[randomIndex]
            ply:Give(randomSWEP)
            ply:GiveAmmo(999, "Pistol", true)
            table.remove(availableWeapons, randomIndex)
        end
    end
end)

hook.Add("InitPostEntity", "RandomAsylum_InitWaiting", function()
    GAMEMODE.MinPlayers = GetConVar("ra_min_players"):GetInt()
    GAMEMODE.IsWaitingForPlayers = true
    GAMEMODE.RoundStartTime = 0
    GAMEMODE.RoundDuration = 0

    PrintMessage(HUD_PRINTTALK, "[Random Asylum] Waiting for players... Need at least " .. GAMEMODE.MinPlayers .. ".")

    print("[RandomAsylum Debug] MinPlayers set to: " .. GAMEMODE.MinPlayers)
    print("[RandomAsylum Debug] ConVar value: " .. GetConVar("ra_min_players"):GetInt())
    print("[RandomAsylum Debug] Current players: " .. #player.GetAll())

    net.Start("RandomAsylum_RoundTime")
    net.WriteBool(GAMEMODE.IsWaitingForPlayers)
    net.WriteInt(#player.GetAll(), 8)
    net.WriteInt(GAMEMODE.MinPlayers, 8)
    net.Broadcast()
end)

hook.Add("Think", "RandomAsylum_CheckStartRound", function()
    if GAMEMODE.IsWaitingForPlayers then
        local playerCount = #player.GetAll()
        if playerCount >= GAMEMODE.MinPlayers then
            GAMEMODE.IsWaitingForPlayers = false
            GAMEMODE.RoundDuration = GetConVar("ra_round_time"):GetInt()
            GAMEMODE.RoundStartTime = CurTime()

            PrintMessage(HUD_PRINTTALK, "[Random Asylum] Enough players! Round started! Duration: " .. GAMEMODE.RoundDuration .. " seconds.")

            timer.Create("RandomAsylum_RoundTimer", GAMEMODE.RoundDuration, 1, function()
                PrintMessage(HUD_PRINTTALK, "[Random Asylum] Round ended! Starting mapvote...")
                RunConsoleCommand("ulx", "mapvote")
            end)
        end
    end

    net.Start("RandomAsylum_RoundTime")
    net.WriteBool(GAMEMODE.IsWaitingForPlayers)
    net.WriteInt(#player.GetAll(), 8)
    net.WriteInt(GAMEMODE.MinPlayers, 8)
    if not GAMEMODE.IsWaitingForPlayers then
        net.WriteFloat(CurTime() - GAMEMODE.RoundStartTime)
        net.WriteInt(GAMEMODE.RoundDuration, 32)
    end
    net.Broadcast()
end)