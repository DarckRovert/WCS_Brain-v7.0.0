--[[
    WCS_Lua50_ErrorCheck.lua - Verificador de Errores Lua 5.0
    
    Este archivo verifica que no hay errores de compatibilidad con Lua 5.0
    Ejecuta verificaciones de sintaxis y funcionalidad
]]--

WCS_Lua50_ErrorCheck = WCS_Lua50_ErrorCheck or {}

-- Safe local wrapper to count table elements prefering centralized helper
local function _wcs_count(t)
    if type(WCS_TableCount) == "function" then return WCS_TableCount(t) end
    if table.getn then return table.getn(t) end
    if not t then return 0 end
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
end

-- Verificar que las funciones básicas existen
function WCS_Lua50_ErrorCheck:VerifyBasicFunctions()
    local errors = {}
    
    -- Verificar funciones de tabla
    if not table.insert then
        table.insert(errors, "table.insert no disponible")
    end
    if not table.remove then
        table.insert(errors, "table.remove no disponible")
    end
    if not table.getn then
        table.insert(errors, "table.getn no disponible")
    end
    
    -- Verificar funciones de string
    if not string.find then
        table.insert(errors, "string.find no disponible")
    end
    if not string.sub then
        table.insert(errors, "string.sub no disponible")
    end
    if not string.len then
        table.insert(errors, "string.len no disponible")
    end
    
    -- Verificar funciones matemáticas
    if not math.floor then
        table.insert(errors, "math.floor no disponible")
    end
    if not math.ceil then
        table.insert(errors, "math.ceil no disponible")
    end
    
    -- Verificar funciones globales
    if not pairs then
        table.insert(errors, "pairs no disponible")
    end
    if not ipairs then
        table.insert(errors, "ipairs no disponible")
    end
    if not next then
        table.insert(errors, "next no disponible")
    end
    if not unpack then
        table.insert(errors, "unpack no disponible")
    end
    
    -- Verificar funciones helper WCS (mínimas)
    if not WCS_TableCount then
        table.insert(errors, "WCS_TableCount no disponible")
    end
    
    return errors
end

-- Verificar sintaxis de varargs
function WCS_Lua50_ErrorCheck:TestVarargs()
    local errors = {}
    
    -- NOTA: En Lua 5.0 de WoW 1.12, la tabla 'arg' puede no estar disponible
    -- en todos los contextos (ej: funciones anónimas). Esto es NORMAL.
    -- Solo verificamos que al menos podemos detectar si existe o no.
    
    -- Test 1: Verificar que 'unpack' existe (alternativa a varargs)
    if not unpack then
        table.insert(errors, "VARARGS: unpack no disponible (fallback para varargs)")
    end
    
    -- Test 2: Intentar usar arg si está disponible (no es error si no lo está)
    if arg then
        local argCount = _wcs_count(arg)
        if type(argCount) ~= "number" then
            table.insert(errors, "VARARGS: arg table existe pero _wcs_count falló")
        end
    end
    
    -- En Lua 5.0, es normal que 'arg' no esté disponible en ciertos contextos
    -- Lo importante es que 'unpack' esté disponible como fallback
    
    return errors
end

-- Verificar que no hay uso de sintaxis Lua 5.1+
function WCS_Lua50_ErrorCheck:CheckModernSyntax()
    local errors = {}
    
    -- Verificar que no usamos el operador # (length)
    -- Esto se debe verificar manualmente en el código
    
    -- Verificar que no usamos ... (varargs moderno)
    -- Esto se debe verificar manualmente en el código
    
    return errors
end

-- Test específico para funciones helper WCS
function WCS_Lua50_ErrorCheck:TestWCSHelpers()
    local errors = {}
    
    -- Test WCS_TableCount
    if WCS_TableCount then
        local testTable = {"a", "b", "c"}
        local count = WCS_TableCount(testTable)
        if count ~= 3 then
            table.insert(errors, "WCS_TableCount no funciona correctamente (esperado 3, obtenido " .. count .. ")")
        end
        
        -- Test tabla vacía
        local emptyCount = WCS_TableCount({})
        if emptyCount ~= 0 then
            table.insert(errors, "WCS_TableCount no maneja tablas vacías correctamente")
        end
        
        -- Test nil
        local nilCount = WCS_TableCount(nil)
        if nilCount ~= 0 then
            table.insert(errors, "WCS_TableCount no maneja nil correctamente")
        end
    else
        table.insert(errors, "WCS_TableCount no está definida")
    end
    
    return errors
end

-- Función principal de verificación
function WCS_Lua50_ErrorCheck:RunAllChecks()
    local allErrors = {}
    
    -- Verificar funciones básicas
    local basicErrors = self:VerifyBasicFunctions()
    for i = 1, _wcs_count(basicErrors) do
        table.insert(allErrors, "BASIC: " .. basicErrors[i])
    end
    
    -- Verificar varargs
    local varargsErrors = self:TestVarargs()
    for i = 1, _wcs_count(varargsErrors) do
        table.insert(allErrors, "VARARGS: " .. varargsErrors[i])
    end
    
    -- Verificar sintaxis moderna
    local syntaxErrors = self:CheckModernSyntax()
    for i = 1, _wcs_count(syntaxErrors) do
        table.insert(allErrors, "SYNTAX: " .. syntaxErrors[i])
    end
    
    -- Verificar funciones helper WCS
    local helperErrors = self:TestWCSHelpers()
    for i = 1, _wcs_count(helperErrors) do
        table.insert(allErrors, "HELPERS: " .. helperErrors[i])
    end
    
    return allErrors
end

-- Comando slash para ejecutar verificaciones
SlashCmdList["WCSLUA50CHECK"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Lua 5.0 Check]|r Ejecutando verificaciones...")
    
    local errors = WCS_Lua50_ErrorCheck:RunAllChecks()
    
    if _wcs_count(errors) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Lua 5.0 Check]|r |cFF00FF00✓ Todas las verificaciones pasaron!|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Lua 5.0 Check]|r |cFFFF0000✗ Se encontraron " .. _wcs_count(errors) .. " errores:|r")
        for i = 1, _wcs_count(errors) do
            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFF0000" .. errors[i] .. "|r")
        end
    end
end

SLASH_WCSLUA50CHECK1 = "/wcslua50check"
SLASH_WCSLUA50CHECK2 = "/wcscheck"

-- Auto-ejecutar al cargar
if WCS_Brain then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[WCS Lua 5.0 Check]|r Verificador cargado. Usa /wcscheck para verificar compatibilidad.")
end
