-- WCS_BrainButtonBar.lua
-- Barra horizontal para organizar todos los botones del addon
-- Compatible con Lua 5.0 (WoW 1.12) - SOLO ASCII

WCS_BrainButtonBar = {}

-- Variables locales
local bar = nil
local buttons = {}
local BUTTON_SIZE = 48
local BUTTON_SPACING = 4
local BAR_PADDING = 8

-- Colores
local COLOR_BRAIN = {r=0.58, g=0.51, b=0.79}
local COLOR_HIGHLIGHT = {r=1, g=0.84, b=0}

-- Configuracion por defecto
local defaultConfig = {
    point = "TOP",
    relativeTo = "UIParent",
    relativePoint = "TOP",
    xOffset = 0,
    yOffset = -10,
    visible = true,
    locked = false,
    buttonSize = 48,
    spacing = 4,
    showLabels = true,
    orientation = "HORIZONTAL", -- HORIZONTAL o VERTICAL
    buttons = {
        brain = {enabled = true, order = 1},
        dqn = {enabled = true, order = 2},
        profiles = {enabled = true, order = 3},
        thinking = {enabled = true, order = 4},
        tutorial = {enabled = true, order = 5},
        diagnostics = {enabled = true, order = 6},
        sequito = {enabled = true, order = 7},
        dashboard = {enabled = true, order = 8},
        toggleAllButtons = {enabled = true, order = 9}
    }
}

-- Funcion para obtener configuracion
local function GetConfig()
    if not WCS_BrainButtonBarConfig then
        WCS_BrainButtonBarConfig = {}
        for k, v in pairs(defaultConfig) do
            if type(v) == "table" then
                WCS_BrainButtonBarConfig[k] = {}
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" then
                        WCS_BrainButtonBarConfig[k][k2] = {}
                        for k3, v3 in pairs(v2) do
                            WCS_BrainButtonBarConfig[k][k2][k3] = v3
                        end
                    else
                        WCS_BrainButtonBarConfig[k][k2] = v2
                    end
                end
            else
                WCS_BrainButtonBarConfig[k] = v
            end
        end
    end
    
    -- Asegurar que todos los botones de defaultConfig esten en la configuracion
    if not WCS_BrainButtonBarConfig.buttons then
        WCS_BrainButtonBarConfig.buttons = {}
    end
    for id, btnConfig in pairs(defaultConfig.buttons) do
        if not WCS_BrainButtonBarConfig.buttons[id] then
            WCS_BrainButtonBarConfig.buttons[id] = {}
            for k, v in pairs(btnConfig) do
                WCS_BrainButtonBarConfig.buttons[id][k] = v
            end
        end
    end
    
    return WCS_BrainButtonBarConfig
end

-- Definicion de botones disponibles
local buttonDefinitions = {
    brain = {
        name = "Brain",
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
        tooltip = "WCS Brain - Control Principal",
        onClick = function()
            if WCS_BrainUI then
                WCS_BrainUI:Toggle()
            end
        end,
        module = "WCS_BrainButton"
    },
    dqn = {
        name = "DQN",
        icon = "Interface\\Icons\\Spell_Nature_Lightning",
        tooltip = "Sistema DQN - Aprendizaje Profundo",
        onClick = function()
            if WCS_BrainDQNUI then
                WCS_BrainDQNUI:Toggle()
            end
        end,
        module = "WCS_BrainDQNButton"
    },
    profiles = {
        name = "Profiles",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        tooltip = "Perfiles de Configuracion",
        onClick = function()
            if WCS_BrainProfilesUI then
                WCS_BrainProfilesUI:Toggle()
            end
        end,
        module = "WCS_BrainProfilesButton"
    },
    thinking = {
        name = "Think",
        icon = "Interface\\Icons\\Spell_Shadow_Charm",
        tooltip = "Thinking UI - Pensamiento en Tiempo Real",
        onClick = function()
            if WCS_BrainThinkingUI then
                WCS_BrainThinkingUI:Toggle()
            end
        end,
        module = "WCS_BrainThinkingButton"
    },
    tutorial = {
        name = "Tutorial",
        icon = "Interface\\Icons\\INV_Misc_Book_11",
        tooltip = "Tutorial Interactivo",
        onClick = function()
            if WCS_BrainTutorialUI then
                WCS_BrainTutorialUI:Toggle()
            elseif WCS_BrainTutorialButton then
                WCS_BrainTutorialButton:Toggle()
            end
        end,
        onRightClick = function()
            if WCS_BrainTutorialButton and WCS_BrainTutorialButton.Toggle then
                WCS_BrainTutorialButton:Toggle()
                DEFAULT_CHAT_FRAME:AddMessage("Boton flotante de Tutorial alternado", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            end
        end,
        module = "WCS_BrainTutorialButton"
    },
    diagnostics = {
        name = "Diag",
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        tooltip = "Diagnosticos del Sistema",
        onClick = function()
            if WCS_BrainDiagnostics then
                WCS_BrainDiagnostics:Toggle()
            end
        end,
        onRightClick = function()
            if WCS_BrainDiagnostics and WCS_BrainDiagnostics.ToggleButton then
                WCS_BrainDiagnostics:ToggleButton()
                DEFAULT_CHAT_FRAME:AddMessage("Boton flotante de Diagnosticos alternado", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            end
        end,
        module = "WCS_BrainDiagnostics"
    },
    sequito = {
        name = "Sequito",
        icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
        tooltip = "El Sequito del Terror - Panel del Clan",
        onClick = function()
            if WCS_ClanUI and WCS_ClanUI.ToggleMainFrame then
                WCS_ClanUI:ToggleMainFrame()
            else
                DEFAULT_CHAT_FRAME:AddMessage("WCS_ClanUI no esta cargado", 1, 0, 0)
            end
        end,
        module = "WCS_BrainClanUI"
    },
    dashboard = {
        name = "Dashboard",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        tooltip = "Dashboard de Rendimiento - Metricas en Tiempo Real",
        onClick = function()
            SlashCmdList["WCSDASHBOARD"]("")
        end,
        module = "WCS_BrainDashboard"
    },
    toggleAllButtons = {
        name = "Btns",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        tooltip = "Mostrar/Ocultar TODOS los Botones Flotantes",
        onClick = function()
            local allHidden = true
            
            -- Verificar si algun boton esta visible
            -- Necesitamos acceder a los frames globales creados por cada boton
            if WCSBrainFloatingButton and WCSBrainFloatingButton:IsVisible() then
                allHidden = false
            end
            if WCS_BrainDQNFloatingButton and WCS_BrainDQNFloatingButton:IsVisible() then
                allHidden = false
            end
            if WCSBrainProfilesFloatingButton and WCSBrainProfilesFloatingButton:IsVisible() then
                allHidden = false
            end
            if WCS_BrainThinkingFloatingButton and WCS_BrainThinkingFloatingButton:IsVisible() then
                allHidden = false
            end
            if WCS_TutorialButton and WCS_TutorialButton:IsVisible() then
                allHidden = false
            end
            if WCSBrainDiagButton and WCSBrainDiagButton:IsVisible() then
                allHidden = false
            end
            
            -- Alternar todos los botones
            if allHidden then
                -- Mostrar todos
                if WCSBrainFloatingButton then WCSBrainFloatingButton:Show() end
                if WCS_BrainDQNFloatingButton then WCS_BrainDQNFloatingButton:Show() end
                if WCSBrainProfilesFloatingButton then WCSBrainProfilesFloatingButton:Show() end
                if WCS_BrainThinkingFloatingButton then WCS_BrainThinkingFloatingButton:Show() end
                if WCS_TutorialButton then WCS_TutorialButton:Show() end
                if WCSBrainDiagButton then WCSBrainDiagButton:Show() end
                DEFAULT_CHAT_FRAME:AddMessage("Todos los botones flotantes mostrados", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            else
                -- Ocultar todos
                if WCSBrainFloatingButton then WCSBrainFloatingButton:Hide() end
                if WCS_BrainDQNFloatingButton then WCS_BrainDQNFloatingButton:Hide() end
                if WCSBrainProfilesFloatingButton then WCSBrainProfilesFloatingButton:Hide() end
                if WCS_BrainThinkingFloatingButton then WCS_BrainThinkingFloatingButton:Hide() end
                if WCS_TutorialButton then WCS_TutorialButton:Hide() end
                if WCSBrainDiagButton then WCSBrainDiagButton:Hide() end
                DEFAULT_CHAT_FRAME:AddMessage("Todos los botones flotantes ocultados", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            end
        end,
        module = "WCS_BrainButtonBar"
    }
}

-- Funcion para crear un boton en la barra
local function CreateBarButton(buttonId, definition, index)
    local config = GetConfig()
    local size = config.buttonSize or BUTTON_SIZE
    
    local btn = CreateFrame("Button", "WCS_BrainBarButton_" .. buttonId, bar)
    btn:SetWidth(size)
    btn:SetHeight(size)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Fondo
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetTexture(0, 0, 0, 0.5)
    btn.bg = bg
    
    -- Icono
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetWidth(size - 8)
    icon:SetHeight(size - 8)
    icon:SetTexture(definition.icon)
    btn.icon = icon
    
    -- Borde
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(btn)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetAlpha(0)
    btn.border = border
    
    -- Label (si esta habilitado)
    if config.showLabels then
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOM", btn, "BOTTOM", 0, -12)
        label:SetText(definition.name)
        label:SetTextColor(COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        btn.label = label
    end
    
    -- Scripts
    btn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            definition.onClick()
        elseif arg1 == "RightButton" then
            if definition.onRightClick then
                definition.onRightClick()
            else
                WCS_BrainButtonBar:ShowButtonMenu(buttonId)
            end
        end
    end)
    
    btn:SetScript("OnEnter", function()
        btn.border:SetAlpha(1)
        GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(definition.tooltip, COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Click Izquierdo: Abrir/Cerrar", 1, 1, 1)
        if definition.onRightClick then
            GameTooltip:AddLine("Click Derecho: Mostrar/Ocultar boton flotante", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Click Derecho: Opciones", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function()
        btn.border:SetAlpha(0)
        GameTooltip:Hide()
    end)
    
    btn.buttonId = buttonId
    btn.definition = definition
    
    return btn
end

-- Funcion para actualizar el layout de la barra
function WCS_BrainButtonBar:UpdateLayout()
    if not bar then
        return
    end
    
    local config = GetConfig()
    local size = config.buttonSize or BUTTON_SIZE
    local spacing = config.spacing or BUTTON_SPACING
    
    -- Ordenar botones por orden configurado
    local sortedButtons = {}
    for id, btn in pairs(buttons) do
        if config.buttons[id] and config.buttons[id].enabled then
            table.insert(sortedButtons, {
                id = id,
                btn = btn,
                order = config.buttons[id].order or 999
            })
        end
    end
    
    table.sort(sortedButtons, function(a, b)
        return a.order < b.order
    end)
    
    -- Posicionar botones
    local totalWidth = 0
    local totalHeight = 0
    
    for i, data in ipairs(sortedButtons) do
        local btn = data.btn
        btn:ClearAllPoints()
        
        if config.orientation == "HORIZONTAL" then
            if i == 1 then
                btn:SetPoint("LEFT", bar, "LEFT", BAR_PADDING, 0)
            else
                btn:SetPoint("LEFT", sortedButtons[i-1].btn, "RIGHT", spacing, 0)
            end
            totalWidth = totalWidth + size + spacing
            totalHeight = size
        else -- VERTICAL
            if i == 1 then
                btn:SetPoint("TOP", bar, "TOP", 0, -BAR_PADDING)
            else
                btn:SetPoint("TOP", sortedButtons[i-1].btn, "BOTTOM", 0, -spacing)
            end
            totalWidth = size
            totalHeight = totalHeight + size + spacing
        end
        
        btn:Show()
    end
    
    -- Ocultar botones deshabilitados
    for id, btn in pairs(buttons) do
        if not config.buttons[id] or not config.buttons[id].enabled then
            btn:Hide()
        end
    end
    
    -- Ajustar tamano de la barra
    if config.orientation == "HORIZONTAL" then
        bar:SetWidth(totalWidth + BAR_PADDING * 2)
        bar:SetHeight(size + BAR_PADDING * 2)
    else
        bar:SetWidth(size + BAR_PADDING * 2)
        bar:SetHeight(totalHeight + BAR_PADDING * 2)
    end
end

-- Funcion para crear la barra
function WCS_BrainButtonBar:CreateBar()
    if bar then
        return bar
    end
    
    local config = GetConfig()
    
    -- Crear frame principal
    bar = CreateFrame("Frame", "WCS_BrainButtonBarFrame", UIParent)
    bar:SetWidth(400)
    bar:SetHeight(64)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() this:StartMoving() end)
    bar:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Fondo de la barra
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetTexture(0, 0, 0, 0.7)
    bar.bg = bg
    
    -- Borde de la barra
    local border = bar:CreateTexture(nil, "BORDER")
    border:SetAllPoints(bar)
    border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    border:SetTexCoord(0, 1, 0, 1)
    bar.border = border
    
    -- Titulo (también sirve como área de drag)
    local titleFrame = CreateFrame("Frame", nil, bar)
    titleFrame:SetPoint("TOP", bar, "TOP", 0, 0)
    titleFrame:SetWidth(200)
    titleFrame:SetHeight(24)
    titleFrame:EnableMouse(true)
    titleFrame:RegisterForDrag("LeftButton")
    titleFrame:SetScript("OnDragStart", function() bar:StartMoving() end)
    titleFrame:SetScript("OnDragStop", function() bar:StopMovingOrSizing() end)
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", titleFrame, "CENTER", 0, 0)
    title:SetText("|cFF9482C9WCS|r |cFF00FF00Brain|r")
    bar.title = title
    bar.titleFrame = titleFrame
    
    -- Boton de cerrar
    local closeBtn = CreateFrame("Button", nil, bar)
    closeBtn:SetWidth(16)
    closeBtn:SetHeight(16)
    closeBtn:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function()
        WCS_BrainButtonBar:Hide()
    end)
    bar.closeBtn = closeBtn
    
    -- Boton de configuracion
    local configBtn = CreateFrame("Button", nil, bar)
    configBtn:SetWidth(16)
    configBtn:SetHeight(16)
    configBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -2, 0)
    configBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    configBtn:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
    configBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    configBtn:SetScript("OnClick", function()
        WCS_BrainButtonBar:ShowConfigMenu()
    end)
    bar.configBtn = configBtn
    
    -- Boton de bloqueo
    local lockBtn = CreateFrame("Button", nil, bar)
    lockBtn:SetWidth(16)
    lockBtn:SetHeight(16)
    lockBtn:SetPoint("TOPRIGHT", configBtn, "TOPLEFT", -2, 0)
    lockBtn:SetScript("OnClick", function()
        config.locked = not config.locked
        WCS_BrainButtonBar:UpdateLockState()
    end)
    bar.lockBtn = lockBtn
    
    -- Scripts de arrastre
    bar:SetScript("OnDragStart", function()
        if not config.locked then
            this:StartMoving()
        end
    end)
    
    bar:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        WCS_BrainButtonBar:SavePosition()
    end)
    
    -- Crear botones
    local buttonCount = 0
    for id, definition in pairs(buttonDefinitions) do
        buttons[id] = CreateBarButton(id, definition, 1)
        buttonCount = buttonCount + 1
        DEFAULT_CHAT_FRAME:AddMessage("Creando boton: " .. id, 0.5, 1, 0.5)
    end
    DEFAULT_CHAT_FRAME:AddMessage("Total botones creados: " .. buttonCount, 1, 1, 0)
    
    -- Restaurar posicion
    bar:ClearAllPoints()
    bar:SetPoint(
        config.point,
        config.relativeTo,
        config.relativePoint,
        config.xOffset,
        config.yOffset
    )
    
    -- Actualizar layout
    self:UpdateLayout()
    self:UpdateLockState()
    
    -- Mostrar/ocultar segun configuracion
    if config.visible then
        bar:Show()
    else
        bar:Hide()
    end
    
    return bar
end

-- Funcion para actualizar estado de bloqueo
function WCS_BrainButtonBar:UpdateLockState()
    if not bar then
        return
    end
    
    local config = GetConfig()
    
    if config.locked then
        bar:RegisterForDrag()
        bar.lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
        bar.lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-Locked-Down")
        bar.title:Hide()
        bar.closeBtn:Hide()
        bar.configBtn:Hide()
        bar.bg:SetAlpha(0.3)
    else
        bar:RegisterForDrag("LeftButton")
        bar.lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-UnLocked-Up")
        bar.lockBtn:SetPushedTexture("Interface\\Buttons\\LockButton-UnLocked-Down")
        bar.title:Show()
        bar.closeBtn:Show()
        bar.configBtn:Show()
        bar.bg:SetAlpha(0.7)
    end
end

-- Funcion para guardar posicion
function WCS_BrainButtonBar:SavePosition()
    if not bar then
        return
    end
    
    local config = GetConfig()
    local point, relativeTo, relativePoint, xOffset, yOffset = bar:GetPoint()
    
    config.point = point or "TOP"
    config.relativeTo = "UIParent"
    config.relativePoint = relativePoint or "TOP"
    config.xOffset = xOffset or 0
    config.yOffset = yOffset or -10
end

-- Funcion para mostrar menu de configuracion
function WCS_BrainButtonBar:ShowConfigMenu()
    local config = GetConfig()
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9WCS Brain|r - Menu de Configuracion de Barra:", 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("1. Cambiar orientacion (Actual: " .. config.orientation .. ")", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("2. Cambiar tamano de botones (Actual: " .. config.buttonSize .. ")", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("3. Mostrar/Ocultar etiquetas (Actual: " .. (config.showLabels and "SI" or "NO") .. ")", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("4. Gestionar botones visibles", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("5. Resetear posicion", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("6. Cancelar", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Usa /brainbar config <numero>", 0.7, 0.7, 0.7)
end

-- Funcion para mostrar menu de boton
function WCS_BrainButtonBar:ShowButtonMenu(buttonId)
    local config = GetConfig()
    local definition = buttonDefinitions[buttonId]
    
    if not definition then
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9WCS Brain|r - Menu de " .. definition.name .. ":", 1, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("1. Abrir interfaz", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("2. Ocultar este boton", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("3. Mover a la izquierda", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("4. Mover a la derecha", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("5. Cancelar", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Usa /brainbar button " .. buttonId .. " <numero>", 0.7, 0.7, 0.7)
    
    WCS_BrainButtonBar.currentButtonMenu = buttonId
end

-- Funcion para mostrar la barra
function WCS_BrainButtonBar:Show()
    if not bar then
        self:CreateBar()
    end
    bar:Show()
    local config = GetConfig()
    config.visible = true
end

-- Funcion para ocultar la barra
function WCS_BrainButtonBar:Hide()
    if bar then
        bar:Hide()
    end
    local config = GetConfig()
    config.visible = false
end

-- Funcion para alternar visibilidad
function WCS_BrainButtonBar:Toggle()
    if not bar then
        self:CreateBar()
    end
    
    if bar:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- Comando slash principal
SLASH_BRAINBAR1 = "/brainbar"
SLASH_BRAINBAR2 = "/wcsbar"
SlashCmdList["BRAINBAR"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "[^%s]+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] or ""
    
    if cmd == "show" then
        WCS_BrainButtonBar:Show()
        DEFAULT_CHAT_FRAME:AddMessage("Barra de botones mostrada", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
    elseif cmd == "hide" then
        WCS_BrainButtonBar:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("Barra de botones ocultada", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
    elseif cmd == "toggle" then
        WCS_BrainButtonBar:Toggle()
    elseif cmd == "lock" then
        local config = GetConfig()
        config.locked = true
        WCS_BrainButtonBar:UpdateLockState()
        DEFAULT_CHAT_FRAME:AddMessage("Barra bloqueada", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
    elseif cmd == "unlock" then
        local config = GetConfig()
        config.locked = false
        WCS_BrainButtonBar:UpdateLockState()
        DEFAULT_CHAT_FRAME:AddMessage("Barra desbloqueada", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
    elseif cmd == "reset" then
        WCS_BrainButtonBarConfig = nil
        WCS_BrainButtonBar:CreateBar()
        DEFAULT_CHAT_FRAME:AddMessage("Configuracion reseteada. Todos los botones habilitados.", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
    elseif cmd == "config" then
        local option = tonumber(args[2])
        if option == 1 then
            local config = GetConfig()
            if config.orientation == "HORIZONTAL" then
                config.orientation = "VERTICAL"
            else
                config.orientation = "HORIZONTAL"
            end
            WCS_BrainButtonBar:UpdateLayout()
            DEFAULT_CHAT_FRAME:AddMessage("Orientacion cambiada a: " .. config.orientation, COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        elseif option == 2 then
            local config = GetConfig()
            local newSize = tonumber(args[3]) or 48
            if newSize >= 32 and newSize <= 64 then
                config.buttonSize = newSize
                WCS_BrainButtonBar:UpdateLayout()
                DEFAULT_CHAT_FRAME:AddMessage("Tamano de botones: " .. newSize, COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            else
                DEFAULT_CHAT_FRAME:AddMessage("Tamano debe estar entre 32 y 64", 1, 0, 0)
            end
        elseif option == 3 then
            local config = GetConfig()
            config.showLabels = not config.showLabels
            WCS_BrainButtonBar:CreateBar()
            DEFAULT_CHAT_FRAME:AddMessage("Etiquetas: " .. (config.showLabels and "SI" or "NO"), COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        elseif option == 5 then
            local config = GetConfig()
            config.point = "TOP"
            config.xOffset = 0
            config.yOffset = -10
            if bar then
                bar:ClearAllPoints()
                bar:SetPoint("TOP", UIParent, "TOP", 0, -10)
            end
            DEFAULT_CHAT_FRAME:AddMessage("Posicion reseteada", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        else
            WCS_BrainButtonBar:ShowConfigMenu()
        end
    elseif cmd == "button" then
        local buttonId = args[2]
        local option = tonumber(args[3])
        
        if buttonId and WCS_BrainButtonBar.currentButtonMenu == buttonId then
            if option == 1 then
                local def = buttonDefinitions[buttonId]
                if def then
                    def.onClick()
                end
            elseif option == 2 then
                local config = GetConfig()
                config.buttons[buttonId].enabled = false
                WCS_BrainButtonBar:UpdateLayout()
                DEFAULT_CHAT_FRAME:AddMessage("Boton ocultado", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
            end
            WCS_BrainButtonBar.currentButtonMenu = nil
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9WCS Brain|r - Barra de Botones:", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar show - Mostrar barra", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar hide - Ocultar barra", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar toggle - Alternar visibilidad", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar lock - Bloquear posicion", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar unlock - Desbloquear posicion", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar config - Menu de configuracion", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  /brainbar reset - Resetear configuracion (habilita todos los botones)", 1, 1, 1)
    end
end

-- Inicializacion automatica
local function Initialize()
    WCS_BrainButtonBar:CreateBar()
    DEFAULT_CHAT_FRAME:AddMessage("WCS_BrainButtonBar cargado. Usa /brainbar para opciones.", COLOR_BRAIN.r, COLOR_BRAIN.g, COLOR_BRAIN.b)
end

-- Registrar evento de carga
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("VARIABLES_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" or event == "VARIABLES_LOADED" then
        Initialize()
        this:UnregisterAllEvents()
    end
end)

