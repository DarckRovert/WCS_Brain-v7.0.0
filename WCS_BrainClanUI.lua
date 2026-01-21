--[[
    WCS_BrainClanUI.lua
    UI Completa para "El Séquito del Terror"
    
    Creado por: Elnazzareno (DarckRovert)
    Guild Master de El Séquito del Terror
    
    Versión: 1.0.0
    Fecha: Enero 2, 2026
    
    Temática: Brujo/Warlock - Oscura y Demoníaca
    
    Descripción:
    Sistema completo de UI para el clan con temática de grimorio oscuro,
    incluyendo gestión de miembros, recursos de brujo, raids, estadísticas,
    y mucho más.
]]--

-- Namespace global
WCS_ClanUI = WCS_ClanUI or {}
WCS_ClanUI.Version = "1.0.0"
WCS_ClanUI.GuildName = "El Séquito del Terror"
WCS_ClanUI.GuildMaster = "Elnazzareno"
WCS_ClanUI.Creator = "DarckRovert"

-- Colores temáticos del clan
WCS_ClanUI.Colors = {
    FelGreen = {r = 0.2, g = 1.0, b = 0.2},      -- Verde Fel
    DarkPurple = {r = 0.5, g = 0.0, b = 0.5},    -- Púrpura Oscuro
    BloodRed = {r = 0.8, g = 0.0, b = 0.0},      -- Rojo Sangre
    ShadowBlack = {r = 0.1, g = 0.1, b = 0.1},   -- Negro Sombra
    GoldText = {r = 1.0, g = 0.8, b = 0.0},      -- Dorado para texto
    SoulBlue = {r = 0.3, g = 0.3, b = 0.8},      -- Azul Alma
}

-- Variables guardadas
WCS_ClanUI_SavedVars = WCS_ClanUI_SavedVars or {
    version = "1.0.0",
    firstRun = true,
    mainFrame = {
        point = "CENTER",
        x = 0,
        y = 0,
        width = 800,
        height = 600,
        shown = false,
    },
    panels = {
        clanPanel = true,
        warlockResources = true,
        raidManager = true,
        statistics = true,
        grimoire = true,
        summonPanel = true,
        clanBank = true,
        pvpTracker = true,
    },
    settings = {
        autoAcceptSummons = true,
        autoShareQuests = true,
        soundEnabled = true,
        animationsEnabled = true,
        showMinimapButton = true,
        debugMode = false,  -- Mensajes de debug desactivados por defecto
    },
    members = {},
    events = {},
    achievements = {},
    statistics = {},
}

-- Frame principal
local MainFrame = nil

-- Inicialización
function WCS_ClanUI:Initialize()
    if self.Initialized then return end
    
    self:Print("Inicializando UI de " .. self.GuildName .. "...")
    
    -- Crear frame principal
    self:CreateMainFrame()
    
    -- Registrar eventos
    self:RegisterEvents()
    
    -- Registrar comandos slash
    self:RegisterSlashCommands()
    
    -- Cargar módulos
    self:LoadModules()
    
    -- Mensaje de bienvenida
    if WCS_ClanUI_SavedVars.firstRun then
        self:ShowWelcomeMessage()
        WCS_ClanUI_SavedVars.firstRun = false
    end
    
    self.Initialized = true
    self:Print("UI inicializada correctamente. Usa /sequito o /clan para abrir el panel.")
end

-- Crear frame principal
function WCS_ClanUI:CreateMainFrame()
    if MainFrame then return end
    
    -- Frame principal
    MainFrame = CreateFrame("Frame", "WCS_ClanUI_MainFrame", UIParent)
    MainFrame:SetWidth(WCS_ClanUI_SavedVars.mainFrame.width)
    MainFrame:SetHeight(WCS_ClanUI_SavedVars.mainFrame.height)
    MainFrame:SetPoint(
        WCS_ClanUI_SavedVars.mainFrame.point,
        WCS_ClanUI_SavedVars.mainFrame.x,
        WCS_ClanUI_SavedVars.mainFrame.y
    )
    MainFrame:SetFrameStrata("HIGH")
    MainFrame:SetMovable(true)
    MainFrame:EnableMouse(true)
    MainFrame:SetClampedToScreen(true)
    MainFrame:Hide()
    
    -- Fondo oscuro con tema de grimorio
    MainFrame.bg = MainFrame:CreateTexture(nil, "BACKGROUND")
    MainFrame.bg:SetAllPoints(MainFrame)
    MainFrame.bg:SetTexture(0, 0, 0, 0.95)
    
    -- Borde con tema demoníaco
    MainFrame.border = CreateFrame("Frame", nil, MainFrame)
    MainFrame.border:SetAllPoints(MainFrame)
    MainFrame.border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    MainFrame.border:SetBackdropBorderColor(
        self.Colors.FelGreen.r,
        self.Colors.FelGreen.g,
        self.Colors.FelGreen.b,
        1
    )
    
    -- Título del grimorio
    MainFrame.title = MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainFrame.title:SetPoint("TOP", 0, -10)
    MainFrame.title:SetText("|cff00ff00El Séquito del Terror|r")
    MainFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    MainFrame.title:SetTextColor(
        self.Colors.FelGreen.r,
        self.Colors.FelGreen.g,
        self.Colors.FelGreen.b
    )
    
    -- Subtítulo eliminado
    
    -- Botón de cerrar
    MainFrame.closeButton = CreateFrame("Button", nil, MainFrame, "UIPanelCloseButton")
    MainFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
    MainFrame.closeButton:SetScript("OnClick", function()
        WCS_ClanUI:ToggleMainFrame()
    end)
    
    -- Hacer el frame movible
    MainFrame:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            MainFrame:StartMoving()
        end
    end)
    
    MainFrame:SetScript("OnMouseUp", function()
        MainFrame:StopMovingOrSizing()
        -- Guardar posición
        local point, _, _, x, y = MainFrame:GetPoint()
        WCS_ClanUI_SavedVars.mainFrame.point = point
        WCS_ClanUI_SavedVars.mainFrame.x = x
        WCS_ClanUI_SavedVars.mainFrame.y = y
    end)
    
    -- Crear pestañas para diferentes paneles
    self:CreateTabs()
    
    -- Crear área de contenido
    MainFrame.content = CreateFrame("Frame", nil, MainFrame)
    MainFrame.content:SetPoint("TOPLEFT", 10, -80)
    MainFrame.content:SetPoint("BOTTOMRIGHT", -10, 10)
    
    self.MainFrame = MainFrame
end

-- Crear pestañas
function WCS_ClanUI:CreateTabs()
    local tabs = {
        {name = "Clan", icon = "Interface\\Icons\\INV_Misc_Book_11"},
        {name = "Recursos", icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02"},
        {name = "Raid", icon = "Interface\\Icons\\Ability_Warlock_DemonicEmpowerment"},
        {name = "Stats", icon = "Interface\\Icons\\INV_Misc_Note_01"},
        {name = "Grimorio", icon = "Interface\\Icons\\INV_Misc_Book_09"},
        {name = "Summons", icon = "Interface\\Icons\\Spell_Shadow_Twilight"},
        {name = "Bank", icon = "Interface\\Icons\\INV_Misc_Bag_10"},
        {name = "PvP", icon = "Interface\\Icons\\Ability_DualWield"},
    }
    
    MainFrame.tabs = {}
    local tabWidth = 90
    local tabHeight = 30
    local startX = 10
    
    for i = 1, table.getn(tabs) do
        local tabData = tabs[i]
        local tab = CreateFrame("Button", "WCS_ClanUI_Tab" .. i, MainFrame)
        tab:SetWidth(tabWidth)
        tab:SetHeight(tabHeight)
        tab:SetPoint("TOPLEFT", startX + (i-1) * (tabWidth + 5), -40)
        
        -- Fondo de la pestaña
        tab.bg = tab:CreateTexture(nil, "BACKGROUND")
        tab.bg:SetAllPoints(tab)
        tab.bg:SetTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Icono
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetWidth(20)
        tab.icon:SetHeight(20)
        tab.icon:SetPoint("LEFT", 5, 0)
        tab.icon:SetTexture(tabData.icon)
        
        -- Texto
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 5, 0)
        tab.text:SetText(tabData.name)
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        
        -- Highlight
        tab:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
        
        -- Guardar índice en el tab
        tab.index = i
        
        -- Click handler (usar this.index en lugar de i para evitar problemas de closure en Lua 5.0)
        tab:SetScript("OnClick", function()
            WCS_ClanUI:SelectTab(this.index)
        end)
        
        MainFrame.tabs[i] = tab
    end
    
    -- NO seleccionar pestaña aquí, se hará en ToggleMainFrame después de crear el área de contenido
end

-- Seleccionar pestaña
function WCS_ClanUI:SelectTab(index)
    -- self:Print("SelectTab llamado con index: " .. index)
    
    if not MainFrame then
        self:Print("ERROR: MainFrame no existe")
        return
    end
    
    if not MainFrame.content then
        self:Print("ERROR: MainFrame.content no existe")
        return
    end
    
    self:Print("MainFrame y content existen, continuando...")
    
    -- Actualizar apariencia de pestañas
    for i = 1, table.getn(MainFrame.tabs) do
        local tab = MainFrame.tabs[i]
        if i == index then
            tab.bg:SetTexture(
                self.Colors.FelGreen.r,
                self.Colors.FelGreen.g,
                self.Colors.FelGreen.b,
                0.5
            )
            tab.text:SetTextColor(1, 1, 1)
        else
            tab.bg:SetTexture(0.2, 0.2, 0.2, 0.8)
            tab.text:SetTextColor(0.7, 0.7, 0.7)
        end
    end
    
    -- Ocultar todos los paneles primero
    self:Print("Ocultando todos los paneles...")
    self:HideAllPanels()
    
    -- Mostrar panel seleccionado
    self:Print("Mostrando panel " .. index)
    self:ShowPanel(index)
    
    -- Guardar pestaña actual
    MainFrame.currentTab = index
    -- self:Print("SelectTab completado")
end

-- Ocultar todos los paneles
function WCS_ClanUI:HideAllPanels()
    if WCS_ClanPanel then WCS_ClanPanel:Hide() end
    if WCS_WarlockResources then WCS_WarlockResources:Hide() end
    if WCS_RaidManager then WCS_RaidManager:Hide() end
    if WCS_Statistics then WCS_Statistics:Hide() end
    if WCS_Grimoire then WCS_Grimoire:Hide() end
    if WCS_SummonPanel then WCS_SummonPanel:Hide() end
    if WCS_ClanBank then WCS_ClanBank:Hide() end
    if WCS_PvPTracker then WCS_PvPTracker:Hide() end
end

-- Mostrar panel específico
function WCS_ClanUI:ShowPanel(index)
    -- self:Print("ShowPanel llamado con index: " .. index)
    
    -- Asegurarse de que el frame principal y el área de contenido existen
    if not self.MainFrame then
        self:Print("Error: MainFrame no existe")
        return
    end
    
    if not self.MainFrame.content then
        self:Print("Error: MainFrame.content no existe")
        return
    end
    
    self:Print("Intentando mostrar panel " .. index)
    
    local panels = {
        function() 
            if WCS_ClanPanel then 
                WCS_ClanPanel:Show() 
            else
                self:Print("Error: WCS_ClanPanel no existe")
            end
        end,
        function() 
            if WCS_WarlockResources then 
                WCS_WarlockResources:Show() 
            else
                self:Print("Error: WCS_WarlockResources no existe")
            end
        end,
        function() 
            if WCS_RaidManager then 
                WCS_RaidManager:Show() 
            else
                self:Print("Error: WCS_RaidManager no existe")
            end
        end,
        function() 
            if WCS_Statistics then 
                WCS_Statistics:Show() 
            else
                self:Print("Error: WCS_Statistics no existe")
            end
        end,
        function() 
            if WCS_Grimoire then 
                WCS_Grimoire:Show() 
            else
                self:Print("Error: WCS_Grimoire no existe")
            end
        end,
        function() 
            if WCS_SummonPanel then 
                WCS_SummonPanel:Show() 
            else
                self:Print("Error: WCS_SummonPanel no existe")
            end
        end,
        function() 
            if WCS_ClanBank then 
                WCS_ClanBank:Show() 
            else
                self:Print("Error: WCS_ClanBank no existe")
            end
        end,
        function() 
            if WCS_PvPTracker then 
                WCS_PvPTracker:Show() 
            else
                self:Print("Error: WCS_PvPTracker no existe")
            end
        end,
    }
    
    if panels[index] then
        panels[index]()
    end
end

-- Registrar eventos
function WCS_ClanUI:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    frame:RegisterEvent("CHAT_MSG_GUILD")
    frame:RegisterEvent("PLAYER_LOGOUT")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_ENTERING_WORLD" then
            WCS_ClanUI:OnPlayerEnteringWorld()
        elseif event == "GUILD_ROSTER_UPDATE" then
            WCS_ClanUI:OnGuildRosterUpdate()
        elseif event == "CHAT_MSG_GUILD" then
            WCS_ClanUI:OnGuildChat(arg1, arg2)
        elseif event == "PLAYER_LOGOUT" then
            WCS_ClanUI:OnPlayerLogout()
        end
    end)
    
    self.EventFrame = frame
end

-- Eventos
function WCS_ClanUI:OnPlayerEnteringWorld()
    -- Verificar si el jugador está en el clan
    if GetGuildInfo("player") == self.GuildName then
        self:Print("¡Bienvenido al " .. self.GuildName .. "!")
    end
end

function WCS_ClanUI:OnGuildRosterUpdate()
    -- Actualizar lista de miembros
    if WCS_ClanPanel then
        WCS_ClanPanel:UpdateMemberList()
    end
end

function WCS_ClanUI:OnGuildChat(message, sender)
    -- Procesar mensajes del chat del clan
    -- Aquí se pueden agregar comandos especiales, etc.
end

function WCS_ClanUI:OnPlayerLogout()
    -- Guardar datos antes de salir
    self:SaveData()
end

-- Registrar comandos slash
function WCS_ClanUI:RegisterSlashCommands()
    -- Comando principal
    SLASH_WCSCLANUI1 = "/sequito"
    SLASH_WCSCLANUI2 = "/wcsui"
    SLASH_WCSCLANUI3 = "/terror"
    SLASH_WCSCLANUI4 = "/clan"
    
    SlashCmdList["WCSCLANUI"] = function(msg)
        WCS_ClanUI:HandleSlashCommand(msg)
    end
    
    -- Comando para abrir directamente el banco
    SLASH_WCSCLANBANK1 = "/clanbank"
    SLASH_WCSCLANBANK2 = "/bank"
    
    SlashCmdList["WCSCLANBANK"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(7) -- Tab del banco
    end
    
    -- Comando para abrir directamente raid manager
    SLASH_WCSRAIDMGR1 = "/raidmanager"
    SLASH_WCSRAIDMGR2 = "/raidmgr"
    SLASH_WCSRAIDMGR3 = "/rm"
    
    SlashCmdList["WCSRAIDMGR"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(3) -- Tab de raid manager
    end
    
    -- Comando para abrir directamente summon panel
    SLASH_WCSSUMMON1 = "/summonpanel"
    SLASH_WCSSUMMON2 = "/summon"
    SLASH_WCSSUMMON3 = "/sp"
    
    SlashCmdList["WCSSUMMON"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(6) -- Tab de summon panel
    end
    
    -- Comando para abrir directamente statistics
    SLASH_WCSSTATS1 = "/warlockstats"
    SLASH_WCSSTATS2 = "/wstats"
    
    SlashCmdList["WCSSTATS"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(4) -- Tab de statistics
    end
    
    -- Comando para abrir directamente grimoire
    SLASH_WCSGRIMOIRE1 = "/grimoire"
    SLASH_WCSGRIMOIRE2 = "/grim"
    
    SlashCmdList["WCSGRIMOIRE"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(5) -- Tab de grimoire
    end
    
    -- Comando para abrir directamente PvP tracker
    SLASH_WCSPVP1 = "/pvptracker"
    SLASH_WCSPVP2 = "/pvpt"
    
    SlashCmdList["WCSPVP"] = function(msg)
        WCS_ClanUI:ToggleMainFrame()
        WCS_ClanUI:SelectTab(8) -- Tab de PvP tracker
    end
end

-- Manejar comandos slash
function WCS_ClanUI:HandleSlashCommand(msg)
    msg = string.lower(msg or "")
    
    if msg == "" or msg == "show" then
        self:ToggleMainFrame()
    elseif msg == "hide" then
        if MainFrame then MainFrame:Hide() end
    elseif msg == "reset" then
        self:ResetPosition()
    elseif msg == "help" then
        self:ShowHelp()
    elseif msg == "version" then
        self:Print("Versión: " .. self.Version)
    else
        self:Print("Comando desconocido. Usa /sequito help para ver los comandos disponibles.")
    end
end

-- Toggle frame principal
function WCS_ClanUI:ToggleMainFrame()
    if not MainFrame then
        self:CreateMainFrame()
    end
    
    if MainFrame:IsShown() then
        MainFrame:Hide()
        WCS_ClanUI_SavedVars.mainFrame.shown = false
    else
        MainFrame:Show()
        WCS_ClanUI_SavedVars.mainFrame.shown = true
        -- Refrescar el panel actual cuando se muestra
        self:SelectTab(1)
    end
end

-- Resetear posición
function WCS_ClanUI:ResetPosition()
    if MainFrame then
        MainFrame:ClearAllPoints()
        MainFrame:SetPoint("CENTER", 0, 0)
        WCS_ClanUI_SavedVars.mainFrame.point = "CENTER"
        WCS_ClanUI_SavedVars.mainFrame.x = 0
        WCS_ClanUI_SavedVars.mainFrame.y = 0
        self:Print("Posición reseteada al centro de la pantalla.")
    end
end

-- Mostrar ayuda
function WCS_ClanUI:ShowHelp()
    self:Print("=== Comandos de El Séquito del Terror ===")
    self:Print("|cffffaa00Comandos principales:|r")
    self:Print("/sequito, /clan, /terror - Abrir/cerrar el panel principal")
    self:Print("/sequito show - Mostrar el panel")
    self:Print("/sequito hide - Ocultar el panel")
    self:Print("/sequito reset - Resetear posición del panel")
    self:Print("/sequito version - Mostrar versión")
    self:Print("/sequito help - Mostrar esta ayuda")
    self:Print(" ")
    self:Print("|cffffaa00Accesos directos a módulos:|r")
    self:Print("/clanbank, /bank - Abrir banco del clan")
    self:Print("/raidmanager, /raidmgr, /rm - Abrir gestión de raid")
    self:Print("/summonpanel, /summon, /sp - Abrir panel de summon")
    self:Print("/warlockstats, /wstats - Abrir estadísticas")
    self:Print("/grimoire, /grim - Abrir grimorio")
    self:Print("/pvptracker, /pvpt - Abrir tracker de PvP")
end

-- Cargar módulos
function WCS_ClanUI:LoadModules()
    -- Los módulos se cargarán desde archivos separados
    self:Print("Cargando módulos...")
    
    -- Verificar que los módulos existan
    if WCS_ClanPanel then
        WCS_ClanPanel:Initialize()
    end
    
    if WCS_WarlockResources then
        WCS_WarlockResources:Initialize()
    end
    
    if WCS_RaidManager then
        WCS_RaidManager:Initialize()
    end
    
    if WCS_Statistics then
        WCS_Statistics:Initialize()
    end
    
    if WCS_Grimoire then
        WCS_Grimoire:Initialize()
    end
    
    if WCS_SummonPanel then
        WCS_SummonPanel:Initialize()
    end
    
    if WCS_ClanBank then
        WCS_ClanBank:Initialize()
    end
    
    if WCS_PvPTracker then
        WCS_PvPTracker:Initialize()
    end
end

-- Mensaje de bienvenida
function WCS_ClanUI:ShowWelcomeMessage()
    self:Print("==============================================")
    self:Print("|cff00ff00El Séquito del Terror - UI v" .. self.Version .. "|r")
    self:Print("Creado por: |cffffaa00" .. self.GuildMaster .. "|r (" .. self.Creator .. ")")
    self:Print("¡Bienvenido al grimorio del clan!")
    self:Print("Usa |cff00ff00/sequito|r para abrir el panel principal")
    self:Print("==============================================")
end

-- Guardar datos
function WCS_ClanUI:SaveData()
    -- Los datos se guardan automáticamente en WCS_ClanUI_SavedVars
    self:Print("Datos guardados correctamente.")
end

-- Función de print personalizada
function WCS_ClanUI:Print(msg)
    -- Siempre mostrar mensajes importantes
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Séquito del Terror]|r " .. msg)
end

-- Inicializar cuando el addon se carga
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_ClanUI:Initialize()
    elseif event == "PLAYER_LOGIN" then
        -- Fallback: inicializar en login si no se inicializó antes
        if not WCS_ClanUI.Initialized then
            WCS_ClanUI:Initialize()
        end
    end
end)

