DeriveGamemode("sandbox")

GM.Name = "Random Asylum"
GM.Author = "adsk-dev"
GM.Email = "N/A"
GM.Website = "https://adskoe96.github.io/links/"

GM.RoundStartTime = 0
GM.RoundDuration = 0
GM.IsWaitingForPlayers = true
GM.MinPlayers = 0
GM.MapVoteActive = false
GM.ShowResultsUntil = 0

function GM:Initialize()
    if SERVER then
        RunConsoleCommand("sbox_playershurtplayers", "1")
        RunConsoleCommand("sbox_godmod", "0")
        print("[Random Asylum] PVP damage enabled!")
    end
    print("[Random Asylum] Gamemode loaded!")
end

function GM:OnSpawnMenuOpen(ply)
    return false
end

if CLIENT then
    function ChangePlayerModel(modelPath)
        net.Start("RandomAsylum_ChangeModel")
        net.WriteString(modelPath)
        net.SendToServer()
    end
    
    concommand.Add("ra_checkmymodel", function()
        LocalPlayer():ChatPrint("Your model: " .. LocalPlayer():GetModel())
    end)
end