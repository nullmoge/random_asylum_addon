include("shared.lua")

net.Receive("RandomAsylum_RoundTime", function()
    GAMEMODE.IsWaitingForPlayers = net.ReadBool()
    local currentPlayers = net.ReadInt(8)
    GAMEMODE.MinPlayers = net.ReadInt(8)
    GAMEMODE.CurrentPlayers = currentPlayers

    if not GAMEMODE.IsWaitingForPlayers then
        local elapsed = net.ReadFloat()
        local duration = net.ReadInt(32)
        GAMEMODE.RoundStartTime = CurTime() - elapsed
        GAMEMODE.RoundDuration = duration
    end
end)

function GM:HUDPaint()
    if GAMEMODE.IsWaitingForPlayers then
        draw.SimpleText("Waiting for players: " .. (GAMEMODE.CurrentPlayers or 0) .. "/" .. GAMEMODE.MinPlayers, "DermaLarge", ScrW() / 2, 20, Color(255, 255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif GAMEMODE.RoundStartTime > 0 then
        local timeLeft = math.max(0, GAMEMODE.RoundDuration - (CurTime() - GAMEMODE.RoundStartTime))
        local minutes = math.floor(timeLeft / 60)
        local seconds = math.floor(timeLeft % 60)
        draw.SimpleText("Round Time Left: " .. minutes .. ":" .. string.format("%02d", seconds), "DermaLarge", ScrW() / 2, 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end