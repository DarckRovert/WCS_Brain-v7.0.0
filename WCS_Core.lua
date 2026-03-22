--[[
    WCS_Core.lua - Unified Heartbeat v8.0.0 (God-Tier Alignment)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.Core = WCS.Core or {}
local Core = WCS.Core

Core.IsMoving = false
Core.IsCasting = false
Core.LastPos = {x=0, y=0}

function Core:Init()
    if not WCS.EventManager then return end
    
    -- [1] Centralized Event Hooking
    WCS.EventManager:Register("SPELLCAST_START", function() self.IsCasting = true end)
    WCS.EventManager:Register("SPELLCAST_STOP", function() self.IsCasting = false end)
    WCS.EventManager:Register("SPELLCAST_FAILED", function() self.IsCasting = false end)
    WCS.EventManager:Register("SPELLCAST_INTERRUPTED", function() self.IsCasting = false end)
    WCS.EventManager:Register("PLAYER_TARGET_CHANGED", function() self:AuditTarget() end)
    
    -- [2] Shared Heartbeat Frame
    self.Tick = CreateFrame("Frame")
    self.Tick:SetScript("OnUpdate", function() self:OnHeartbeat() end)
    
    WCS:Log("Core Heartbeat v8.0.0 [Active]")
end

function Core:OnHeartbeat()
    -- Movement Detection
    local x, y = GetPlayerMapPosition("player")
    self.IsMoving = (x ~= self.LastPos.x or y ~= self.LastPos.y)
    self.LastPos.x, self.LastPos.y = x, y
    
    -- Broadcast Tick to Subsystems (Eliminating redundant frames)
    if WCS.PetManager then WCS.PetManager:OnUpdate() end
    if WCS.BrainAutoExecute then WCS.BrainAutoExecute:OnUpdate() end
    if WCS.TacticalHUD then WCS.TacticalHUD:Update() end
end

function Core:AuditTarget()
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local level = UnitLevel("target")
        if level > (UnitLevel("player") + 5) then
            WCS:Notify("|cffff0000!! GANK WARNING !!|r [" .. UnitName("target") .. "] Lvl " .. level)
        end
    end
end

-- Shared Utility
function Core:IsMounted()
    for i = 1, 32 do
        local tex = GetPlayerBuffTexture(i)
        if not tex then break end
        if string.find(tex, "Mount") or string.find(tex, "Spell_Nature_Swiftness") then return true end
    end
    return false
end

function Core:Dismount() if self:IsMounted() then Dismount() return true end return false end

function Core:HasBuff(name)
    for i = 1, 32 do
        local b = GetPlayerBuffTexture(i)
        if not b then break end
        if string.find(b, name) then return true end
    end
    return false
end

function Core:TargetHasDebuff(name)
    for i = 1, 16 do
        local d = UnitDebuff("target", i)
        if not d then break end
        if string.find(d, name) then return true end
    end
    return false
end

WCS:Log("Core Infrastructure v8.0.0 [Aligned]")
