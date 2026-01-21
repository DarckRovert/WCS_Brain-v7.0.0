--[[
    WCS_BrainProfiles.lua - Sistema de Perfiles v1.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Permite guardar y cambiar entre diferentes configuraciones
    según spec/situación (Solo, Dungeon, Raid, PvP, Farming)
    
    Autor: Elnazzareno (DarckRovert)
    Twitch: twitch.tv/darckrovert
    Kick: kick.com/darckrovert
]]--

WCS_BrainProfiles = WCS_BrainProfiles or {}
WCS_BrainProfiles.VERSION = "1.0.0"

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
function WCS_BrainProfiles:Initialize()
    -- Crear SavedVariables si no existe
    if not WCS_BrainSaved then
        WCS_BrainSaved = {}
    end
    
    if not WCS_BrainSaved.profiles then
        WCS_BrainSaved.profiles = {}
    end
    
    if not WCS_BrainSaved.currentProfile then
        WCS_BrainSaved.currentProfile = "Default"
    end
    
    if not WCS_BrainSaved.autoSwitch then
        WCS_BrainSaved.autoSwitch = false
    end
    
    -- Crear perfiles predefinidos si no existen
    self:CreateDefaultProfiles()
    
    -- Cargar perfil actual
    if WCS_BrainSaved.currentProfile then
        self:LoadProfile(WCS_BrainSaved.currentProfile)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS_BrainProfiles]|r v" .. self.VERSION .. " cargado. Usa |cFFFFCC00/brainprofile|r")
end

-- ============================================================================
-- PERFILES PREDEFINIDOS
-- ============================================================================
function WCS_BrainProfiles:CreateDefaultProfiles()
    -- Solo crear si no existen
    if not WCS_BrainSaved.profiles["Affliction Solo"] then
        self:CreateProfile("Affliction Solo", {
            spec = "affliction",
            situation = "solo",
            ai = {
                enabled = true,
                debug = false,
                aggressiveness = 0.6,
                manaConservation = 0.8,
            },
            petAI = {
                enabled = true,
                mode = "defensive",
                preferredPet = "Voidwalker",
                autoFollow = true,
                notifications = true,
                sounds = true,
            },
            petUI = {
                compactMode = false,
                showBuffs = true,
                showHappiness = true,
                monitorEvents = true,
            },
            spellPriorities = {
                ["Corruption"] = 9,
                ["Curse of Agony"] = 8,
                ["Drain Life"] = 7,
                ["Shadow Bolt"] = 5,
                ["Fear"] = 8,
            },
            thresholds = {
                healthLow = 40,
                healthCritical = 20,
                manaLow = 30,
                manaCritical = 15,
            },
        })
    end
    
    if not WCS_BrainSaved.profiles["Affliction Raid"] then
        self:CreateProfile("Affliction Raid", {
            spec = "affliction",
            situation = "raid",
            ai = {
                enabled = true,
                debug = false,
                aggressiveness = 0.9,
                manaConservation = 0.5,
            },
            petAI = {
                enabled = true,
                mode = "passive",
                preferredPet = "Imp",
                autoFollow = true,
                notifications = false,
                sounds = false,
            },
            petUI = {
                compactMode = true,
                showBuffs = true,
                showHappiness = false,
                monitorEvents = false,
            },
            spellPriorities = {
                ["Corruption"] = 10,
                ["Curse of Agony"] = 9,
                ["Siphon Life"] = 9,
                ["Shadow Bolt"] = 8,
                ["Immolate"] = 7,
            },
            thresholds = {
                healthLow = 30,
                healthCritical = 15,
                manaLow = 20,
                manaCritical = 10,
            },
        })
    end
    
    if not WCS_BrainSaved.profiles["Destruction Dungeon"] then
        self:CreateProfile("Destruction Dungeon", {
            spec = "destruction",
            situation = "dungeon",
            ai = {
                enabled = true,
                debug = false,
                aggressiveness = 0.8,
                manaConservation = 0.6,
            },
            petAI = {
                enabled = true,
                mode = "assist",
                preferredPet = "Succubus",
                autoFollow = true,
                notifications = true,
                sounds = true,
            },
            petUI = {
                compactMode = false,
                showBuffs = true,
                showHappiness = false,
                monitorEvents = true,
            },
            spellPriorities = {
                ["Shadow Bolt"] = 9,
                ["Immolate"] = 8,
                ["Conflagrate"] = 10,
                ["Shadowburn"] = 10,
                ["Rain of Fire"] = 6,
            },
            thresholds = {
                healthLow = 35,
                healthCritical = 18,
                manaLow = 25,
                manaCritical = 12,
            },
        })
    end
    
    if not WCS_BrainSaved.profiles["Destruction PvP"] then
        self:CreateProfile("Destruction PvP", {
            spec = "destruction",
            situation = "pvp",
            ai = {
                enabled = true,
                debug = false,
                aggressiveness = 1.0,
                manaConservation = 0.3,
            },
            petAI = {
                enabled = true,
                mode = "aggressive",
                preferredPet = "Felhunter",
                autoFollow = false,
                notifications = true,
                sounds = true,
            },
            petUI = {
                compactMode = false,
                showBuffs = true,
                showHappiness = false,
                monitorEvents = true,
            },
            spellPriorities = {
                ["Shadowburn"] = 10,
                ["Conflagrate"] = 10,
                ["Death Coil"] = 9,
                ["Fear"] = 9,
                ["Shadow Bolt"] = 7,
                ["Howl of Terror"] = 8,
            },
            thresholds = {
                healthLow = 50,
                healthCritical = 25,
                manaLow = 30,
                manaCritical = 15,
            },
        })
    end
    
    if not WCS_BrainSaved.profiles["Demonology Farming"] then
        self:CreateProfile("Demonology Farming", {
            spec = "demonology",
            situation = "farming",
            ai = {
                enabled = true,
                debug = false,
                aggressiveness = 0.9,
                manaConservation = 0.4,
            },
            petAI = {
                enabled = true,
                mode = "aggressive",
                preferredPet = "Felguard",
                autoFollow = true,
                notifications = false,
                sounds = false,
            },
            petUI = {
                compactMode = true,
                showBuffs = false,
                showHappiness = false,
                monitorEvents = false,
            },
            spellPriorities = {
                ["Seed of Corruption"] = 10,
                ["Rain of Fire"] = 9,
                ["Hellfire"] = 8,
                ["Corruption"] = 7,
                ["Shadow Bolt"] = 5,
            },
            thresholds = {
                healthLow = 30,
                healthCritical = 15,
                manaLow = 20,
                manaCritical = 10,
            },
        })
    end
end

-- ============================================================================
-- GESTIÓN DE PERFILES
-- ============================================================================
function WCS_BrainProfiles:CreateProfile(name, data)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Nombre de perfil inválido")
        return false
    end
    
    WCS_BrainSaved.profiles[name] = data
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil '" .. name .. "' creado")
    return true
end

function WCS_BrainProfiles:DeleteProfile(name)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Nombre de perfil inválido")
        return false
    end
    
    if not WCS_BrainSaved.profiles[name] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Perfil '" .. name .. "' no existe")
        return false
    end
    
    -- No permitir eliminar el perfil actual
    if WCS_BrainSaved.currentProfile == name then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r No puedes eliminar el perfil activo")
        return false
    end
    
    WCS_BrainSaved.profiles[name] = nil
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil '" .. name .. "' eliminado")
    return true
end

function WCS_BrainProfiles:LoadProfile(name)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Nombre de perfil inválido")
        return false
    end
    
    local profile = WCS_BrainSaved.profiles[name]
    if not profile then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Perfil '" .. name .. "' no existe")
        return false
    end
    
    -- Aplicar configuración
    self:ApplyProfile(profile)
    
    -- Guardar como perfil actual
    WCS_BrainSaved.currentProfile = name
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil '" .. name .. "' cargado")
    PlaySound("igMainMenuOptionCheckBoxOn")
    return true
end

function WCS_BrainProfiles:SaveProfile(name)
    if not name or name == "" then
        name = WCS_BrainSaved.currentProfile
    end
    
    -- Capturar configuración actual
    local profile = self:CaptureCurrentConfig()
    
    WCS_BrainSaved.profiles[name] = profile
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil '" .. name .. "' guardado")
    PlaySound("igMainMenuOptionCheckBoxOn")
    return true
end

function WCS_BrainProfiles:GetCurrentProfile()
    return WCS_BrainSaved.currentProfile
end

function WCS_BrainProfiles:ListProfiles()
    local profiles = {}
    for name, _ in pairs(WCS_BrainSaved.profiles) do
        table.insert(profiles, name)
    end
    table.sort(profiles)
    return profiles
end

-- ============================================================================
-- APLICACIÓN DE CONFIGURACIÓN
-- ============================================================================
function WCS_BrainProfiles:ApplyProfile(profile)
    if not profile then return end
    
    -- Aplicar configuración de IA
    if profile.ai and WCS_Brain then
        WCS_Brain.ENABLED = profile.ai.enabled or false
        WCS_Brain.DEBUG = profile.ai.debug or false
        -- Aquí se pueden agregar más configuraciones de IA
    end
    
    -- Aplicar configuración de Pet AI
    if profile.petAI then
        if WCS_BrainPetAI_SetEnabled then
            WCS_BrainPetAI_SetEnabled(profile.petAI.enabled)
        end
        
        if WCS_BrainPetAI and WCS_BrainPetAI.SetMode then
            WCS_BrainPetAI:SetMode(profile.petAI.mode)
        end
        
        -- Aplicar configuración de Pet UI
        if WCS_BrainCharSaved and WCS_BrainCharSaved.petUIConfig then
            WCS_BrainCharSaved.petUIConfig.notifications = profile.petAI.notifications
            WCS_BrainCharSaved.petUIConfig.sounds = profile.petAI.sounds
            WCS_BrainCharSaved.petUIConfig.autoFollow = profile.petAI.autoFollow
        end
    end
    
    -- Aplicar configuración de Pet UI
    if profile.petUI and WCS_BrainCharSaved and WCS_BrainCharSaved.petUIConfig then
        WCS_BrainCharSaved.petUIConfig.compactMode = profile.petUI.compactMode
        
        -- Aplicar modo compacto si está activado
        if profile.petUI.compactMode and WCS_BrainPetUI and WCS_BrainPetUI.ToggleCompactMode then
            WCS_BrainPetUI:ToggleCompactMode(true)
        end
    end
    
    -- Aplicar prioridades de hechizos
    if profile.spellPriorities and WCS_BrainAI then
        -- Aquí se integraría con el sistema de scoring de WCS_BrainAI
        -- Por ahora solo guardamos las prioridades
        if not WCS_BrainAI.CustomPriorities then
            WCS_BrainAI.CustomPriorities = {}
        end
        WCS_BrainAI.CustomPriorities = profile.spellPriorities
    end
    
    -- Aplicar umbrales
    if profile.thresholds and WCS_Brain and WCS_Brain.Context then
        -- Integrar con el sistema de contexto
        -- Esto requeriría modificar WCS_Brain para usar estos umbrales
    end
    
    -- Actualizar UI si está abierta
    if WCS_BrainUI and WCS_BrainUI.Update then
        WCS_BrainUI:Update()
    end
    
    if WCS_BrainPetUI and WCS_BrainPetUI.UpdateButtonVisuals then
        WCS_BrainPetUI:UpdateButtonVisuals()
    end
end

function WCS_BrainProfiles:CaptureCurrentConfig()
    local profile = {
        spec = "unknown",
        situation = "unknown",
        ai = {},
        petAI = {},
        petUI = {},
        spellPriorities = {},
        thresholds = {},
    }
    
    -- Capturar configuración de IA
    if WCS_Brain then
        profile.ai.enabled = WCS_Brain.ENABLED or false
        profile.ai.debug = WCS_Brain.DEBUG or false
    end
    
    -- Capturar configuración de Pet AI
    if WCS_BrainPetAI then
        profile.petAI.enabled = WCS_BrainPetAI_IsEnabled and WCS_BrainPetAI_IsEnabled() or false
        profile.petAI.mode = WCS_BrainPetAI.currentMode or "defensive"
    end
    
    -- Capturar configuración de Pet UI
    if WCS_BrainCharSaved and WCS_BrainCharSaved.petUIConfig then
        local config = WCS_BrainCharSaved.petUIConfig
        profile.petAI.notifications = config.notifications
        profile.petAI.sounds = config.sounds
        profile.petAI.autoFollow = config.autoFollow
        profile.petUI.compactMode = config.compactMode
    end
    
    -- Capturar prioridades personalizadas
    if WCS_BrainAI and WCS_BrainAI.CustomPriorities then
        profile.spellPriorities = WCS_BrainAI.CustomPriorities
    end
    
    return profile
end

-- ============================================================================
-- EXPORTAR/IMPORTAR
-- ============================================================================
function WCS_BrainProfiles:ExportProfile(name)
    if not name or name == "" then
        name = WCS_BrainSaved.currentProfile
    end
    
    local profile = WCS_BrainSaved.profiles[name]
    if not profile then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Perfil '" .. name .. "' no existe")
        return nil
    end
    
    -- Serializar perfil (simplificado)
    local serialized = "WCS_PROFILE:" .. name .. ":"
    -- Aquí iría la serialización completa
    -- Por ahora retornamos un placeholder
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil exportado (copia el string)")
    return serialized
end

function WCS_BrainProfiles:ImportProfile(serialized)
    if not serialized or serialized == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r String de importación inválido")
        return false
    end
    
    -- Deserializar perfil
    -- Por ahora solo un placeholder
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Profiles]|r Perfil importado")
    return true
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSBRAINPROFILE1 = "/brainprofile"
SLASH_WCSBRAINPROFILE2 = "/profile"
SlashCmdList["WCSBRAINPROFILE"] = function(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1]
    
    if not cmd or cmd == "" or cmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[Profiles]|r Comandos disponibles:")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile list|r - Lista perfiles")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile load <nombre>|r - Carga perfil")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile save [nombre]|r - Guarda perfil")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile delete <nombre>|r - Elimina perfil")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile current|r - Muestra perfil actual")
        DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00/brainprofile ui|r - Abre interfaz")
        return
    end
    
    if cmd == "list" then
        local profiles = WCS_BrainProfiles:ListProfiles()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[Profiles]|r Perfiles disponibles:")
        for _, name in ipairs(profiles) do
            local marker = ""
            if name == WCS_BrainSaved.currentProfile then
                marker = " |cFF00FF00(actual)|r"
            end
            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFCC00" .. name .. "|r" .. marker)
        end
        
    elseif cmd == "load" then
        local name = args[2]
        if not name then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Uso: /brainprofile load <nombre>")
            return
        end
        WCS_BrainProfiles:LoadProfile(name)
        
    elseif cmd == "save" then
        local name = args[2]
        WCS_BrainProfiles:SaveProfile(name)
        
    elseif cmd == "delete" then
        local name = args[2]
        if not name then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Uso: /brainprofile delete <nombre>")
            return
        end
        WCS_BrainProfiles:DeleteProfile(name)
        
    elseif cmd == "current" then
        local current = WCS_BrainProfiles:GetCurrentProfile()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[Profiles]|r Perfil actual: |cFFFFCC00" .. current .. "|r")
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Profiles]|r Comando desconocido. Usa /brainprofile help")
    end
end

-- ============================================================================
-- REGISTRO DE COMANDOS SLASH
-- ============================================================================
SLASH_BRAINPROFILE1 = "/brainprofile"
SLASH_BRAINPROFILE2 = "/profile"
SlashCmdList["BRAINPROFILE"] = function(msg)
    -- Agregar comando "ui" para abrir interfaz grafica
    if msg == "ui" then
        if WCS_BrainProfilesUI then
            WCS_BrainProfilesUI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Perfiles]|r UI no disponible")
        end
    else
        WCS_BrainProfiles_SlashHandler(msg)
    end
end

-- ============================================================================
-- FUNCIONES PARA LA UI
-- ============================================================================

-- Obtener lista de nombres de perfiles
function WCS_BrainProfiles.GetProfileList()
    local list = {}
    if WCS_BrainSaved and WCS_BrainSaved.profiles then
        for name, _ in pairs(WCS_BrainSaved.profiles) do
            table.insert(list, name)
        end
    end
    return list
end

-- Obtener detalles de un perfil
function WCS_BrainProfiles.GetProfileDetails(name)
    if WCS_BrainSaved and WCS_BrainSaved.profiles and WCS_BrainSaved.profiles[name] then
        return WCS_BrainSaved.profiles[name]
    end
    return nil
end

-- Obtener nombre del perfil actual
function WCS_BrainProfiles.GetCurrentProfileName()
    if WCS_BrainSaved and WCS_BrainSaved.currentProfile then
        return WCS_BrainSaved.currentProfile
    end
    return nil
end

-- Crear nuevo perfil desde configuracion actual
function WCS_BrainProfiles.CreateNewProfile(name, description)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Perfiles]|r Nombre invalido")
        return false
    end
    
    if WCS_BrainSaved.profiles[name] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Perfiles]|r El perfil '" .. name .. "' ya existe")
        return false
    end
    
    -- Capturar configuracion actual
    local config = WCS_BrainProfiles.CaptureCurrentConfig()
    config.description = description or "Perfil personalizado"
    
    WCS_BrainProfiles:CreateProfile(name, config)
    return true
end

-- Actualizar perfil existente
function WCS_BrainProfiles.UpdateProfile(name, config)
    if not WCS_BrainSaved.profiles[name] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Perfiles]|r El perfil '" .. name .. "' no existe")
        return false
    end
    
    WCS_BrainSaved.profiles[name] = config
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Perfiles]|r Perfil '" .. name .. "' actualizado")
    PlaySound("igMainMenuOptionCheckBoxOn")
    return true
end

-- ============================================================================
-- INICIALIZACIÓN AL CARGAR
-- ============================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_BrainProfiles:Initialize()
    end
end)

