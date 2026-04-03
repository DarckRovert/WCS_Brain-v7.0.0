--[[
    WCS_Statistics.lua
    Panel de Estadísticas para "El Séquito del Terror"

    CORRECCIONES (Lua 5.0):
    - Reemplazado time() por GetTime() (time() no existe en WoW 1.12 Lua)
    - Eliminados SetWidth(760) que desbordaban el frame 700px
    - Corregida iteración pairs(combatStats.spellsCast) → compatible Lua 5.0
]]--

WCS_Statistics = WCS_Statistics or {}

local panel = nil
local combatStats = {
    totalDamage   = 0,
    totalHealing  = 0,
    spellsCast    = {},
    combatTime    = 0,
    kills         = 0,
    deaths        = 0,
    sessionStart  = 0,
    lastCombatStart = 0,
    inCombat      = false
}

function WCS_Statistics:Initialize()
    if panel then return end

    panel = CreateFrame("Frame", "WCS_StatisticsFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()

    -- Título
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff9370DBEstadísticas de Combate|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Panel de resumen — anchura relativa al padre
    local summaryPanel = CreateFrame("Frame", nil, panel)
    summaryPanel:SetPoint("TOPLEFT", 10, -50)
    summaryPanel:SetPoint("TOPRIGHT", -10, -50)
    summaryPanel:SetHeight(150)
    summaryPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    summaryPanel:SetBackdropColor(0.1, 0.0, 0.15, 0.8)
    summaryPanel:SetBackdropBorderColor(0.5, 0.0, 0.5, 0.8)

    local summaryTitle = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    summaryTitle:SetPoint("TOP", 0, -10)
    summaryTitle:SetText("|cff00ff00Resumen de Sesión|r")

    -- Columna izquierda
    local damageText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    damageText:SetPoint("TOPLEFT", 20, -40)
    damageText:SetText("|cffffaa00Daño Total:|r 0")
    panel.damageText = damageText

    local dpsText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dpsText:SetPoint("TOPLEFT", 20, -65)
    dpsText:SetText("|cffffaa00DPS Promedio:|r 0")
    panel.dpsText = dpsText

    local healingText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healingText:SetPoint("TOPLEFT", 20, -90)
    healingText:SetText("|cffffaa00Curación Total:|r 0")
    panel.healingText = healingText

    local timeText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    timeText:SetPoint("TOPLEFT", 20, -115)
    timeText:SetText("|cffffaa00Tiempo en Combate:|r 0s")
    panel.timeText = timeText

    -- Columna derecha (usando porcentaje del ancho → fijo 320px desde derecha)
    local killsText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    killsText:SetPoint("TOPRIGHT", -200, -40)
    killsText:SetText("|cff00ff00Kills:|r 0")
    panel.killsText = killsText

    local deathsText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathsText:SetPoint("TOPRIGHT", -200, -65)
    deathsText:SetText("|cffff0000Deaths:|r 0")
    panel.deathsText = deathsText

    local kdText = summaryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    kdText:SetPoint("TOPRIGHT", -200, -90)
    kdText:SetText("|cffffaa00K/D Ratio:|r 0.00")
    panel.kdText = kdText

    -- Panel de hechizos más usados — también relativo
    local spellsPanel = CreateFrame("Frame", nil, panel)
    spellsPanel:SetPoint("TOPLEFT", 10, -220)
    spellsPanel:SetPoint("BOTTOMRIGHT", -10, 50)  -- deja espacio para botón
    spellsPanel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    spellsPanel:SetBackdropColor(0.1, 0.0, 0.15, 0.8)
    spellsPanel:SetBackdropBorderColor(0.2, 1.0, 0.2, 0.5)

    local spellsTitle = spellsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellsTitle:SetPoint("TOP", 0, -10)
    spellsTitle:SetText("|cff00ff00Hechizos Más Usados|r")

    local spellsList = spellsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellsList:SetPoint("TOPLEFT", 20, -40)
    spellsList:SetPoint("BOTTOMRIGHT", spellsPanel, "BOTTOMRIGHT", -10, 5)
    spellsList:SetJustifyH("LEFT")
    spellsList:SetJustifyV("TOP")
    spellsList:SetText("Sin datos de combate aún...")
    panel.spellsList = spellsList

    -- Botón de reset — anclado al BOTTOM
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetWidth(180)
    resetBtn:SetHeight(30)
    resetBtn:SetPoint("BOTTOM", 0, 10)
    resetBtn:SetText("Reset Estadísticas")
    resetBtn:SetScript("OnClick", function()
        WCS_Statistics:ResetStats()
    end)

    self.panel = panel

    -- Inicializar tiempo de sesión con GetTime() (no time())
    combatStats.sessionStart = GetTime()

    -- Registrar eventos
    panel:RegisterEvent("PLAYER_REGEN_DISABLED")
    panel:RegisterEvent("PLAYER_REGEN_ENABLED")
    panel:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
    panel:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    panel:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    panel:RegisterEvent("PLAYER_DEAD")
    panel:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")

    panel:SetScript("OnEvent", function()
        WCS_Statistics:OnEvent(event, arg1)
    end)

    panel:SetScript("OnUpdate", function()
        if not this.lastUpdate then this.lastUpdate = 0 end
        this.lastUpdate = this.lastUpdate + arg1
        if this.lastUpdate >= 1.0 then
            WCS_Statistics:UpdateDisplay()
            this.lastUpdate = 0
        end
    end)
end

function WCS_Statistics:OnEvent(ev, msg)
    if ev == "PLAYER_REGEN_DISABLED" then
        combatStats.inCombat = true
        combatStats.lastCombatStart = GetTime()   -- GetTime() en vez de time()

    elseif ev == "PLAYER_REGEN_ENABLED" then
        if combatStats.inCombat then
            local combatDuration = GetTime() - combatStats.lastCombatStart
            combatStats.combatTime = combatStats.combatTime + combatDuration
            combatStats.inCombat = false
        end

    elseif ev == "CHAT_MSG_COMBAT_SELF_HITS"
        or ev == "CHAT_MSG_SPELL_SELF_DAMAGE"
        or ev == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        self:ParseDamage(msg)

    elseif ev == "PLAYER_DEAD" then
        combatStats.deaths = combatStats.deaths + 1

    elseif ev == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        if msg and (string.find(msg, "dies") or string.find(msg, "muere")) then
            combatStats.kills = combatStats.kills + 1
        end
    end
end

function WCS_Statistics:ParseDamage(msg)
    if not msg then return end
    local _, _, damage = string.find(msg, "for (%d+)")
    if damage then
        combatStats.totalDamage = combatStats.totalDamage + tonumber(damage)
    end

    local _, _, spell = string.find(msg, "Your (.-) hits")
    if not spell then
        _, _, spell = string.find(msg, "Your (.-) crits")
    end

    if spell then
        if not combatStats.spellsCast[spell] then
            combatStats.spellsCast[spell] = {count = 0, damage = 0}
        end
        combatStats.spellsCast[spell].count = combatStats.spellsCast[spell].count + 1
        if damage then
            combatStats.spellsCast[spell].damage = combatStats.spellsCast[spell].damage + tonumber(damage)
        end
    end
end

function WCS_Statistics:UpdateDisplay()
    if not self.panel or not self.panel:IsVisible() then return end

    self.panel.damageText:SetText("|cffffaa00Daño Total:|r " .. combatStats.totalDamage)

    local dps = 0
    if combatStats.combatTime > 0 then
        dps = math.floor(combatStats.totalDamage / combatStats.combatTime)
    end
    self.panel.dpsText:SetText("|cffffaa00DPS Promedio:|r " .. dps)
    self.panel.healingText:SetText("|cffffaa00Curación Total:|r " .. combatStats.totalHealing)

    local minutes = math.floor(combatStats.combatTime / 60)
    local seconds = math.floor(math.mod(combatStats.combatTime, 60))
    self.panel.timeText:SetText("|cffffaa00Tiempo en Combate:|r " .. minutes .. "m " .. seconds .. "s")

    self.panel.killsText:SetText("|cff00ff00Kills:|r " .. combatStats.kills)
    self.panel.deathsText:SetText("|cffff0000Deaths:|r " .. combatStats.deaths)

    local kd = 0
    if combatStats.deaths > 0 then
        kd = combatStats.kills / combatStats.deaths
    else
        kd = combatStats.kills
    end
    self.panel.kdText:SetText(string.format("|cffffaa00K/D Ratio:|r %.2f", kd))

    -- Construir lista de hechizos — Lua 5.0: pairs() con iteración correcta
    local spellList = {}
    for spell, data in pairs(combatStats.spellsCast) do
        table.insert(spellList, {name = spell, count = data.count, damage = data.damage})
    end

    table.sort(spellList, function(a, b) return a.damage > b.damage end)

    local spellText = ""
    for i = 1, math.min(10, table.getn(spellList)) do
        local sp = spellList[i]
        local avgDmg = 0
        if sp.count > 0 then
            avgDmg = math.floor(sp.damage / sp.count)
        end
        spellText = spellText .. string.format("%d. %s: %d usos, %d daño (avg: %d)\n",
            i, sp.name, sp.count, sp.damage, avgDmg)
    end

    if spellText == "" then
        spellText = "Sin datos de combate aún..."
    end
    self.panel.spellsList:SetText(spellText)
end

function WCS_Statistics:ResetStats()
    combatStats.totalDamage    = 0
    combatStats.totalHealing   = 0
    combatStats.spellsCast     = {}
    combatStats.combatTime     = 0
    combatStats.kills          = 0
    combatStats.deaths         = 0
    combatStats.sessionStart   = GetTime()
    combatStats.inCombat       = false
    self:UpdateDisplay()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[WCS Statistics]|r Estadísticas reseteadas")
end

function WCS_Statistics:Show()
    if self.panel then
        self.panel:Show()
        self:UpdateDisplay()
    end
end

function WCS_Statistics:Hide()
    if self.panel then self.panel:Hide() end
end

_G["WCS_Statistics"] = WCS_Statistics
