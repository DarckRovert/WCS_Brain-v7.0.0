--[[
    WCS_DecisionEngine.lua - Elite Tactical Engine v9.3.0 (Multi-Class)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Resuelve la mejor accion en base a la clase detectada por WCS.ClassEngine.
    Funcionalidad REAL â€” Sin ficcion.
]]--

WCS = WCS or {}
WCS.DecisionEngine = WCS.DecisionEngine or {}
local DE = WCS.DecisionEngine

-- Local helpers to resolve class data safely
local function getClassFiller()
    if WCS.ClassEngine and WCS.ClassEngine.GetFiller then
        return WCS.ClassEngine:GetFiller()
    end
    return "Shadow Bolt" -- Warlock fallback
end

local function getClassRotation()
    if WCS.ClassEngine and WCS.ClassEngine.GetRotation then
        return WCS.ClassEngine:GetRotation()
    end
    if WCS.Grimoire and WCS.Grimoire.GetBestRotation then
        return WCS.Grimoire:GetBestRotation()
    end
    return { "Shadow Bolt" }
end

local function getClassDefensive()
    if WCS.ClassEngine and WCS.ClassEngine.GetDefensive then
        return WCS.ClassEngine:GetDefensive()
    end
    return "Death Coil"
end

local function getProcTrigger()
    if WCS.ClassEngine and WCS.ClassEngine.GetProcTrigger then
        return WCS.ClassEngine:GetProcTrigger()
    end
    return "Shadow Trance" -- Warlock Nightfall fallback
end

local function getProcAction()
    if WCS.ClassEngine and WCS.ClassEngine.GetProcAction then
        return WCS.ClassEngine:GetProcAction()
    end
    return "Shadow Bolt"
end

function DE:GetBestAction()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return nil end

    -- [1] Deep State Sync
    local hp       = UnitHealthMax("player") > 0 and (UnitHealth("player") / UnitHealthMax("player")) * 100 or 100
    local isMoving = WCS.Core and WCS.Core.IsMoving
    local isCasting = WCS.Core and WCS.Core.IsCasting

    if isCasting then return nil end

    -- [2] Survival Protocol (Defensive cooldown when critically low)
    if hp < 30 then
        local defensive = getClassDefensive()
        if defensive and WCS.SpellManager and WCS.SpellManager.IsReady then
            if WCS.SpellManager:IsReady(defensive) then
                WCS:Notify("|cffff0000[EMERGENCIA]|r Usando " .. defensive)
                return { spell = defensive, reason = "Survival < 30%HP" }
            end
        end
        -- Last resort: healthstone for Warlocks
        if WCS.DataManager and WCS.DataManager.HasHealthstone and WCS.DataManager:HasHealthstone() then
            WCS:Notify("|cffff0000[EMERGENCIA]|r Usando Piedra de Salud")
            return { spell = "Healthstone", reason = "Survival" }
        end
    end

    -- [3] Proc Awareness â€” check class proc trigger
    local procTrigger = getProcTrigger()
    if procTrigger and WCS.Core and WCS.Core.HasBuff and WCS.Core:HasBuff(procTrigger) then
        local procAction = getProcAction()
        WCS:Notify("|cff00ffff[PROC: " .. procTrigger .. "]|r " .. procAction .. " Instantaneo")
        return { spell = procAction, reason = "PROC: " .. procTrigger }
    end

    -- [4] Priority Rotation â€” class-aware
    local rotation = getClassRotation()
    local filler   = getClassFiller()

    -- Check if WCS.Core methods exist before calling
    if WCS.Core and WCS.Core.TargetHasDebuff then
        for _, spell in ipairs(rotation) do
            if spell ~= filler then
                -- DoT/debuff: only apply if not already on target
                if not WCS.Core:TargetHasDebuff(spell) then
                    if not isMoving then
                        return { spell = spell, reason = "Rotation: Priority" }
                    end
                end
            end
        end
    end

    -- [5] Movement Filler â€” use instant spell if moving
    if isMoving then
        -- Try Corruption (Warlock, instant with talent) or class-specific instant
        if WCS.ClassEngine and WCS.ClassEngine.class == "WARLOCK" then
            if WCS.Helpers and WCS.Helpers.HasImprovedCorruption and WCS.Helpers:HasImprovedCorruption() then
                return { spell = "Corruption", reason = "Moving: Instant" }
            end
        end
        return nil -- Don't waste globals casting while moving
    end

    -- [6] Filler
    return { spell = filler, reason = "Filler" }
end

WCS:Log("Decision Engine v9.3.0 [Multi-Class] â€” ClassEngine Aligned.")
