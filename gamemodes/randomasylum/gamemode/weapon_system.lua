if SERVER then
    local bannedWeapons = {
        "weapon_physgun",
        "gmod_tool",
        "gmod_camera"
    }

    function GM:PlayerLoadout(ply)
        return true
    end

    hook.Add("PlayerSpawn", "RandomAsylum_GiveWeapons", function(ply)
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
end