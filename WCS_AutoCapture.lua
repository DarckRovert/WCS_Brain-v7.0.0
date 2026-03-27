--[[
    WCS_AutoCapture.lua - Autonomous Journalist v9.3.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.AutoCapture = WCS.AutoCapture or {}
local AC = WCS.AutoCapture

function AC:Capture(reason)
    WCS:Log("Captura AutomÃ¡tica: " .. (reason or "Evento CrÃ­tico"))
    if Screenshot then Screenshot() end
end

WCS:Log("Auto-Capture v9.3.0 [Active]")
