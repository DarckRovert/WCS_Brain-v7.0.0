--[[
    WCS_SavedVarsValidator.lua - Data Integrity Auditor v8.0.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.Validator = WCS.Validator or {}

function WCS.Validator:Audit()
    WCS_BrainSaved = WCS_BrainSaved or {}
    
    -- [1] Central Config (Persistence for UI Controls)
    WCS_BrainSaved.Config = WCS_BrainSaved.Config or {}
    local C = WCS_BrainSaved.Config
    if C.AutoExecute == nil then C.AutoExecute = false end
    if C.PetManager == nil then C.PetManager = true end
    if C.TacticsScale == nil then C.TacticsScale = 1.0 end
    if C.Notifications == nil then C.Notifications = true end
    
    -- [2] HUD Persistence
    WCS_BrainSaved.HUD = WCS_BrainSaved.HUD or { x = 0, y = -120, scale = 1.0, locked = true, alpha = 0.8 }
    
    -- [3] Stats & Achievements
    WCS_BrainSaved.Stats = WCS_BrainSaved.Stats or { Kills = 0, Deaths = 0, ShardsUsed = 0 }
    WCS_BrainSaved.Log = WCS_BrainSaved.Log or {}
    WCS_BrainSaved.Achievements = WCS_BrainSaved.Achievements or {}
    
    WCS:Log("SavedVars Audit: OK (UI v8.0 READY)")
    WCS_BrainSaved.Version = "8.0.0"
end

WCS:Log("SavedVars Auditor Aligned for Persistence.")
