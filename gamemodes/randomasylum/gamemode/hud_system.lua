if CLIENT then
    local funnyTexts = {
        "Your SWEP is pure Italian brainrot: named like 'Tralalero Tralala' but hits like a cyclops sigma edit.",
        "Deaths piling up? That's 2025 GTA6 delay energy—promised glory, delivered existential void.",
        "Channeling Godzilla's first meme string: roar once, then get hip-checked by your own reload.",
        "Your killstreak? More like a comedy epilepsy vid: flashes of hope, then instant blackout.",
        "SWEP in hand, but you're the Plesioth hip check—sliding into irrelevance mid-fight.",
        "2025 so far: your ammo runs out faster than Reddit's meme bans on politics.",
        "Embrace the absurd: your next death is just Clem the Grineer dual-wielding your dignity.",
        "Not sugarcoating it—your aim's a Tekken combo straight to self-sabotage."
    }

    net.Receive("RandomAsylum_RoundTime", function()
        GAMEMODE.IsWaitingForPlayers = net.ReadBool()
        local currentPlayers = net.ReadInt(8)
        GAMEMODE.MinPlayers = net.ReadInt(8)
        GAMEMODE.CurrentPlayers = currentPlayers

        local elapsed = net.ReadFloat()
        local duration = net.ReadInt(32)

        if not GAMEMODE.IsWaitingForPlayers then
            GAMEMODE.RoundStartTime = CurTime() - elapsed
            GAMEMODE.RoundDuration = duration
        else
            GAMEMODE.RoundStartTime = 0
            GAMEMODE.RoundDuration = 0
            if not GAMEMODE.FunnyText then
                GAMEMODE.FunnyText = funnyTexts[math.random(#funnyTexts)]
            end
        end
    end)

    net.Receive("RandomAsylum_RoundStart", function() 
        GAMEMODE.FunnyText = nil
    end)

    net.Receive("RandomAsylum_RoundResults", function()
        GAMEMODE.TopKiller = {
            name = net.ReadString(),
            kills = net.ReadInt(16)
        }
        GAMEMODE.TopDeather = {
            name = net.ReadString(),
            deaths = net.ReadInt(16)
        }
        GAMEMODE.ShowResultsUntil = CurTime() + 5
        GAMEMODE.FunnyText = nil
    end)

    net.Receive("RandomAsylum_MapVoteActive", function()
        GAMEMODE.MapVoteActive = net.ReadBool()
    end)

    local whiteMat = Material("vgui/white")

    local function DrawShadowedText(text, font, x, y, color, alignX, alignY)
        draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 100), alignX, alignY)
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
    end

    local function DrawProgressBar(x, y, width, height, progress, color)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(x, y, width, height)
        surface.SetDrawColor(color.r or 100, color.g or 100, color.b or 100, 200)
        surface.DrawRect(x, y, width * progress, height)
        surface.SetDrawColor(255, 255, 255, 100)
        surface.DrawOutlinedRect(x, y, width, height)
    end

    local function DrawLoadingIcon(x, y, size, alpha)
        local time = CurTime() * 2
        surface.SetDrawColor(255, 255, 255, alpha or 255)
        for i = 0, 7 do
            local angle = (time + i * (math.pi / 4)) % (math.pi * 2)
            local px = x + size / 2 * math.cos(angle)
            local py = y + size / 2 * math.sin(angle)
            surface.DrawRect(px - 1, py - 1, 2, 2)
        end
    end

    function GM:HUDPaint()
        local screenW, screenH = ScrW(), ScrH()
        local hudY = 20
        local barWidth = 300
        local barHeight = 20
        local textFont = "DermaLarge"

        local currentPlayers = GAMEMODE.CurrentPlayers or 0
        local minPlayers = GAMEMODE.MinPlayers or 1

        if CurTime() < (GAMEMODE.ShowResultsUntil or 0) then
            local resultsY = screenH / 2 - 80
            surface.SetDrawColor(0, 0, 0, 220)
            surface.DrawRect(screenW / 2 - 250, resultsY - 15, 500, 105)

            DrawShadowedText("Round Results", "Trebuchet24", screenW / 2, resultsY, Color(255, 215, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local killerText = (GAMEMODE.TopKiller and GAMEMODE.TopKiller.name or "Nobody") .. " — " .. (GAMEMODE.TopKiller and GAMEMODE.TopKiller.kills or 0) .. " kills"
            DrawShadowedText("Top Killer: " .. killerText, "DermaDefaultBold", screenW / 2, resultsY + 40, Color(255, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            local deatherText = (GAMEMODE.TopDeather and GAMEMODE.TopDeather.name or "Nobody") .. " — " .. (GAMEMODE.TopDeather and GAMEMODE.TopDeather.deaths or 0) .. " deaths"
            DrawShadowedText("Lover of Deaths: " .. deatherText, "DermaDefaultBold", screenW / 2, resultsY + 70, Color(100, 255, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            return
        end

        if GAMEMODE.IsWaitingForPlayers then
            local progress = math.min(1, currentPlayers / minPlayers)
            local playersText = "Waiting for players: " .. currentPlayers .. "/" .. minPlayers
            local barColor = currentPlayers >= minPlayers and Color(0, 255, 0) or Color(255, 0, 0)

            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(screenW / 2 - barWidth / 2 - 10, hudY - 5, barWidth + 20, barHeight + 40)

            DrawProgressBar(screenW / 2 - barWidth / 2, hudY, barWidth, barHeight, progress, barColor)

            local textY = hudY + barHeight + 15
            local textColor = currentPlayers >= minPlayers and Color(0, 255, 0, 255) or Color(255, 100, 100, 255)
            DrawShadowedText(playersText, textFont, screenW / 2, textY, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            DrawLoadingIcon(screenW / 2 - barWidth / 2 - 20, hudY + 5, 10, 200)

            if not GAMEMODE.MapVoteActive and GAMEMODE.FunnyText then
                DrawShadowedText(GAMEMODE.FunnyText, "DermaDefault", screenW / 2, screenH - 100, Color(200, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if GAMEMODE.MapVoteActive then
                local voteY = hudY + 70
                surface.SetDrawColor(255, 0, 0, 150)
                surface.DrawRect(screenW / 2 - barWidth / 2 - 10, voteY - 5, barWidth + 20, barHeight + 10)
                DrawShadowedText("Map Vote Active - Changing map soon!", textFont, screenW / 2, voteY + 5, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        elseif GAMEMODE.RoundStartTime > 0 and GAMEMODE.RoundDuration > 0 and not GAMEMODE.MapVoteActive then
            local timeLeft = math.max(0, GAMEMODE.RoundDuration - (CurTime() - GAMEMODE.RoundStartTime))
            local minutes = math.floor(timeLeft / 60)
            local seconds = math.floor(timeLeft % 60)
            local timeText = "Time Left: " .. minutes .. ":" .. string.format("%02d", seconds)

            local textColor = timeLeft < 30 and Color(255, 0, 0, 255) or Color(255, 255, 255, 255)
            local pulseAlpha = timeLeft < 30 and (math.sin(CurTime() * 5) * 0.5 + 0.5) * 255 or 255
            textColor.a = pulseAlpha

            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(screenW / 2 - barWidth / 2 - 10, hudY - 5, barWidth + 20, barHeight + 45)

            local radius = barHeight / 2 + 5
            local circleY = hudY + radius
            surface.SetMaterial(whiteMat)
            surface.SetDrawColor(100, 100, 100, 200)
            surface.DrawCircle(screenW / 2, circleY, radius)
            local progress = timeLeft / GAMEMODE.RoundDuration
            surface.SetDrawColor(textColor.r, textColor.g, textColor.b, 200)
            surface.DrawArc(screenW / 2, circleY, radius, radius, -90, -90 + (360 * progress), 32)

            local textY = circleY + radius + 15
            DrawShadowedText(timeText, textFont, screenW / 2, textY, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    function surface.DrawCircle(x, y, radius)
        local steps = 32
        local points = {{x = x, y = y}}
        for i = 0, steps do
            local angle = (i / steps) * math.pi * 2
            table.insert(points, {
                x = x + math.cos(angle) * radius,
                y = y + math.sin(angle) * radius
            })
        end
        surface.DrawPoly(points)
    end

    function surface.DrawArc(x, y, radiusX, radiusY, startAngle, endAngle, segments)
        local points = {{x = x, y = y}}
        for i = 0, segments do
            local progress = i / segments
            local angle = (startAngle + (endAngle - startAngle) * progress) * math.pi / 180
            table.insert(points, {
                x = x + math.cos(angle) * radiusX,
                y = y + math.sin(angle) * radiusY
            })
        end
        surface.DrawPoly(points)
    end
end