--[[
    WCS_BrainTerrorMeter.lua - Integración con TerrorMeter v1.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Integración con el addon TerrorMeter para obtener métricas reales de DPS/HPS
    y mejorar el sistema de recompensas del Brain AI.
    
    Características:
    - Detección automática de TerrorMeter
    - Lectura de DPS/HPS en tiempo real
    - Ranking en grupo/raid
    - Top hechizos por daño
    - Integración con WCS_BrainReward
    - Integración con WCS_BrainMetrics
    - Sistema de logros basado en DPS
]]--

WCS_BrainTerrorMeter = WCS_BrainTerrorMeter or {}
WCS_BrainTerrorMeter.VERSION = "1.0"
WCS_BrainTerrorMeter.enabled = true

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================
WCS_BrainTerrorMeter.Config = {
    updateInterval = 1.0,        -- Actualizar cada 1 segundo
    debugMode = false,           -- Modo debug
    enableNotifications = true,  -- Notificar cambios de ranking
    enableRewardBonus = true,    -- Bonus de recompensa por DPS alto
    enableMetrics = true,        -- Actualizar métricas
    enableAchievements = true,   -- Sistema de logros
    minDPSForBonus = 100,       -- DPS mínimo para bonus
    topRankBonus = 1.5,         -- Multiplicador si estás #1
    top3RankBonus = 1.2,        -- Multiplicador si estás top 3
}

-- ============================================================================
-- ESTADO INTERNO
-- ============================================================================
WCS_BrainTerrorMeter.State = {
    isAvailable = false,
    lastUpdate = 0,
    currentDPS = 0,
    currentHPS = 0,
    currentRank = 0,
    lastRank = 0,
    topSpells = {},
    combatTime = 0,
    totalDamage = 0,
    totalHealing = 0,
    groupSize = 0,
}

-- ============================================================================
-- ESTADÍSTICAS HISTÓRICAS
-- ============================================================================
WCS_BrainTerrorMeter.Stats = {
    peakDPS = 0,
    peakHPS = 0,
    timesRank1 = 0,
    timesTop3 = 0,
    averageDPS = 0,
    combatsTracked = 0,
    totalDPSSamples = 0,
}

-- ============================================================================
-- DETECCIÓN DE TERRORMETER
-- ============================================================================
function WCS_BrainTerrorMeter:IsAvailable()
    -- Verificar si TerrorMeter está cargado
    if TerrorMeter and TerrorMeter.data then
        self.State.isAvailable = true
        return true
    end
    
    self.State.isAvailable = false
    return false
end

function WCS_BrainTerrorMeter:CheckAvailability()
    local available = self:IsAvailable()
    
    if available and not self.State.isAvailable then
        self:Log("TerrorMeter detectado y disponible")
        self.State.isAvailable = true
    elseif not available and self.State.isAvailable then
        self:Log("TerrorMeter no disponible")
        self.State.isAvailable = false
    end
    
    return available
end

-- ============================================================================
-- LECTURA DE DATOS - DPS/HPS
-- ============================================================================
function WCS_BrainTerrorMeter:GetCurrentDPS()
    if not self:IsAvailable() then return 0 end
    
    local playerName = UnitName("player")
    if not playerName then return 0 end
    
    -- Datos del combate actual [1]
    local currentData = TerrorMeter.data.damage[1]
    if not currentData then return 0 end
    
    if currentData[playerName] then
        local playerData = currentData[playerName]
        
        -- Calcular DPS manualmente si no está disponible
        local dps = 0
        if playerData._sum and playerData._ctime and playerData._ctime > 0 then
            dps = playerData._sum / playerData._ctime
        end
        
        self.State.currentDPS = dps
        self.State.totalDamage = playerData._sum or 0
        self.State.combatTime = playerData._ctime or 0
        
        return dps
    end
    
    return 0
end

function WCS_BrainTerrorMeter:GetCurrentHPS()
    if not self:IsAvailable() then return 0 end
    
    local playerName = UnitName("player")
    if not playerName then return 0 end
    
    -- Datos del combate actual [1]
    local currentData = TerrorMeter.data.heal[1]
    if not currentData then return 0 end
    
    if currentData[playerName] then
        local playerData = currentData[playerName]
        
        -- Calcular HPS manualmente
        local hps = 0
        if playerData._sum and playerData._ctime and playerData._ctime > 0 then
            hps = playerData._sum / playerData._ctime
        end
        
        self.State.currentHPS = hps
        self.State.totalHealing = playerData._sum or 0
        
        return hps
    end
    
    return 0
end

function WCS_BrainTerrorMeter:GetOverallDPS()
    if not self:IsAvailable() then return 0 end
    
    local playerName = UnitName("player")
    if not playerName then return 0 end
    
    -- Datos overall [0]
    local overallData = TerrorMeter.data.damage[0]
    if not overallData then return 0 end
    
    if overallData[playerName] then
        local playerData = overallData[playerName]
        
        local dps = 0
        if playerData._sum and playerData._ctime and playerData._ctime > 0 then
            dps = playerData._sum / playerData._ctime
        end
        
        return dps
    end
    
    return 0
end

-- ============================================================================
-- RANKING EN GRUPO/RAID
-- ============================================================================
function WCS_BrainTerrorMeter:GetRankInGroup()
    if not self:IsAvailable() then return 0 end
    
    local playerName = UnitName("player")
    if not playerName then return 0 end
    
    local currentData = TerrorMeter.data.damage[1]
    if not currentData then return 0 end
    
    -- Crear tabla de DPS
    local dpsTable = {}
    for name, data in pairs(currentData) do
        -- Ignorar entradas internas de TerrorMeter
        if not TerrorMeter.internals[name] then
            local dps = 0
            if data._sum and data._ctime and data._ctime > 0 then
                dps = data._sum / data._ctime
            end
            
            -- Lua 5.0: usar table.insert sin índice
            table.insert(dpsTable, {name = name, dps = dps})
        end
    end
    
    -- Ordenar por DPS descendente
    table.sort(dpsTable, function(a, b) return a.dps > b.dps end)
    
    -- Encontrar posición del jugador
    local rank = 0
    for i = 1, table.getn(dpsTable) do  -- Lua 5.0: table.getn en lugar de #
        if dpsTable[i].name == playerName then
            rank = i
            break
        end
    end
    
    self.State.currentRank = rank
    self.State.groupSize = table.getn(dpsTable)
    
    return rank
end

function WCS_BrainTerrorMeter:GetGroupDPSList()
    if not self:IsAvailable() then return {} end
    
    local currentData = TerrorMeter.data.damage[1]
    if not currentData then return {} end
    
    local dpsTable = {}
    for name, data in pairs(currentData) do
        if not TerrorMeter.internals[name] then
            local dps = 0
            if data._sum and data._ctime and data._ctime > 0 then
                dps = data._sum / data._ctime
            end
            
            table.insert(dpsTable, {
                name = name,
                dps = dps,
                damage = data._sum or 0,
                time = data._ctime or 0
            })
        end
    end
    
    table.sort(dpsTable, function(a, b) return a.dps > b.dps end)
    
    return dpsTable
end

-- ============================================================================
-- TOP HECHIZOS
-- ============================================================================
function WCS_BrainTerrorMeter:GetTopSpells(count)
    if not self:IsAvailable() then return {} end
    
    count = count or 5  -- Por defecto top 5
    
    local playerName = UnitName("player")
    if not playerName then return {} end
    
    local currentData = TerrorMeter.data.damage[1]
    if not currentData or not currentData[playerName] then return {} end
    
    local playerData = currentData[playerName]
    local spells = {}
    
    for key, value in pairs(playerData) do
        -- Ignorar campos internos
        if not TerrorMeter.internals[key] and type(value) == "number" and value > 0 then
            table.insert(spells, {spell = key, damage = value})
        end
    end
    
    -- Ordenar por daño descendente
    table.sort(spells, function(a, b) return a.damage > b.damage end)
    
    -- Retornar solo los top N
    local topSpells = {}
    for i = 1, math.min(count, table.getn(spells)) do
        table.insert(topSpells, spells[i])
    end
    
    self.State.topSpells = topSpells
    
    return topSpells
end

-- ============================================================================
-- ACTUALIZACIÓN PERIÓDICA
-- ============================================================================
function WCS_BrainTerrorMeter:Update()
    if not self:CheckAvailability() then return end
    
    local now = GetTime()
    if now - self.State.lastUpdate < self.Config.updateInterval then
        return
    end
    
    self.State.lastUpdate = now
    
    -- Actualizar métricas
    local dps = self:GetCurrentDPS()
    local hps = self:GetCurrentHPS()
    local rank = self:GetRankInGroup()
    
    -- Actualizar estadísticas
    self:UpdateStats(dps, hps, rank)
    
    -- Notificar cambios de ranking
    if self.Config.enableNotifications then
        self:CheckRankChange(rank)
    end
    
    -- Integrar con otros módulos
    if self.Config.enableMetrics then
        self:UpdateMetricsModule()
    end
    
    if self.Config.enableRewardBonus then
        self:UpdateRewardModule()
    end
end

-- ============================================================================
-- ESTADÍSTICAS
-- ============================================================================
function WCS_BrainTerrorMeter:UpdateStats(dps, hps, rank)
    -- Actualizar picos
    if dps > self.Stats.peakDPS then
        self.Stats.peakDPS = dps
    end
    
    if hps > self.Stats.peakHPS then
        self.Stats.peakHPS = hps
    end
    
    -- Contar veces en top ranks
    if rank == 1 then
        self.Stats.timesRank1 = self.Stats.timesRank1 + 1
    end
    
    if rank > 0 and rank <= 3 then
        self.Stats.timesTop3 = self.Stats.timesTop3 + 1
    end
    
    -- Calcular promedio de DPS
    if dps > 0 then
        self.Stats.totalDPSSamples = self.Stats.totalDPSSamples + dps
        self.Stats.combatsTracked = self.Stats.combatsTracked + 1
        self.Stats.averageDPS = self.Stats.totalDPSSamples / self.Stats.combatsTracked
    end
end

function WCS_BrainTerrorMeter:CheckRankChange(newRank)
    if newRank ~= self.State.lastRank and newRank > 0 then
        if newRank < self.State.lastRank then
            -- Subimos de ranking
            self:Notify("¡Subiste al puesto #" .. newRank .. " en DPS!")
        elseif newRank > self.State.lastRank and self.State.lastRank > 0 then
            -- Bajamos de ranking
            self:Notify("Bajaste al puesto #" .. newRank .. " en DPS")
        end
        
        self.State.lastRank = newRank
    end
end

-- ============================================================================
-- INTEGRACIÓN CON WCS_BrainMetrics
-- ============================================================================
function WCS_BrainTerrorMeter:UpdateMetricsModule()
    if not WCS_BrainMetrics then return end
    
    -- Añadir métricas de TerrorMeter
    if not WCS_BrainMetrics.terrorMeter then
        WCS_BrainMetrics.terrorMeter = {
            currentDPS = 0,
            currentHPS = 0,
            rank = 0,
            groupSize = 0,
            peakDPS = 0,
            topSpells = {}
        }
    end
    
    WCS_BrainMetrics.terrorMeter.currentDPS = self.State.currentDPS
    WCS_BrainMetrics.terrorMeter.currentHPS = self.State.currentHPS
    WCS_BrainMetrics.terrorMeter.rank = self.State.currentRank
    WCS_BrainMetrics.terrorMeter.groupSize = self.State.groupSize
    WCS_BrainMetrics.terrorMeter.peakDPS = self.Stats.peakDPS
    WCS_BrainMetrics.terrorMeter.topSpells = self.State.topSpells
end

-- ============================================================================
-- INTEGRACIÓN CON WCS_BrainReward (DQN)
-- ============================================================================
function WCS_BrainTerrorMeter:UpdateRewardModule()
    if not WCS_BrainReward then return end
    
    -- Calcular bonus de recompensa basado en DPS
    local bonus = 0
    
    if self.State.currentDPS >= self.Config.minDPSForBonus then
        -- Bonus base por DPS alto
        bonus = 0.1
        
        -- Bonus adicional por ranking
        if self.State.currentRank == 1 then
            bonus = bonus * self.Config.topRankBonus
        elseif self.State.currentRank > 0 and self.State.currentRank <= 3 then
            bonus = bonus * self.Config.top3RankBonus
        end
    end
    
    -- Aplicar bonus a la recompensa
    if WCS_BrainReward.AddDPSBonus then
        WCS_BrainReward:AddDPSBonus(bonus)
    end
end

-- ============================================================================
-- INTEGRACIÓN CON WCS_BrainAchievements
-- ============================================================================
function WCS_BrainTerrorMeter:CheckAchievements()
    if not self.Config.enableAchievements then return end
    if not WCS_BrainAchievements then return end
    
    -- Logro: Top DPS (estar #1)
    if self.State.currentRank == 1 and self.State.groupSize >= 5 then
        if WCS_BrainAchievements.UnlockAchievement then
            WCS_BrainAchievements:UnlockAchievement("top_dps")
        end
    end
    
    -- Logro: DPS Master (superar 500 DPS)
    if self.State.currentDPS >= 500 then
        if WCS_BrainAchievements.UnlockAchievement then
            WCS_BrainAchievements:UnlockAchievement("dps_master")
        end
    end
    
    -- Logro: Consistent (mantener top 3 por 10 actualizaciones)
    if self.Stats.timesTop3 >= 10 then
        if WCS_BrainAchievements.UnlockAchievement then
            WCS_BrainAchievements:UnlockAchievement("consistent_dps")
        end
    end
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
function WCS_BrainTerrorMeter:RegisterCommands()
    SLASH_BRAINTERROR1 = "/brainterror"
    SLASH_BRAINTERROR2 = "/btm"
    
    SlashCmdList["BRAINTERROR"] = function(msg)
        WCS_BrainTerrorMeter:HandleCommand(msg)
    end
end

function WCS_BrainTerrorMeter:HandleCommand(msg)
    msg = string.lower(msg or "")
    
    if msg == "" or msg == "status" then
        self:ShowStatus()
    elseif msg == "stats" then
        self:ShowStats()
    elseif msg == "top" or msg == "spells" then
        self:ShowTopSpells()
    elseif msg == "rank" or msg == "ranking" then
        self:ShowRanking()
    elseif msg == "on" then
        self.enabled = true
        self:Print("TerrorMeter integration ACTIVADA")
    elseif msg == "off" then
        self.enabled = false
        self:Print("TerrorMeter integration DESACTIVADA")
    elseif msg == "debug" then
        self.Config.debugMode = not self.Config.debugMode
        self:Print("Debug mode: " .. (self.Config.debugMode and "ON" or "OFF"))
    elseif msg == "help" then
        self:ShowHelp()
    else
        self:Print("Comando desconocido. Usa /btm help")
    end
end

-- ============================================================================
-- MOSTRAR INFORMACIÓN
-- ============================================================================
function WCS_BrainTerrorMeter:ShowStatus()
    self:Print("|cFF00FF00=== TerrorMeter Integration Status ===")
    self:Print("Disponible: " .. (self.State.isAvailable and "|cFF00FF00SÍ" or "|cFFFF0000NO"))
    self:Print("DPS Actual: |cFFFFFF00" .. string.format("%.1f", self.State.currentDPS))
    self:Print("HPS Actual: |cFFFFFF00" .. string.format("%.1f", self.State.currentHPS))
    self:Print("Ranking: |cFFFFFF00#" .. self.State.currentRank .. " / " .. self.State.groupSize)
    self:Print("Daño Total: |cFFFFFF00" .. self.State.totalDamage)
    self:Print("Tiempo: |cFFFFFF00" .. string.format("%.1f", self.State.combatTime) .. "s")
end

function WCS_BrainTerrorMeter:ShowStats()
    self:Print("|cFF00FF00=== TerrorMeter Statistics ===")
    self:Print("Peak DPS: |cFFFFFF00" .. string.format("%.1f", self.Stats.peakDPS))
    self:Print("Peak HPS: |cFFFFFF00" .. string.format("%.1f", self.Stats.peakHPS))
    self:Print("Average DPS: |cFFFFFF00" .. string.format("%.1f", self.Stats.averageDPS))
    self:Print("Veces #1: |cFFFFFF00" .. self.Stats.timesRank1)
    self:Print("Veces Top 3: |cFFFFFF00" .. self.Stats.timesTop3)
    self:Print("Combates: |cFFFFFF00" .. self.Stats.combatsTracked)
end

function WCS_BrainTerrorMeter:ShowTopSpells()
    local topSpells = self:GetTopSpells(5)
    
    self:Print("|cFF00FF00=== Top 5 Hechizos por Daño ===")
    
    if table.getn(topSpells) == 0 then
        self:Print("|cFFFF0000No hay datos disponibles")
        return
    end
    
    for i = 1, table.getn(topSpells) do
        local spell = topSpells[i]
        self:Print(i .. ". |cFFFFFF00" .. spell.spell .. "|r - " .. spell.damage .. " daño")
    end
end

function WCS_BrainTerrorMeter:ShowRanking()
    local dpsList = self:GetGroupDPSList()
    
    self:Print("|cFF00FF00=== Ranking de DPS ===")
    
    if table.getn(dpsList) == 0 then
        self:Print("|cFFFF0000No hay datos disponibles")
        return
    end
    
    local playerName = UnitName("player")
    
    for i = 1, math.min(10, table.getn(dpsList)) do
        local entry = dpsList[i]
        local color = "|cFFFFFFFF"
        
        if entry.name == playerName then
            color = "|cFF00FF00"  -- Verde para el jugador
        elseif i == 1 then
            color = "|cFFFFD700"  -- Dorado para #1
        elseif i <= 3 then
            color = "|cFFC0C0C0"  -- Plateado para top 3
        end
        
        self:Print(i .. ". " .. color .. entry.name .. "|r - " .. string.format("%.1f", entry.dps) .. " DPS")
    end
end

function WCS_BrainTerrorMeter:ShowHelp()
    self:Print("|cFF00FF00=== TerrorMeter Integration Commands ===")
    self:Print("/btm status - Mostrar estado actual")
    self:Print("/btm stats - Mostrar estadísticas")
    self:Print("/btm top - Mostrar top hechizos")
    self:Print("/btm rank - Mostrar ranking de grupo")
    self:Print("/btm on/off - Activar/desactivar")
    self:Print("/btm debug - Toggle debug mode")
    self:Print("/btm help - Mostrar esta ayuda")
end

-- ============================================================================
-- UTILIDADES
-- ============================================================================
function WCS_BrainTerrorMeter:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[BTM]|r " .. msg)
end

function WCS_BrainTerrorMeter:Notify(msg)
    if not self.Config.enableNotifications then return end
    
    UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0.0, 1.0, UIERRORS_HOLD_TIME)
end

function WCS_BrainTerrorMeter:Log(msg)
    if not self.Config.debugMode then return end
    
    -- Integrar con WCS_BrainLogger si está disponible
    if WCS_BrainLogger and WCS_BrainLogger.Log then
        WCS_BrainLogger:Log("INFO", "TerrorMeter", msg)
    else
        self:Print("[DEBUG] " .. msg)
    end
end

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Salir de combate
frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entrar en combate

frame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        WCS_BrainTerrorMeter:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        WCS_BrainTerrorMeter:CheckAvailability()
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entrar en combate - resetear stats de combate actual
        WCS_BrainTerrorMeter.State.lastRank = 0
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Salir de combate - verificar logros
        WCS_BrainTerrorMeter:CheckAchievements()
    end
end)

function WCS_BrainTerrorMeter:Initialize()
    self:Print("TerrorMeter Integration v" .. self.VERSION .. " cargado")
    self:RegisterCommands()
    self:CheckAvailability()
    
    -- Iniciar actualización periódica
    self:StartUpdateLoop()
end

function WCS_BrainTerrorMeter:StartUpdateLoop()
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        if WCS_BrainTerrorMeter.enabled then
            WCS_BrainTerrorMeter:Update()
        end
    end)
end

-- ============================================================================
-- API PÚBLICA PARA OTROS MÓDULOS
-- ============================================================================

-- Obtener DPS actual
function WCS_BrainTerrorMeter:GetDPS()
    return self.State.currentDPS
end

-- Obtener HPS actual
function WCS_BrainTerrorMeter:GetHPS()
    return self.State.currentHPS
end

-- Obtener ranking actual
function WCS_BrainTerrorMeter:GetRank()
    return self.State.currentRank
end

-- Verificar si estamos en top 3
function WCS_BrainTerrorMeter:IsTopDPS()
    return self.State.currentRank > 0 and self.State.currentRank <= 3
end

-- Verificar si somos #1
function WCS_BrainTerrorMeter:IsRank1()
    return self.State.currentRank == 1
end

-- Obtener multiplicador de recompensa basado en DPS
function WCS_BrainTerrorMeter:GetRewardMultiplier()
    if not self:IsAvailable() then return 1.0 end
    
    local multiplier = 1.0
    
    if self.State.currentDPS >= self.Config.minDPSForBonus then
        multiplier = 1.1
        
        if self:IsRank1() then
            multiplier = self.Config.topRankBonus
        elseif self:IsTopDPS() then
            multiplier = self.Config.top3RankBonus
        end
    end
    
    return multiplier
end


-- ============================================================================
-- FIN DEL MÓDULO
-- ============================================================================
