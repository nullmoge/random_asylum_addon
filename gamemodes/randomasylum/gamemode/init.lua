AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("player_appearance.lua")
AddCSLuaFile("round_management.lua")
AddCSLuaFile("weapon_system.lua")
AddCSLuaFile("hud_system.lua")

include("shared.lua")

include("player_appearance.lua")
include("round_management.lua")
include("weapon_system.lua")

util.AddNetworkString("RandomAsylum_RoundTime")
util.AddNetworkString("RandomAsylum_RoundStart")
util.AddNetworkString("RandomAsylum_RoundEnd")
util.AddNetworkString("RandomAsylum_RoundResults")
util.AddNetworkString("RandomAsylum_MapVoteActive")
util.AddNetworkString("RandomAsylum_ChangeModel")

function GM:Initialize()
    if SERVER then
        RunConsoleCommand("sbox_playershurtplayers", "1")
        RunConsoleCommand("sbox_godmod", "0")
        print("[Random Asylum] PVP damage enabled!")
    end
    print("[Random Asylum] Gamemode loaded!")
end