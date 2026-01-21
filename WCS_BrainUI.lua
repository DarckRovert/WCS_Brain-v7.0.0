--[[
    WCS_BrainUI.lua - Interfaz Grafica del Cerebro Central v6.6.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Diseno Warlock con tema purpura/verde fel
    
    Autor: Elnazzareno (DarckRovert)
    Twitch: twitch.tv/darckrovert
    Kick: kick.com/darckrovert
]]--

WCS_BrainUI = WCS_BrainUI or {}
WCS_BrainUI.VERSION = "6.6.0"
WCS_BrainUI.AUTHOR = "Elnazzareno (DarckRovert)"

-- ============================================================================
-- COLORES WARLOCK
-- ============================================================================
local COLORS = {
    -- Tema principal
    WARLOCK_PURPLE = {0.58, 0.51, 0.79},
    FEL_GREEN = {0.0, 1.0, 0.5},
    SHADOW = {0.4, 0.2, 0.6},
    
    -- Estados
    HEALTH_HIGH = {0.0, 0.9, 0.3},
    HEALTH_MED = {1.0, 0.7, 0.0},
    HEALTH_LOW = {1.0, 0.2, 0.2},
    MANA = {0.0, 0.5, 1.0},
    
    -- Fases
    PHASE_IDLE = {0.4, 0.4, 0.4},
    PHASE_SUSTAIN = {0.0, 0.8, 0.4},
    PHASE_EXECUTE = {1.0, 0.5, 0.0},
    PHASE_EMERGENCY = {1.0, 0.1, 0.1},
    
    -- UI
    BG_DARK = {0.08, 0.06, 0.12},
    BG_SECTION = {0.12, 0.10, 0.18},
    BORDER = {0.5, 0.4, 0.7},
    TEXT_DIM = {0.6, 0.6, 0.6},
    TEXT_BRIGHT = {1.0, 1.0, 1.0},
    GOLD = {1.0, 0.82, 0.0}
}

-- ============================================================================
-- UTILIDADES
-- ============================================================================
local function CreateSection(parent, x, y, width, height, title)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    frame:SetBackdropColor(COLORS.BG_SECTION[1], COLORS.BG_SECTION[2], COLORS.BG_SECTION[3], 0.95)
    frame:SetBackdropBorderColor(COLORS.BORDER[1], COLORS.BORDER[2], COLORS.BORDER[3], 0.8)
    
    if title then
        local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
        titleText:SetText("|cFF9482C9" .. title .. "|r")
    end
    
    return frame
end

local function CreateStatusBar(parent, x, y, width, height, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    bar:SetWidth(width)
    bar:SetHeight(height)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(color[1], color[2], color[3], 1)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(100)
    
    -- Fondo de la barra
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bg:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- Texto
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetText("100%")
    bar.text = text
    
    return bar
end

-- ============================================================================
-- CREAR FRAME PRINCIPAL
-- ============================================================================
function WCS_BrainUI:CreateMainFrame()
    if self.MainFrame then return self.MainFrame end
    
    local f = CreateFrame("Frame", "WCSBrainMainFrame", UIParent)
    f:SetWidth(320)
    f:SetHeight(645)
    f:SetPoint("CENTER", UIParent, "CENTER", 350, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetFrameStrata("MEDIUM")
    
    -- Fondo principal oscuro
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    f:SetBackdropColor(COLORS.BG_DARK[1], COLORS.BG_DARK[2], COLORS.BG_DARK[3], 0.97)
    f:SetBackdropBorderColor(COLORS.WARLOCK_PURPLE[1], COLORS.WARLOCK_PURPLE[2], COLORS.WARLOCK_PURPLE[3], 1)
    
    -- Header con titulo
    self:CreateHeader(f)
    
    -- Secciones
    self:CreatePhaseSection(f)
    self:CreateStatsSection(f)
    self:CreateDecisionSection(f)
    self:CreateMLSection(f)
    self:CreateSystemsSection(f)
    self:CreateControlsSection(f)
    
    self.MainFrame = f
    
    -- Iniciar actualizacion
    self:StartUpdate()
    
    return f
end

-- ============================================================================
-- HEADER
-- ============================================================================
function WCS_BrainUI:CreateHeader(parent)
    -- Titulo principal
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", parent, "TOP", 0, -12)
    title:SetText("|cFF9482C9WCS|r |cFF00FF00BRAIN|r")
    
    -- Subtitulo con version
    local subtitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cFF666666Cerebro Central Inteligente v" .. self.VERSION .. "|r")
    
    -- Creditos del autor
    local author = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    author:SetPoint("TOP", subtitle, "BOTTOM", 0, -1)
    author:SetText("|cFF888888by |cFF9482C9" .. self.AUTHOR .. "|r")
    
    -- Boton cerrar
    local closeBtn = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() WCS_BrainUI:Toggle() end)
    
    -- Linea separadora
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -52)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, -52)
    line:SetHeight(1)
    line:SetTexture(1, 1, 1, 0.2)
end

-- ============================================================================
-- SECCION: FASE DE COMBATE
-- ============================================================================
function WCS_BrainUI:CreatePhaseSection(parent)
    local section = CreateSection(parent, 10, -60, 300, 40, nil)
    
    -- Indicador de fase (izquierda)
    local phaseText = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phaseText:SetPoint("LEFT", section, "LEFT", 15, 0)
    phaseText:SetText("|cFF888888IDLE|r")
    self.phaseText = phaseText
    self.phaseSection = section
    
    -- Indicador de MOVIMIENTO (derecha, grande y visible)
    local movingIndicator = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    movingIndicator:SetPoint("RIGHT", section, "RIGHT", -15, 0)
    movingIndicator:SetText("")  -- Vacio por defecto
    self.movingIndicator = movingIndicator
end

-- ============================================================================
-- SECCION: ESTADISTICAS (HP, Mana, Pet)
-- ============================================================================
function WCS_BrainUI:CreateStatsSection(parent)
    local section = CreateSection(parent, 10, -110, 300, 95, "Estado")
    
    -- Barra de HP
    local hpLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpLabel:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -22)
    hpLabel:SetText("|cFF00FF00HP|r")
    
    local hpBar = CreateStatusBar(section, 35, -20, 180, 14, COLORS.HEALTH_HIGH)
    self.hpBar = hpBar
    
    local hpPct = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpPct:SetPoint("LEFT", hpBar, "RIGHT", 5, 0)
    hpPct:SetText("100%")
    self.hpPct = hpPct
    
    -- Barra de Mana
    local manaLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    manaLabel:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -40)
    manaLabel:SetText("|cFF0088FFMP|r")
    
    local manaBar = CreateStatusBar(section, 35, -38, 180, 14, COLORS.MANA)
    self.manaBar = manaBar
    
    local manaPct = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    manaPct:SetPoint("LEFT", manaBar, "RIGHT", 5, 0)
    manaPct:SetText("100%")
    self.manaPct = manaPct
    
    -- Info de Target
    local targetText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -58)
    targetText:SetText("|cFFFF6666Target:|r |cFF888888Ninguno|r")
    self.targetText = targetText
    
    -- Info de Pet
    local petText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    petText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -74)
    petText:SetText("|cFFCC99FFPet:|r |cFF888888Ninguno|r")
    self.petText = petText
end

-- ============================================================================
-- SECCION: DECISION ACTUAL
-- ============================================================================
function WCS_BrainUI:CreateDecisionSection(parent)
    local section = CreateSection(parent, 10, -215, 300, 100, "Decision")
    
    -- Hechizo recomendado (grande)
    local spellFrame = CreateFrame("Frame", nil, section)
    spellFrame:SetPoint("TOPLEFT", section, "TOPLEFT", 8, -22)
    spellFrame:SetWidth(284)
    spellFrame:SetHeight(50)
    spellFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    spellFrame:SetBackdropColor(0.15, 0.1, 0.05, 0.9)
    spellFrame:SetBackdropBorderColor(COLORS.GOLD[1], COLORS.GOLD[2], COLORS.GOLD[3], 0.8)
    
    local spellName = spellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    spellName:SetPoint("TOP", spellFrame, "TOP", 0, -8)
    spellName:SetText("|cFFFFCC00Esperando...|r")
    self.spellName = spellName
    
    local spellReason = spellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellReason:SetPoint("TOP", spellName, "BOTTOM", 0, -4)
    spellReason:SetText("|cFF888888Sin combate|r")
    self.spellReason = spellReason
    
    -- Score (si existe)
    local scoreText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scoreText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -78)
    scoreText:SetText("|cFF666666Score: --|r")
    self.scoreText = scoreText
    
    -- Prioridad
    local priorityText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priorityText:SetPoint("TOPRIGHT", section, "TOPRIGHT", -10, -78)
    priorityText:SetText("|cFF666666Prioridad: --|r")
    self.priorityText = priorityText
end

-- ============================================================================
-- SECCION: MACHINE LEARNING
-- ============================================================================
function WCS_BrainUI:CreateMLSection(parent)
    local section = CreateSection(parent, 10, -325, 300, 85, "Aprendizaje (ML)")
    
    -- Combates
    local combatsText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    combatsText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -22)
    combatsText:SetText("|cFFAAAAAACombates:|r |cFFFFFFFF0|r")
    self.combatsText = combatsText
    
    -- Victorias
    local winsText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    winsText:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -38)
    winsText:SetText("|cFF00FF00Victorias:|r |cFFFFFFFF0 (0%)|r")
    self.winsText = winsText
    
    -- DPS Promedio
    local dpsText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dpsText:SetPoint("TOPLEFT", section, "TOPLEFT", 150, -22)
    dpsText:SetText("|cFFFFAA00DPS Avg:|r |cFFFFFFFF0|r")
    self.dpsText = dpsText
    
    -- Tiempo total
    local timeText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("TOPLEFT", section, "TOPLEFT", 150, -38)
    timeText:SetText("|cFF8888FFTiempo:|r |cFFFFFFFF0m|r")
    self.timeText = timeText
    
    -- Estado del aprendizaje
    local mlStatus = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mlStatus:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -58)
    mlStatus:SetText("|cFF666666Estado: Recopilando datos...|r")
    self.mlStatus = mlStatus
end

-- ============================================================================
-- SECCION: ESTADO DE SISTEMAS
-- ============================================================================
function WCS_BrainUI:CreateSystemsSection(parent)
    local section = CreateSection(parent, 10, -420, 300, 110, "Sistemas")
    
    -- Indicadores de estado - Primera fila (Core)
    local systemsRow1 = {
        {name = "Brain", x = 10, check = function() return WCS_Brain and WCS_Brain.ENABLED end},
        {name = "AI", x = 65, check = function() return WCS_BrainAI ~= nil end},
        {name = "ML", x = 100, check = function() return WCS_BrainML and WCS_BrainML.Data end},
        {name = "Core", x = 135, check = function() return WCS_BrainCore ~= nil end},
        {name = "SpellDB", x = 180, check = function() return WCS_SpellDB ~= nil end},
        {name = "Integ", x = 240, check = function() return WCS_BrainIntegration ~= nil end}
    }
    
    -- Segunda fila - DQN y State
    local systemsRow2 = {
        {name = "DQN", x = 10, check = function() return WCS_BrainDQN and WCS_BrainDQN.enabled end},
        {name = "State", x = 55, check = function() return WCS_BrainState ~= nil end},
        {name = "Reward", x = 110, check = function() return WCS_BrainReward ~= nil end},
        {name = "DQNBtn", x = 170, check = function() return WCS_BrainDQNButton ~= nil end},
        {name = "DQNUI", x = 230, check = function() return WCS_BrainDQNUI ~= nil end}
    }
    
    -- Tercera fila - Sistemas de mascota
    local systemsRow3 = {
        {name = "PetAI", x = 10, check = function() return WCS_BrainPetAI_IsEnabled and WCS_BrainPetAI_IsEnabled() end},
        {name = "PetSocial", x = 70, check = function() return WCS_Brain and WCS_Brain.Pet and WCS_Brain.Pet.Social and WCS_Brain.Pet.Social.Config and WCS_Brain.Pet.Social.Config.enabled end},
        {name = "PetUI", x = 155, check = function() return WCS_BrainPetUI ~= nil end},
        {name = "Button", x = 210, check = function() return WCS_BrainButton ~= nil end}
    }
    
    self.systemIndicators = {}
    
    -- Crear indicadores primera fila
    for i, sys in ipairs(systemsRow1) do
        local indicator = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        indicator:SetPoint("TOPLEFT", section, "TOPLEFT", sys.x, -22)
        indicator:SetText("|cFF888888[?]|r")
        
        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", indicator, "RIGHT", 2, 0)
        label:SetText("|cFFAAAAAA" .. sys.name .. "|r")
        
        self.systemIndicators[sys.name] = {indicator = indicator, check = sys.check}
    end
    
    -- Crear indicadores segunda fila (DQN - color fel green)
    for i, sys in ipairs(systemsRow2) do
        local indicator = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        indicator:SetPoint("TOPLEFT", section, "TOPLEFT", sys.x, -40)
        indicator:SetText("|cFF888888[?]|r")
        
        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", indicator, "RIGHT", 2, 0)
        label:SetText("|cFF00FF80" .. sys.name .. "|r")
        
        self.systemIndicators[sys.name] = {indicator = indicator, check = sys.check}
    end
    
    -- Crear indicadores tercera fila (Pet - color purple)
    for i, sys in ipairs(systemsRow3) do
        local indicator = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        indicator:SetPoint("TOPLEFT", section, "TOPLEFT", sys.x, -58)
        indicator:SetText("|cFF888888[?]|r")
        
        local label = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", indicator, "RIGHT", 2, 0)
        label:SetText("|cFFCC99FF" .. sys.name .. "|r")
        
        self.systemIndicators[sys.name] = {indicator = indicator, check = sys.check}
    end
end

-- ============================================================================
-- SECCION: CONTROLES
-- ============================================================================
function WCS_BrainUI:CreateControlsSection(parent)
    local section = CreateSection(parent, 10, -540, 300, 85, nil)
    
    -- Fila de botones

    -- Botón ON/OFF
    local toggleBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    toggleBtn:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -22)
    toggleBtn:SetWidth(60)
    toggleBtn:SetHeight(22)
    toggleBtn:SetText("ON")
    self.toggleBtn = toggleBtn
    toggleBtn:SetScript("OnClick", function()
        if WCS_Brain then
            WCS_Brain.ENABLED = not WCS_Brain.ENABLED
            WCS_BrainUI:Update()
        end
    end)

    -- Botón Debug
    local debugBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    debugBtn:SetPoint("LEFT", toggleBtn, "RIGHT", 8, 0)
    debugBtn:SetWidth(60)
    debugBtn:SetHeight(22)
    debugBtn:SetText("Debug")
    self.debugBtn = debugBtn
    debugBtn:SetScript("OnClick", function()
        if WCS_Brain then
            WCS_Brain.DEBUG = not WCS_Brain.DEBUG
            WCS_BrainUI:Update()
        end
    end)

    -- Botón ML
    local mlBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    mlBtn:SetPoint("LEFT", debugBtn, "RIGHT", 8, 0)
    mlBtn:SetWidth(60)
    mlBtn:SetHeight(22)
    mlBtn:SetText("ML")
    self.mlBtn = mlBtn
    mlBtn:SetScript("OnClick", function()
        if WCS_BrainML and WCS_BrainML.ToggleUI then
            WCS_BrainML:ToggleUI()
        end
    end)

    -- Botón CAST
    local castBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    castBtn:SetPoint("LEFT", mlBtn, "RIGHT", 8, 0)
    castBtn:SetWidth(60)
    castBtn:SetHeight(22)
    castBtn:SetText("Cast")
    self.castBtn = castBtn
    castBtn:SetScript("OnClick", function()
        if WCS_Brain then
            WCS_Brain:Execute()
        end
    end)

    -- Botón RESET MEMORIA (debajo de ML y Cast)
    local resetBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -75)
    resetBtn:SetWidth(90)
    resetBtn:SetHeight(22)
    resetBtn:SetText("Reset Mem")
    self.resetBtn = resetBtn
    resetBtn:SetScript("OnClick", function()
        if WCS_Brain and WCS_Brain.ResetMemory then
            WCS_Brain:ResetMemory()
            WCS_BrainUI:Update()
        end
    end)

    -- Botón RESET STATS ML (debajo de ML y Cast, a la derecha de Reset Mem)
    local resetStatsBtn = CreateFrame("Button", nil, section, "UIPanelButtonTemplate")
    resetStatsBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)
    resetStatsBtn:SetWidth(100)
    resetStatsBtn:SetHeight(22)
    resetStatsBtn:SetText("Reset Stats")
    self.resetStatsBtn = resetStatsBtn
    resetStatsBtn:SetScript("OnClick", function()
        if WCS_BrainML and WCS_BrainML.ResetStats then
            WCS_BrainML:ResetStats()
            WCS_BrainUI:Update()
        end
    end)

    -- === CHECKBOX PET AI ===
    local petAICheck = CreateFrame("CheckButton", "WCS_PetAICheckbox", section, "UICheckButtonTemplate")
    petAICheck:SetWidth(24)
    petAICheck:SetHeight(24)
    petAICheck:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -45)
    petAICheck:SetChecked(true)
    petAICheck:SetScript("OnClick", function()
        if WCS_BrainPetAI_SetEnabled then
            WCS_BrainPetAI_SetEnabled(this:GetChecked())
        end
    end)
    self.petAICheck = petAICheck
    
    local petAILabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    petAILabel:SetPoint("LEFT", petAICheck, "RIGHT", 2, 0)
    petAILabel:SetText("|cFFCC99FFPet AI|r")
    
    -- Estado de PetAI
    local petAIStatus = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    petAIStatus:SetPoint("LEFT", petAILabel, "RIGHT", 10, 0)
    petAIStatus:SetText("|cFF888888(Cargando...)|r")
    self.petAIStatus = petAIStatus
end

-- ============================================================================
-- ACTUALIZACION EN TIEMPO REAL
-- ============================================================================
function WCS_BrainUI:Update()
    if not self.MainFrame or not self.MainFrame:IsVisible() then return end
    if not WCS_Brain then return end
    
    local ctx = WCS_Brain.Context
    
    -- === FASE ===
    local phase = ctx.phase or "idle"
    local isMoving = ctx.player.isMoving or false
    local phaseColors = {
        idle = {COLORS.PHASE_IDLE, "IDLE"},
        sustain = {COLORS.PHASE_SUSTAIN, "SUSTAIN"},
        execute = {COLORS.PHASE_EXECUTE, "EXECUTE"},
        emergency = {COLORS.PHASE_EMERGENCY, "EMERGENCY"}
    }
    local phaseData = phaseColors[phase] or phaseColors.idle
    local phaseText = phaseData[2]
    
    self.phaseText:SetText("|cFF" .. self:ColorToHex(phaseData[1]) .. phaseText .. "|r")
    self.phaseSection:SetBackdropColor(phaseData[1][1] * 0.2, phaseData[1][2] * 0.2, phaseData[1][3] * 0.2, 0.9)
    
    -- Indicador de movimiento grande y visible
    if isMoving then
        self.movingIndicator:SetText("|cFFFF6600>>> MOVIENDO <<<|r")
    else
        self.movingIndicator:SetText("")
    end
    
    -- === HP ===
    local hp = ctx.player.healthPct or 100
    self.hpBar:SetValue(hp)
    -- Mostrar [MOV] junto al HP si esta en movimiento
    local movIndicator = isMoving and " |cFFFF6600[MOV]|r" or ""
    self.hpPct:SetText(math.floor(hp) .. "%" .. movIndicator)
    local hpColor = hp > 60 and COLORS.HEALTH_HIGH or (hp > 30 and COLORS.HEALTH_MED or COLORS.HEALTH_LOW)
    self.hpBar:SetStatusBarColor(hpColor[1], hpColor[2], hpColor[3])
    
    -- === MANA ===
    local mp = ctx.player.manaPct or 100
    self.manaBar:SetValue(mp)
    self.manaPct:SetText(math.floor(mp) .. "%")
    
    -- === TARGET ===
    if ctx.target.exists then
        local thp = ctx.target.healthPct or 100
        local tclass = ctx.target.classification or "normal"
        local tcolor = thp > 35 and "FFFFFF" or "FF6600"
        self.targetText:SetText("|cFFFF6666Target:|r |cFF" .. tcolor .. math.floor(thp) .. "% [" .. tclass .. "]|r")
    else
        self.targetText:SetText("|cFFFF6666Target:|r |cFF666666Ninguno|r")
    end
    
    -- === PET ===
    if ctx.pet.exists then
        local php = ctx.pet.healthPct or 100
        local ptype = ctx.pet.type or "unknown"
        local pcolor = php > 50 and "CC99FF" or "FF6666"
        self.petText:SetText("|cFFCC99FFPet:|r |cFF" .. pcolor .. ptype .. " " .. math.floor(php) .. "%|r")
    else
        self.petText:SetText("|cFFCC99FFPet:|r |cFF666666Ninguno|r")
    end
    
    -- === DECISION ===
    local action = nil
    if WCS_BrainAI and WCS_BrainAI.GetBestAction then
        action = WCS_BrainAI:GetBestAction()
    else
        action = WCS_Brain:GetNextAction()
    end
    
    if action then
        self.spellName:SetText("|cFFFFCC00" .. (action.spell or "?") .. "|r")
        
        -- Mostrar razon, con indicador si es instant mientras nos movemos
        local reason = action.reason or ""
        if isMoving then
            reason = reason .. " |cFF00FF00(instant)|r"
        end
        self.spellReason:SetText("|cFFAAAAAA" .. reason .. "|r")
        
        local score = action.score or 0
        self.scoreText:SetText("|cFF888888Score:|r |cFFFFFFFF" .. math.floor(score) .. "|r")
        
        local prio = action.priority or 0
        local prioNames = {"Emergency", "Interrupt", "Defensive", "PetSave", "PetAction", "Synergy", "DoTs", "Curse", "Filler", "Mana"}
        local prioName = prioNames[prio] or "?"
        self.priorityText:SetText("|cFF888888Prio:|r |cFFFFFFFF" .. prioName .. "|r")
    else
        -- Sin accion disponible
        if isMoving then
            self.spellName:SetText("|cFFFFAA00Solo Instants|r")
            self.spellReason:SetText("|cFF888888Moviendose - usa DoTs/Curses|r")
        else
            self.spellName:SetText("|cFF666666Esperando...|r")
            self.spellReason:SetText("|cFF444444Sin combate|r")
        end
        self.scoreText:SetText("|cFF666666Score: --|r")
        self.priorityText:SetText("|cFF666666Prio: --|r")
    end
    
    -- === ML STATS ===
    if WCS_BrainML and WCS_BrainML.Data then
        local stats = WCS_BrainML.Data.globalStats
        self.combatsText:SetText("|cFFAAAAAACombates:|r |cFFFFFFFF" .. (stats.totalCombats or 0) .. "|r")
        
        local winRate = 0
        if stats.totalCombats and stats.totalCombats > 0 then
            winRate = ((stats.wins or 0) / stats.totalCombats) * 100
        end
        self.winsText:SetText("|cFF00FF00Victorias:|r |cFFFFFFFF" .. (stats.wins or 0) .. " (" .. string.format("%.0f", winRate) .. "%)|r")
        
        self.dpsText:SetText("|cFFFFAA00DPS Avg:|r |cFFFFFFFF" .. string.format("%.1f", stats.avgDPS or 0) .. "|r")
        
        local timeMin = (stats.totalTime or 0) / 60
        self.timeText:SetText("|cFF8888FFTiempo:|r |cFFFFFFFF" .. string.format("%.1f", timeMin) .. "m|r")
        
        -- Estado del ML
        if stats.totalCombats < 3 then
            self.mlStatus:SetText("|cFFFFAA00Recopilando datos... (" .. (stats.totalCombats or 0) .. "/3)|r")
        else
            self.mlStatus:SetText("|cFF00FF00Aprendizaje activo|r")
        end
    else
        self.combatsText:SetText("|cFFAAAAAACombates:|r |cFF6666660|r")
        self.winsText:SetText("|cFF00FF00Victorias:|r |cFF6666660|r")
        self.dpsText:SetText("|cFFFFAA00DPS Avg:|r |cFF6666660|r")
        self.timeText:SetText("|cFF8888FFTiempo:|r |cFF6666660m|r")
        self.mlStatus:SetText("|cFFFF6666ML no cargado|r")
    end
    
    -- === BOTONES ===
    if self.toggleBtn and WCS_Brain then
        if WCS_Brain.ENABLED then
            self.toggleBtn:SetText("|cFF00FF00ON|r")
        else
            self.toggleBtn:SetText("|cFFFF0000OFF|r")
        end
    end
    
    if self.debugBtn and WCS_Brain then
        if WCS_Brain.DEBUG then
            self.debugBtn:SetText("|cFFFFFF00Dbg|r")
        else
            self.debugBtn:SetText("Debug")
        end
    end
    
    -- === PET AI CHECKBOX ===
    if self.petAICheck then
        local petAIEnabled = WCS_BrainPetAI_IsEnabled and WCS_BrainPetAI_IsEnabled() or false
        self.petAICheck:SetChecked(petAIEnabled)
        
        if self.petAIStatus then
            if UnitExists("pet") then
                local petName = UnitName("pet") or "Desconocido"
                local petType = ""
                if WCS_BrainPetAI and WCS_BrainPetAI.GetPetType then
                    petType = WCS_BrainPetAI:GetPetType() or ""
                end
                local statusColor = petAIEnabled and "00FF00" or "FF0000"
                local statusText = petAIEnabled and "ON" or "OFF"
                -- Mostrar: ON/OFF - NombreMascota (Tipo)
                self.petAIStatus:SetText("|cFF" .. statusColor .. statusText .. "|r - |cFFCC99FF" .. petName .. "|r (" .. petType .. ")")
            else
                self.petAIStatus:SetText("|cFF888888Sin mascota|r")
            end
        end
    end
    
    -- === INDICADORES DE SISTEMAS ===
    if self.systemIndicators then
        for name, data in pairs(self.systemIndicators) do
            local isActive = false
            if data.check then
                -- Llamar la funcion de verificacion de forma segura
                local ok, result = pcall(data.check)
                if ok then
                    isActive = result
                end
            end
            
            if isActive then
                data.indicator:SetText("|cFF00FF00[*]|r")
            else
                data.indicator:SetText("|cFFFF0000[x]|r")
            end
        end
    end
end

function WCS_BrainUI:ColorToHex(color)
    local r = math.floor(color[1] * 255)
    local g = math.floor(color[2] * 255)
    local b = math.floor(color[3] * 255)
    return string.format("%02X%02X%02X", r, g, b)
end

function WCS_BrainUI:StartUpdate()
    if not self.updateFrame then
        self.updateFrame = CreateFrame("Frame")
        self.updateFrame.elapsed = 0
        self.updateFrame:SetScript("OnUpdate", function()
            this.elapsed = this.elapsed + arg1
            -- Optimizado: actualizar solo cada 0.5s (UI no necesita alta frecuencia)
            if this.elapsed >= 0.5 then
                this.elapsed = 0
                WCS_BrainUI:Update()
            end
        end)
    end
    
    -- Registrar con UpdateManager si está disponible
    if WCS_UpdateManager then
        WCS_UpdateManager:RegisterCallback("ui", "BrainUI", function()
            WCS_BrainUI:Update()
        end)
        -- Desactivar OnUpdate local si usamos UpdateManager
        if self.updateFrame then
            self.updateFrame:SetScript("OnUpdate", nil)
        end
    end
end

-- ============================================================================
-- TOGGLE Y SHOW
-- ============================================================================
function WCS_BrainUI:Toggle()
    if not self.MainFrame then
        self:CreateMainFrame()
    end
    
    if self.MainFrame:IsVisible() then
        self.MainFrame:Hide()
    else
        self.MainFrame:Show()
    end
end

function WCS_BrainUI:Show()
    if not self.MainFrame then
        self:CreateMainFrame()
    end
    self.MainFrame:Show()
end

function WCS_BrainUI:Hide()
    if self.MainFrame then
        self.MainFrame:Hide()
    end
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSBRAINUI1 = "/brainui"
SLASH_WCSBRAINUI2 = "/wcsui"
SlashCmdList["WCSBRAINUI"] = function(msg)
    WCS_BrainUI:Toggle()
end

-- Mensaje de carga
DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS_BrainUI]|r v" .. WCS_BrainUI.VERSION .. " by |cFF00FF00" .. WCS_BrainUI.AUTHOR .. "|r cargado. Usa |cFFFFCC00/brainui|r para abrir.")

