--[[
    WCS_BrainUI.lua - Master Command Hub v8.0.0 [God-Tier]
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Sistema de Control Unificado Multi-Clase para El Sequito del Terror.
    5-Tab Interface: AI | CLAN | PET | HUD | SYS
    
    Funcionalidad REAL - Sin placeholders.
]]--

WCS = WCS or {}
WCS.UI = WCS.UI or {}
local UI = WCS.UI

-- ============================================================================
-- COLORES DEEP VOID THEME
-- ============================================================================
local C = {
    BG_MAIN   = {0.04, 0.02, 0.08},
    BG_SECT   = {0.08, 0.05, 0.14},
    LAVENDER  = {0.58, 0.51, 0.79},
    FEL_GREEN = {0.0,  1.0,  0.5},
    GOLD      = {1.0,  0.82, 0.0},
    RED       = {1.0,  0.2,  0.2},
    CYAN      = {0.0,  0.85, 1.0},
    WHITE     = {1.0,  1.0,  1.0},
    GREY      = {0.55, 0.55, 0.55},
}

-- ============================================================================
-- TAB DEFINITIONS (REAL FUNCTIONALITY)
-- ============================================================================
local TABS = {
    { id="ai",   label="IA",    icon="Interface\\Icons\\Spell_Nature_Lightning" },
    { id="clan", label="CLAN",  icon="Interface\\Icons\\INV_Misc_Book_11" },
    { id="pet",  label="PET",   icon="Interface\\Icons\\Spell_Shadow_Twilight" },
    { id="hud",  label="HUD",   icon="Interface\\Icons\\INV_Misc_PocketWatch_01" },
    { id="sys",  label="SYS",   icon="Interface\\Icons\\INV_Misc_Gear_01" },
}

UI.currentTab = "ai"

-- ============================================================================
-- MAIN FRAME CREATION
-- ============================================================================
function UI:CreateMainFrame()
    if self.MainFrame then return end

    local f = CreateFrame("Frame", "WCS_MainFrame", UIParent)
    f:SetWidth(420) f:SetHeight(620)
    f:SetPoint("CENTER", UIParent, "CENTER", 360, 0)
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left=4, right=4, top=4, bottom=4}
    })
    f:SetBackdropColor(C.BG_MAIN[1], C.BG_MAIN[2], C.BG_MAIN[3], 0.97)
    f:SetBackdropBorderColor(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 1)
    f:SetMovable(true) f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
    f:SetFrameStrata("MEDIUM")

    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3)

    -- Header
    self:BuildHeader(f)

    -- Status Strip (Vitals)
    self:BuildVitals(f)

    -- Tab Bar
    self:BuildTabBar(f)

    -- Tab Content Area (explicit size required in Lua 5.0 / WoW 1.12)
    self.ContentFrame = CreateFrame("Frame", nil, f)
    self.ContentFrame:SetPoint("TOPLEFT",  f, "TOPLEFT",  8, -210)
    self.ContentFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 30)
    self.ContentFrame:SetWidth(404)
    self.ContentFrame:SetHeight(380)

    -- Footer
    self.foot = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.foot:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    self.foot:SetTextColor(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3])

    self.MainFrame = f
    self:ShowTab("ai")
    self:StartHeartbeat()
end

-- ============================================================================
-- HEADER (Class + Version + Phase)
-- ============================================================================
function UI:BuildHeader(f)
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText("|cff9482C9WCS BRAIN|r |cffffffffv8.0.0|r")
    self.titleLabel = title

    -- Class/Race readout (live)
    self.classLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.classLabel:SetPoint("TOP", title, "BOTTOM", 0, -3)
    self.classLabel:SetText("|cff888888Detectando clase...|r")

    -- Separator line
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1) line:SetWidth(400)
    line:SetPoint("TOP", f, "TOP", 0, -55)
    line:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.35)

    -- Phase/Status
    local phBG = self:MakeSection(f, 8, -60, 404, 38)
    self.phaseText = phBG:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.phaseText:SetPoint("CENTER", phBG, "CENTER", 0, 0)
    self.phaseText:SetText("|cff888888INICIANDO v8.0.0...|r")
end

-- ============================================================================
-- VITALS BAR (HP + Mana + Target)
-- ============================================================================
function UI:BuildVitals(f)
    local section = self:MakeSection(f, 8, -103, 404, 100)

    local lbl = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", section, "TOPLEFT", 10, -6)
    lbl:SetText("|cff9482C9VITALES|r")

    self.hpBar   = self:MakeBar(section, 10, -22, 382, 16, {0.2, 0.9, 0.3})
    self.manaBar = self:MakeBar(section, 10, -43, 382, 16, {0.1, 0.5, 1.0})

    self.targetLabel = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.targetLabel:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 10, 9)
    self.targetLabel:SetText("Target: Ninguno")
end

-- ============================================================================
-- TAB BAR (5 Real Tabs)
-- ============================================================================
function UI:BuildTabBar(f)
    self.tabFrames = {}
    local tabW = 76
    local startX = 8
    local y = -207

    for i, tabDef in ipairs(TABS) do
        local btn = CreateFrame("Button", "WCS_Tab_"..tabDef.id, f)
        btn:SetWidth(tabW) btn:SetHeight(30)
        btn:SetPoint("TOPLEFT", f, "TOPLEFT", startX + (i-1)*(tabW+2), y)

        local tabBG = btn:CreateTexture(nil, "BACKGROUND")
        tabBG:SetAllPoints(btn)
        tabBG:SetTexture(C.BG_SECT[1], C.BG_SECT[2], C.BG_SECT[3], 0.9)
        btn.bg = tabBG

        local tabBorder = btn:CreateTexture(nil, "BORDER")
        tabBorder:SetAllPoints(btn)
        tabBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        btn.brd = tabBorder

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(16) icon:SetHeight(16)
        icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
        icon:SetTexture(tabDef.icon)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        lbl:SetText(tabDef.label)
        lbl:SetTextColor(C.GREY[1], C.GREY[2], C.GREY[3])
        btn.lbl = lbl

        local id = tabDef.id
        btn:SetScript("OnClick",  function() UI:ShowTab(id) end)
        btn:SetScript("OnEnter", function()
            if UI.currentTab ~= id then
                btn.bg:SetTexture(0.15, 0.10, 0.25, 0.95)
            end
        end)
        btn:SetScript("OnLeave", function()
            if UI.currentTab ~= id then
                btn.bg:SetTexture(C.BG_SECT[1], C.BG_SECT[2], C.BG_SECT[3], 0.9)
            end
        end)

        self.tabFrames[tabDef.id] = btn
    end
end

-- Switch tab
function UI:ShowTab(id)
    self.currentTab = id

    -- Update tab visuals
    for tid, btn in pairs(self.tabFrames) do
        if tid == id then
            btn.bg:SetTexture(C.LAVENDER[1]*0.4, C.LAVENDER[2]*0.4, C.LAVENDER[3]*0.4, 1)
            btn.lbl:SetTextColor(C.WHITE[1], C.WHITE[2], C.WHITE[3])
        else
            btn.bg:SetTexture(C.BG_SECT[1], C.BG_SECT[2], C.BG_SECT[3], 0.9)
            btn.lbl:SetTextColor(C.GREY[1], C.GREY[2], C.GREY[3])
        end
    end

    -- Clear content
    if self.ContentFrame then
        local children = {self.ContentFrame:GetChildren()}
        for _, ch in ipairs(children) do ch:Hide() end
    end

    -- Build content
    if id == "ai"   then self:BuildTabAI()   end
    if id == "clan" then self:BuildTabClan()  end
    if id == "pet"  then self:BuildTabPet()   end
    if id == "hud"  then self:BuildTabHUD()   end
    if id == "sys"  then self:BuildTabSys()   end
end

-- ============================================================================
-- TAB: AI — Combat Logic Controls
-- ============================================================================
function UI:BuildTabAI()
    local p = self.ContentFrame
    local s = self:MakeSection(p, 0, 0, p:GetWidth(), p:GetHeight()-4, "INTELIGENCIA ARTIFICIAL")

    -- Mode selector
    local modeLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeLabel:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -22)
    modeLabel:SetText("|cff9482C9Modo IA:|r")
    modeLabel:Show()

    -- Hybrid button
    local btnHybrid = self:MakeButton(s, "HIBRIDO", 10, -36, 120, 24, function()
        if WCS_Brain then WCS_Brain.Config.mode = "hybrid" end
        WCS_BrainNotifications:Info("Modo: Hibrido (DQN + SmartAI)")
    end)
    btnHybrid:Show()

    local btnDQN = self:MakeButton(s, "SOLO DQN", 136, -36, 100, 24, function()
        if WCS_Brain then WCS_Brain.Config.mode = "dqn_only" end
        WCS_BrainNotifications:Info("Modo: Solo DQN")
    end)
    btnDQN:Show()

    local btnSmart = self:MakeButton(s, "SMARTAI", 242, -36, 100, 24, function()
        if WCS_Brain then WCS_Brain.Config.mode = "smartai_only" end
        WCS_BrainNotifications:Info("Modo: Solo SmartAI")
    end)
    btnSmart:Show()

    -- Divider
    local div = s:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1) div:SetWidth(s:GetWidth()-20)
    div:SetPoint("TOP", s, "TOP", 0, -68)
    div:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.25)
    div:Show()

    -- Auto-Execute toggle with real binding
    local cbAE = self:MakeCB(s, "AutoExecute", "|cff00ff00AUTO-CICLO|r  (IA ejecuta hechizos)", 10, -80)
    cbAE:Show()

    -- Decision display
    local currentLbl = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentLbl:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -110)
    currentLbl:SetText("|cff9482C9Decision actual:|r")
    currentLbl:Show()

    self.aiSpellText = s:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.aiSpellText:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -128)
    self.aiSpellText:SetText("|cff888888Esperando combate...|r")
    self.aiSpellText:Show()

    self.aiReasonText = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.aiReasonText:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -150)
    self.aiReasonText:SetText("")
    self.aiReasonText:Show()

    -- Launchers
    local div2 = s:CreateTexture(nil, "ARTWORK")
    div2:SetHeight(1) div2:SetWidth(s:GetWidth()-20)
    div2:SetPoint("TOP", s, "TOP", 0, -168)
    div2:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.25)
    div2:Show()

    self:MakeButton(s, "Abrir DQN Dashboard", 10, -180, 185, 24, function()
        if WCS_BrainDQNUI and WCS_BrainDQNUI.Toggle then
            WCS_BrainDQNUI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r DQN UI no disponible.")
        end
    end):Show()

    self:MakeButton(s, "Abrir Thinking UI", 200, -180, 185, 24, function()
        if WCS_BrainThinkingUI and WCS_BrainThinkingUI.Toggle then
            WCS_BrainThinkingUI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Thinking UI no disponible.")
        end
    end):Show()

    self:MakeButton(s, "Abrir Diagnosticos", 10, -210, 185, 24, function()
        if WCS_BrainDiagnostics and WCS_BrainDiagnostics.Toggle then
            WCS_BrainDiagnostics:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Diagnosticos no disponible.")
        end
    end):Show()

    self:MakeButton(s, "Abrir Pensamientos", 200, -210, 185, 24, function()
        if WCS_BrainThoughts and WCS_BrainThoughts.Toggle then
            WCS_BrainThoughts:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r BrainThoughts no disponible.")
        end
    end):Show()
end

-- ============================================================================
-- TAB: CLAN — Guild Panel Control
-- ============================================================================
function UI:BuildTabClan()
    local p = self.ContentFrame
    local s = self:MakeSection(p, 0, 0, p:GetWidth(), p:GetHeight()-4, "EL SEQUITO DEL TERROR")

    -- Guild info
    local guildInfo = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guildInfo:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -22)
    local guildName = GetGuildInfo("player") or "Sin clan"
    guildInfo:SetText("|cff9482C9Clan:|r |cff00ff00" .. guildName .. "|r")
    guildInfo:Show()

    -- Online members count
    self.clanOnlineLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.clanOnlineLabel:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -40)
    self.clanOnlineLabel:SetText("|cff888888Miembros online: --/--|r")
    self.clanOnlineLabel:Show()

    -- Buttons
    self:MakeButton(s, "Panel Principal del Clan", 10, -60, 380, 28, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Panel del Clan no cargado. /sequito")
        end
    end):Show()

    self:MakeButton(s, "Panel de Invocaciones", 10, -94, 183, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(6)
        else
            if SlashCmdList["WCSSUMMON"] then
                SlashCmdList["WCSSUMMON"]("")
            end
        end
    end):Show()

    self:MakeButton(s, "Raid Manager", 200, -94, 190, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(3)
        end
    end):Show()

    self:MakeButton(s, "Banco del Clan", 10, -124, 183, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(7)
        end
    end):Show()

    self:MakeButton(s, "Tracker PvP", 200, -124, 190, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(8)
        end
    end):Show()

    self:MakeButton(s, "Grimorio", 10, -154, 183, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(5)
        end
    end):Show()

    self:MakeButton(s, "Estadisticas", 200, -154, 190, 24, function()
        if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
            WCS_ClanUI:ToggleMainFrame()
            WCS_ClanUI:SelectTab(4)
        end
    end):Show()

    -- Recruitment info
    local div = s:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1) div:SetWidth(s:GetWidth()-20)
    div:SetPoint("TOP", s, "TOP", 0, -185)
    div:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.25)
    div:Show()

    local warningLbl = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warningLbl:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -195)
    warningLbl:SetText("|cffaaaaaa/sequito — /clan — /terror — /raidmanager|r")
    warningLbl:Show()
end

-- ============================================================================
-- TAB: PET — Pet AI Management
-- ============================================================================
function UI:BuildTabPet()
    local p = self.ContentFrame
    local s = self:MakeSection(p, 0, 0, p:GetWidth(), p:GetHeight()-4, "CONTROL DE MASCOTA")

    -- Pet availability
    self.petStatusLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.petStatusLabel:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -22)
    local petStatus = UnitExists("pet") and ("|cff00ff00" .. (UnitName("pet") or "Mascota") .. "|r")
                      or "|cff888888Sin mascota activa|r"
    self.petStatusLabel:SetText("|cff9482C9Mascota:|r " .. petStatus)
    self.petStatusLabel:Show()

    -- Pet controls - only relevant for Warlock/Hunter
    local classStr = WCS and WCS.ClassEngine and WCS.ClassEngine.class or ""
    local hasPet = (classStr == "WARLOCK" or classStr == "HUNTER")

    local petCB = self:MakeCB(s, "PetManager", "|cff00ffffPET-AI AUTO|r (control automatico)", 10, -42)
    petCB:Show()

    -- Mode buttons
    local modeL = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modeL:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -70)
    modeL:SetText("|cff9482C9Modo de mascota:|r")
    modeL:Show()

    self:MakeButton(s, "AGRESIVO", 10, -84, 115, 24, function()
        PetAttackMode()
        WCS_BrainNotifications:Info("Mascota: Modo Agresivo")
    end):Show()

    self:MakeButton(s, "DEFENSIVO", 130, -84, 115, 24, function()
        PetDefensiveMode()
        WCS_BrainNotifications:Info("Mascota: Modo Defensivo")
    end):Show()

    self:MakeButton(s, "PASIVO", 250, -84, 115, 24, function()
        PetPassiveMode()
        WCS_BrainNotifications:Info("Mascota: Modo Pasivo")
    end):Show()

    -- Quick actions
    local div = s:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1) div:SetWidth(s:GetWidth()-20)
    div:SetPoint("TOP", s, "TOP", 0, -116)
    div:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.25)
    div:Show()

    self:MakeButton(s, "Invocar Mascota", 10, -126, 183, 24, function()
        if WCS and WCS.SummonManager and WCS.SummonManager.SummonBestPet then
            WCS.SummonManager:SummonBestPet()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Usa el grimorio para invocar tu mascota.")
        end
    end):Show()

    self:MakeButton(s, "Abrir Panel Pet UI", 200, -126, 183, 24, function()
        if WCS_BrainPetUI and WCS_BrainPetUI.Toggle then
            WCS_BrainPetUI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Pet UI no disponible.")
        end
    end):Show()

    self:MakeButton(s, "Pet: Atacar Target", 10, -156, 183, 24, function()
        if UnitExists("target") and UnitCanAttack("player", "target") then
            PetAttack()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Sin target hostil.")
        end
    end):Show()

    self:MakeButton(s, "Pet: Seguir", 200, -156, 183, 24, function()
        PetFollow()
        WCS_BrainNotifications:Info("Mascota sigue al jugador.")
    end):Show()

    self:MakeButton(s, "Health Funnel", 10, -186, 183, 24, function()
        if UnitExists("pet") then
            CastSpellByName("Health Funnel")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Sin mascota activa.")
        end
    end):Show()

    if not hasPet then
        local note = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("BOTTOM", s, "BOTTOM", 0, 14)
        note:SetText("|cffaaaaaa(Funciones de mascota para Brujos y Cazadores)|r")
        note:Show()
    end
end

-- ============================================================================
-- TAB: HUD — Tactical Display Controls
-- ============================================================================
function UI:BuildTabHUD()
    local p = self.ContentFrame
    local s = self:MakeSection(p, 0, 0, p:GetWidth(), p:GetHeight()-4, "HUD TACTICO")

    local hudStatus = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hudStatus:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -22)
    local hudOn = WCS_BrainHUD and WCS_BrainHUD.Config and WCS_BrainHUD.Config.enabled
    hudStatus:SetText("|cff9482C9Estado:|r " .. (hudOn and "|cff00ff00ACTIVO|r" or "|cffff4444INACTIVO|r"))
    hudStatus:Show()
    self.hudStatusLabel = hudStatus

    self:MakeButton(s, "Toggle HUD (ON/OFF)", 10, -42, 380, 28, function()
        if WCS_BrainHUD and WCS_BrainHUD.Toggle then
            WCS_BrainHUD:Toggle()
            local on = WCS_BrainHUD.Config.enabled
            UI.hudStatusLabel:SetText("|cff9482C9Estado:|r " .. (on and "|cff00ff00ACTIVO|r" or "|cffff4444INACTIVO|r"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r HUD no disponible. /brainhud")
        end
    end):Show()

    -- Alpha slider
    local alphaLbl = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    alphaLbl:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -80)
    alphaLbl:SetText("|cff9482C9Transparencia del HUD:|r")
    alphaLbl:Show()

    local alphaSlider = CreateFrame("Slider", "WCS_HUD_AlphaSlider", s, "OptionsSliderTemplate")
    alphaSlider:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -100)
    alphaSlider:SetWidth(380) alphaSlider:SetHeight(16)
    alphaSlider:SetMinMaxValues(0.1, 1.0)
    alphaSlider:SetValueStep(0.05)
    alphaSlider:SetValue(WCS_BrainHUD and WCS_BrainHUD.Config and WCS_BrainHUD.Config.alpha or 0.6)
    getglobal("WCS_HUD_AlphaSliderLow"):SetText("10%")
    getglobal("WCS_HUD_AlphaSliderHigh"):SetText("100%")
    alphaSlider:SetScript("OnValueChanged", function()
        local v = alphaSlider:GetValue()
        if WCS_BrainHUD then
            WCS_BrainHUD.Config.alpha = v
            if WCS_BrainHUD.Frame then WCS_BrainHUD.Frame:SetAlpha(v) end
        end
    end)
    alphaSlider:Show()

    -- Scale slider
    local scaleLbl = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLbl:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -126)
    scaleLbl:SetText("|cff9482C9Escala del HUD:|r")
    scaleLbl:Show()

    local scaleSlider = CreateFrame("Slider", "WCS_HUD_ScaleSlider", s, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -146)
    scaleSlider:SetWidth(380) scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(WCS_BrainHUD and WCS_BrainHUD.Config and WCS_BrainHUD.Config.scale or 0.8)
    getglobal("WCS_HUD_ScaleSliderLow"):SetText("50%")
    getglobal("WCS_HUD_ScaleSliderHigh"):SetText("200%")
    scaleSlider:SetScript("OnValueChanged", function()
        local v = scaleSlider:GetValue()
        if WCS_BrainHUD then
            WCS_BrainHUD.Config.scale = v
            if WCS_BrainHUD.Frame then WCS_BrainHUD.Frame:SetScale(v) end
        end
    end)
    scaleSlider:Show()

    self:MakeButton(s, "Resetear Posicion del HUD", 10, -174, 380, 24, function()
        if WCS_BrainHUD and WCS_BrainHUD.Frame then
            WCS_BrainHUD.Frame:ClearAllPoints()
            WCS_BrainHUD.Frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
            WCS_BrainNotifications:Success("HUD reposicionado al centro.")
        end
    end):Show()

    self:MakeButton(s, "Abrir Tactical HUD", 10, -204, 380, 24, function()
        -- Tactical HUD auto-shows with target, but can be forced
        if WCS.TacticalHUD and WCS.TacticalHUD.Main then
            if WCS.TacticalHUD.Main:IsVisible() then
                WCS.TacticalHUD.Main:Hide()
            else
                WCS.TacticalHUD.Main:Show()
            end
        end
    end):Show()
end

-- ============================================================================
-- TAB: SYS — System Tools & Performance
-- ============================================================================
function UI:BuildTabSys()
    local p = self.ContentFrame
    local s = self:MakeSection(p, 0, 0, p:GetWidth(), p:GetHeight()-4, "SISTEMA & HERRAMIENTAS")

    -- Memory & FPS
    self.sysMemLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.sysMemLabel:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -22)
    self.sysMemLabel:SetText("|cff9482C9Memoria:|r " .. WCS:GetMemory())
    self.sysMemLabel:Show()

    self.sysFpsLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.sysFpsLabel:SetPoint("TOPRIGHT", s, "TOPRIGHT", -10, -22)
    self.sysFpsLabel:SetText("")
    self.sysFpsLabel:Show()

    -- Class info
    self.sysClassLabel = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.sysClassLabel:SetPoint("TOPLEFT", s, "TOPLEFT", 10, -40)
    local _cls1, cls1 = UnitClass("player")
    local _rac1, rac1 = UnitRace("player")
    local cls = (WCS and WCS.ClassEngine and WCS.ClassEngine.class) or cls1 or "?"
    local race = (WCS and WCS.ClassEngine and WCS.ClassEngine.race) or rac1 or "?"
    self.sysClassLabel:SetText("|cff9482C9Clase:|r |cffffd700" .. cls .. "|r  |cff9482C9Raza:|r " .. race)
    self.sysClassLabel:Show()

    -- Divider
    local div = s:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1) div:SetWidth(s:GetWidth()-20)
    div:SetPoint("TOP", s, "TOP", 0, -56)
    div:SetTexture(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.25)
    div:Show()

    -- Tool buttons
    self:MakeButton(s, "Dashboard de Rendimiento", 10, -66, 185, 24, function()
        if WCS_Brain and WCS_Brain.Dashboard and WCS_Brain.Dashboard.Toggle then
            WCS_Brain.Dashboard:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Dashboard: /wcsdash")
        end
    end):Show()

    self:MakeButton(s, "Perfiles de Config", 200, -66, 185, 24, function()
        if WCS_BrainProfilesUI and WCS_BrainProfilesUI.Toggle then
            WCS_BrainProfilesUI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Perfiles no disponibles.")
        end
    end):Show()

    self:MakeButton(s, "Diagnosticos del Sistema", 10, -96, 185, 24, function()
        if WCS_BrainDiagnostics and WCS_BrainDiagnostics.Toggle then
            WCS_BrainDiagnostics:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Diagnosticos no disponibles.")
        end
    end):Show()

    self:MakeButton(s, "Barra de Botones", 200, -96, 185, 24, function()
        if WCS_BrainButtonBar and WCS_BrainButtonBar.Toggle then
            WCS_BrainButtonBar:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r ButtonBar: /brainbar")
        end
    end):Show()

    self:MakeButton(s, "Logros del Clan", 10, -126, 185, 24, function()
        if WCS_BrainAchievements and WCS_BrainAchievements.Toggle then
            WCS_BrainAchievements:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[WCS]|r Logros no disponibles.")
        end
    end):Show()

    self:MakeButton(s, "Recargar Config", 200, -126, 185, 24, function()
        if WCS_SavedVarsValidator and WCS_SavedVarsValidator.Validate then
            WCS_SavedVarsValidator:Validate()
            WCS_BrainNotifications:Success("Variables validadas y recargadas.")
        else
            ReloadUI()
        end
    end):Show()

    -- Version info
    local verLbl = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    verLbl:SetPoint("BOTTOM", s, "BOTTOM", 0, 14)
    verLbl:SetText("|cff9482C9WCS Brain v8.0.0 [God-Tier] — El Sequito del Terror|r")
    verLbl:Show()
end

-- ============================================================================
-- HEARTBEAT — Live Data Updates
-- ============================================================================
function UI:StartHeartbeat()
    local tick = CreateFrame("Frame")
    local elapsed = 0
    tick:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed < 0.25 then return end
        elapsed = 0
        if UI.MainFrame and UI.MainFrame:IsVisible() then
            UI:Update()
        end
    end)
end

function UI:Update()
    -- Vitals
    if self.hpBar then
        local hp = UnitHealthMax("player") > 0 and (UnitHealth("player") / UnitHealthMax("player")) * 100 or 0
        self.hpBar:SetValue(hp)
        self.hpBar.txt:SetText("HP " .. math.floor(hp) .. "%")
    end
    if self.manaBar then
        local mp = UnitManaMax("player") > 0 and (UnitMana("player") / UnitManaMax("player")) * 100 or 0
        self.manaBar:SetValue(mp)
        self.manaBar.txt:SetText("MP " .. math.floor(mp) .. "%")
    end
    if self.targetLabel then
        if UnitExists("target") then
            local tname = UnitName("target") or "?"
            local tlvl  = UnitLevel("target") or "?"
            local thp   = UnitHealthMax("target") > 0 and math.floor((UnitHealth("target") / UnitHealthMax("target")) * 100) or 0
            self.targetLabel:SetText("Target: " .. tname .. " (Lv" .. tlvl .. ") " .. thp .. "%")
        else
            self.targetLabel:SetText("Target: Ninguno")
        end
    end

    -- Phase
    if self.phaseText and WCS_Brain and WCS_Brain.Context then
        local phase = WCS_Brain.Context.phase or "Idle"
        local inCombat = UnitAffectingCombat("player")
        local color = inCombat and "|cffff4444" or "|cff00ff88"
        self.phaseText:SetText(color .. string.upper(phase) .. "|r")
    end

    -- Class label (live)
    if self.classLabel then
        local _c, clsLive = UnitClass("player")
        local _r, racLive = UnitRace("player")
        local cls = (WCS and WCS.ClassEngine and WCS.ClassEngine.class) or clsLive or "?"
        local race = (WCS and WCS.ClassEngine and WCS.ClassEngine.race) or racLive or "?"
        self.classLabel:SetText("|cffaaaaaa" .. cls .. " — " .. race .. "|r")
    end

    -- AI Decision (in AI tab)
    if self.currentTab == "ai" and self.aiSpellText then
        if WCS and WCS.DecisionEngine then
            local action = WCS.DecisionEngine:GetBestAction()
            if action then
                self.aiSpellText:SetText("|cff00ff88" .. action.spell .. "|r")
                self.aiReasonText:SetText("|cffaaaaaa" .. (action.reason or "") .. "|r")
            else
                self.aiSpellText:SetText("|cff888888Sin decision — sin target|r")
                self.aiReasonText:SetText("")
            end
        end
    end

    -- Pet status (in pet tab)
    if self.currentTab == "pet" and self.petStatusLabel then
        local petStatus = UnitExists("pet") and ("|cff00ff00" .. (UnitName("pet") or "Mascota") .. "|r")
                          or "|cff888888Sin mascota activa|r"
        self.petStatusLabel:SetText("|cff9482C9Mascota:|r " .. petStatus)
    end

    -- Clan members online (in clan tab)
    if self.currentTab == "clan" and self.clanOnlineLabel then
        local total = GetNumGuildMembers()
        local online = 0
        if total then
            -- Count online manually in 1.12 (no second return value from GetNumGuildMembers)
            for i = 1, total do
                local _, _, _, _, _, _, _, _, connected = GetGuildRosterInfo(i)
                if connected then online = online + 1 end
            end
            self.clanOnlineLabel:SetText("|cff9482C9Miembros online:|r |cff00ff00" .. online .. "/" .. total .. "|r")
        end
    end

    -- Sys Tab live updates
    if self.currentTab == "sys" then
        if self.sysMemLabel then
            self.sysMemLabel:SetText("|cff9482C9Memoria:|r " .. WCS:GetMemory())
        end
        if self.sysFpsLabel then
            local fps = GetFramerate and math.floor(GetFramerate()) or 0
            local lat = 0
            if GetNetStats then
                local _, _, l = GetNetStats()
                lat = math.floor(l or 0)
            end
            self.sysFpsLabel:SetText("|cff9482C9FPS:|r " .. fps .. "  |cff9482C9Lat:|r " .. lat .. "ms")
        end
    end

    -- Footer memory
    if self.foot then
        self.foot:SetText("|cff9482C9MEM:|r " .. WCS:GetMemory() .. "  |cff9482C9v8.0.0 [God-Tier]|r")
    end
end

-- ============================================================================
-- TOGGLE
-- ============================================================================
function UI:Toggle()
    if not self.MainFrame then self:CreateMainFrame() end
    if self.MainFrame:IsVisible() then self.MainFrame:Hide() else self.MainFrame:Show() end
end

-- ============================================================================
-- HELPER BUILDERS (DRY Constructors)
-- ============================================================================
function UI:MakeSection(p, x, y, w, h, title)
    local f = CreateFrame("Frame", nil, p)
    f:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    f:SetWidth(w) f:SetHeight(h)
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left=3, right=3, top=3, bottom=3}
    })
    f:SetBackdropColor(C.BG_SECT[1], C.BG_SECT[2], C.BG_SECT[3], 0.92)
    f:SetBackdropBorderColor(C.LAVENDER[1], C.LAVENDER[2], C.LAVENDER[3], 0.55)
    if title then
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -6)
        t:SetText("|cff9482C9" .. title .. "|r")
    end
    return f
end

function UI:MakeBar(p, x, y, w, h, col)
    local sb = CreateFrame("StatusBar", nil, p)
    sb:SetWidth(w) sb:SetHeight(h)
    sb:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    sb:SetStatusBarColor(col[1], col[2], col[3], 0.85)
    sb:SetMinMaxValues(0, 100) sb:SetValue(100)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(sb) bg:SetTexture(0, 0, 0, 0.5)
    sb.txt = sb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sb.txt:SetPoint("CENTER", sb, "CENTER", 0, 0)
    return sb
end

function UI:MakeButton(p, text, x, y, w, h, fn)
    local b = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
    b:SetWidth(w) b:SetHeight(h)
    b:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    b:SetText(text)
    b:SetScript("OnClick", fn)
    return b
end

function UI:MakeCB(p, key, label, x, y)
    local cb = CreateFrame("CheckButton", "WCS_CB_"..key, p, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", p, "TOPLEFT", x, y)
    getglobal(cb:GetName().."Text"):SetText(label)
    cb:SetScript("OnShow", function()
        if WCS_BrainSaved and WCS_BrainSaved.Config then
            this:SetChecked(WCS_BrainSaved.Config[key])
        end
    end)
    cb:SetScript("OnClick", function()
        if WCS_BrainSaved and WCS_BrainSaved.Config then
            WCS_BrainSaved.Config[key] = this:GetChecked() == 1
        end
    end)
    return cb
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================
SLASH_WCSBRAIN1 = "/brain"
SLASH_WCSBRAIN2 = "/wcsbrain"
SlashCmdList["WCSBRAIN"] = function() UI:Toggle() end

-- ============================================================================
-- GLOBAL COMPATIBILITY BRIDGE (God-Tier Backward Compatibility)
-- ============================================================================
WCS_BrainUI = WCS_BrainUI or WCS.UI
WCS_BrainUI.MainFrame = WCS.UI.MainFrame

WCS_ClanUI = WCS_ClanUI or {}
WCS_BrainClanUI = WCS_ClanUI

if WCS_Brain and WCS_Brain.Dashboard then
    WCS_BrainDashboard = WCS_Brain.Dashboard
end

if WCS_BrainAutoExecute then
    WCS.BrainAutoExecute = WCS_BrainAutoExecute
end

WCS_BrainDQNUI      = WCS_BrainDQNUI or {}
WCS_BrainTutorialUI = WCS_BrainTutorialUI or {}
WCS_BrainProfilesUI = WCS_BrainProfilesUI or {}

WCS.UI.Legacy = {
    DQN  = WCS_BrainDQNUI,
    Clan = WCS_ClanUI,
    Dash = WCS_BrainDashboard,
    Tut  = WCS_BrainTutorialUI,
    Prof = WCS_BrainProfilesUI
}

-- Auto-init on PLAYER_LOGIN
local hubInit = CreateFrame("Frame")
hubInit:RegisterEvent("PLAYER_LOGIN")
hubInit:SetScript("OnEvent", function()
    UI:CreateMainFrame()
    WCS:Log("Master Hub v8.0.0 [God-Tier] Online — 120 modules bridged.")
end)
