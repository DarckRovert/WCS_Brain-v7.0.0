--[[
    WCS_BossManager.lua - Tactical Raid Auditor v9.3.0 (Unified)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.BossManager = WCS.BossManager or {}
local BM = WCS.BossManager

function BM:OnCombatStart(bossName)
    WCS:Log("Encuentro Detectado: " .. bossName)
    if WCS.AutoCapture then WCS.AutoCapture:Capture("Boss: " .. bossName) end
end

-- [Event Hooks via Central EM]
if WCS.EventManager then
    WCS.EventManager:Register("PLAYER_REGEN_DISABLED", function()
        if UnitExists("target") and (UnitClassification("target") == "worldboss" or UnitClassification("target") == "elite") then
            BM:OnCombatStart(UnitName("target"))
        end
    end)
end

WCS:Log("Boss Manager v9.3.0 (Combat-Sensing) Ready.")
