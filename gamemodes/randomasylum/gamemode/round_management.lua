if SERVER then
    function GM:PlayerInitialSpawn(ply)
        ply:SetNWInt("ra_kills", 0)
        ply:SetNWInt("ra_deaths", 0)
    end

    hook.Add("PlayerDeath", "RandomAsylum_TrackStats", function(victim, inflictor, attacker)
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            attacker:SetNWInt("ra_kills", attacker:GetNWInt("ra_kills") + 1)
        end
        victim:SetNWInt("ra_deaths", victim:GetNWInt("ra_deaths") + 1)
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
end