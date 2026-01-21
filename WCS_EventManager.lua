--[[
    WCS_EventManager.lua - Bus de Eventos Centralizado
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Provee una interfaz unificada para el manejo de eventos, reduciendo 
    la necesidad de múltiples frames invisibles y mejorando el rendimiento.
]]--

WCS_EventManager = WCS_EventManager or {}
WCS_EventManager.VERSION = "1.0.0"

-- Registro de listeners: { ["EVENT_NAME"] = { {func=callback, owner=ownerID}, ... } }
WCS_EventManager.Registry = {}

-- Frame principal para recibir eventos de WoW
WCS_EventManager.Frame = CreateFrame("Frame", "WCS_EventFrame")

-- ============================================================================
-- FUNCIONES PRIVADAS
-- ============================================================================

local function DebugPrint(msg)
    if WCS_Brain and WCS_Brain.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[EventManager]|r " .. tostring(msg))
    end
end

-- Handler principal OnEvent
local function OnEvent()
    local event = event  -- Lua 5.0 global
    local args = arg     -- Lua 5.0 global args table
    
    if not WCS_EventManager.Registry[event] then return end
    
    -- Iterar sobre todos los listeners registrados para este evento
    for i, listener in ipairs(WCS_EventManager.Registry[event]) do
        if listener.func then
            -- Llamada protegida para evitar crashes en cadena
            local status, err = pcall(listener.func, event, unpack(args or {}))
            if not status then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[EventManager] Error en " .. event .. ": " .. tostring(err))
            end
        end
    end
end

WCS_EventManager.Frame:SetScript("OnEvent", OnEvent)

-- ============================================================================
-- API PÚBLICA
-- ============================================================================

-- Registrar un callback para un evento
-- @param event: Nombre del evento (string)
-- @param callback: Función a ejecutar
-- @param ownerID: Identificador del modulo propietario (string) - importante para Unregister
function WCS_EventManager:Register(event, callback, ownerID)
    if not event or type(callback) ~= "function" then
        DebugPrint("Intento de registro invalido para " .. tostring(event))
        return false
    end
    
    ownerID = ownerID or "Unknown"
    
    -- Inicializar tabla de evento si no existe
    if not self.Registry[event] then
        self.Registry[event] = {}
        
        -- Si es un evento de WoW, registrarlo en el frame real
        -- (Ignorar eventos custom internos que empiezan con WCS_)
        if not string.find(event, "^WCS_") then
            self.Frame:RegisterEvent(event)
            DebugPrint("Registrado evento de WoW: " .. event)
        end
    end
    
    -- Evitar duplicados para el mismo owner
    for i, listener in ipairs(self.Registry[event]) do
        if listener.owner == ownerID then
            -- Actualizar callback existente
            listener.func = callback
            return true
        end
    end
    
    -- Añadir nuevo listener
    table.insert(self.Registry[event], {
        func = callback,
        owner = ownerID
    })
    
    return true
end

-- Eliminar registro
function WCS_EventManager:Unregister(event, ownerID)
    if not self.Registry[event] then return end
    
    local found = false
    -- Recorrer hacia atrás para borrar seguro
    for i = table.getn(self.Registry[event]), 1, -1 do
        if self.Registry[event][i].owner == ownerID then
            table.remove(self.Registry[event], i)
            found = true
        end
    end
    
    -- Si ya no quedan listeners y es evento de WoW, desregistrar del frame
    -- (Opcional: A veces es mejor dejarlo si se va a reusar pronto)
    if table.getn(self.Registry[event]) == 0 then
        if not string.find(event, "^WCS_") then
            self.Frame:UnregisterEvent(event)
            DebugPrint("Desregistrado evento de WoW: " .. event)
        end
        self.Registry[event] = nil
    end
    
    return found
end

-- Disparar un evento interno (Custom Event)
function WCS_EventManager:Fire(event, ...)
    if not self.Registry[event] then return end
    
    local args = arg or {}
    
    -- Mismo loop que OnEvent
    for i, listener in ipairs(self.Registry[event]) do
        if listener.func then
            local status, err = pcall(listener.func, event, unpack(args))
            if not status then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[EventManager/Fire] Error en " .. event .. ": " .. tostring(err))
            end
        end
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS_EventManager]|r Sistema de eventos centralizado v" .. WCS_EventManager.VERSION .. " cargado")
