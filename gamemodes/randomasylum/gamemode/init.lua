AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("RandomAsylum_RoundTime")

local bannedWeapons = {
    "weapon_physgun",
    "gmod_tool",
    "gmod_camera"
}

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

function GM:PlayerLoadout(ply)
    return true
end

function GM:PlayerSetModel(ply)
    local models = GetPlayerModelPool()
    local chos = nil

    if #models > 0 then
        chos = models[ math.random(1, #models) ]
    else
        chos = "models/player/kleiner.mdl"
    end

    util.PrecacheModel(chos)
    ply:SetModel(chos)
    ply:SetupHands()
    ply:SetNWString("ra_playermodel", chos)
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

hook.Add("InitPostEntity", "RandomAsylum_InitWaiting", function()
    GAMEMODE.MinPlayers = GetConVar("ra_min_players"):GetInt()
    GAMEMODE.IsWaitingForPlayers = true
    GAMEMODE.RoundStartTime = 0
    GAMEMODE.RoundDuration = 0

    PrintMessage(HUD_PRINTTALK, "[Random Asylum] Waiting for players... Need at least " .. GAMEMODE.MinPlayers .. ".")
    print("[RandomAsylum Debug] MinPlayers set to: " .. GAMEMODE.MinPlayers)
    print("[RandomAsylum Debug] ConVar value: " .. GetConVar("ra_min_players"):GetInt())
    print("[RandomAsylum Debug] Current players: " .. #player.GetAll())

    if timer.Exists("RandomAsylum_BroadcastTimer") then timer.Remove("RandomAsylum_BroadcastTimer") end
    timer.Create("RandomAsylum_BroadcastTimer", 1, 0, function()
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
                RunConsoleCommand("mapvote")
            end)
        end
    end
end)
