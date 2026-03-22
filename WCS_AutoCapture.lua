--[[
    WCS_AutoCapture.lua - Autonomous Journalist v8.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.AutoCapture = WCS.AutoCapture or {}
local AC = WCS.AutoCapture

function AC:Capture(reason)
    WCS:Log("Captura Automática: " .. (reason or "Evento Crítico"))
    if Screenshot then Screenshot() end
end

WCS:Log("Auto-Capture v8.0.0 [Active]")
