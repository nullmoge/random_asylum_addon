DeriveGamemode("sandbox")

GM.Name = "Random Asylum"
GM.Author = "adsk-dev"
GM.Email = "N/A"
GM.Website = "https://adskoe96.github.io/links/"

GM.RoundStartTime = 0
GM.RoundDuration = 0
GM.IsWaitingForPlayers = true
GM.MinPlayers = 0

function GM:Initialize()
    print("[Random Asylum] Gamemode loaded!")
end

function GM:OnSpawnMenuOpen(ply)
    return false
end