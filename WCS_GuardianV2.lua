-- Guardian V2: Sistema mejorado con rotacion de habilidades
-- Este archivo sobrescribe GuardianDefend con mejor deteccion

if not WCS_BrainPetAI then return end
local PetAI = WCS_BrainPetAI

-- Helper: Restaurar target de forma segura
local function SafeRestoreTarget(targetName)
    pcall(function()
        if targetName then
            TargetByName(targetName)
        else
            ClearTarget()
        end
    end)
end


-- Guardar original
PetAI.GuardianDefend_Original = PetAI.GuardianDefend

-- Nueva version mejorada
function PetAI:GuardianDefend(guardianUnit)
    if not guardianUnit then return false end
    
    local guardianHP = self:GetUnitHealthPercent(guardianUnit)
    local isInCombat = UnitAffectingCombat(guardianUnit)
    
    -- Actualizar estado
    if WCS_BrainCombatCache and WCS_BrainCombatCache.UpdateGuardianAlly then
        WCS_BrainCombatCache:UpdateGuardianAlly(guardianUnit)
    end
    
    -- POSICIONAR CERCA DEL ALIADO: La pet debe estar cerca del guardian
    -- En WoW 1.12, PetFollow() solo sigue al jugador, no a otras unidades
    -- Solucion: hacer que la pet ataque al target del aliado (si existe)
    -- o se mantenga en modo defensivo cerca de el
    if not isInCombat then
        -- Si el aliado tiene un target enemigo, posicionar la pet ahi
        local guardianTarget = guardianUnit .. "target"
        if UnitExists(guardianTarget) and UnitCanAttack("player", guardianTarget) and not UnitIsDead(guardianTarget) then
            -- Posicionar cerca del enemigo del aliado (modo preventivo)
            if not UnitIsUnit("pettarget", guardianTarget) then
                -- NO cambiar el target del jugador, solo atacar con la pet
                -- Guardar target actual del jugador
                local playerTarget = UnitName("target")
                
                TargetByName(UnitName(guardianTarget))
                if UnitExists("target") and not UnitIsDead("target") then
                    PetAttack()
                    self:DebugPrint("[Guardian] Posicionando cerca del target de " .. UnitName(guardianUnit))
                end
                
                -- Restaurar target del jugador (protegido)
                SafeRestoreTarget(playerTarget)
            end
        end
    end
    
    -- Defender si necesario
    if guardianHP < 50 or isInCombat then
        local attackerName = nil
        
        -- PRIORIDAD 1: CombatLog (mas preciso)
        if self.GuardianCombatLog and self.GuardianCombatLog.enabled then
            attackerName = self.GuardianCombatLog:GetMostDangerous()
        end
        
        -- PRIORIDAD 2: Target del aliado
        if not attackerName then
            local guardianTarget = guardianUnit .. "target"
            if UnitExists(guardianTarget) and UnitCanAttack("player", guardianTarget) and not UnitIsDead(guardianTarget) then
                attackerName = UnitName(guardianTarget)
            end
        end
        
        -- Si encontramos atacante
        if attackerName then
            -- Guardar target del jugador
            local playerTarget = UnitName("target")
            
            TargetByName(attackerName)
            if UnitExists("target") and UnitName("target") == attackerName and not UnitIsDead("target") then
                PetAttack()
                
                -- Usar habilidades segun mascota
                local petType = self:GetPetType()
                
                if petType == "Voidwalker" then
                    if not self:IsOnCooldown("Torment") then
                        self:SetCooldown("Torment", 5)
                        self:ExecuteAbility("Torment")
                    elseif guardianHP < 30 and not self:IsOnCooldown("Suffering") then
                        self:SetCooldown("Suffering", 120)
                        self:ExecuteAbility("Suffering")
                    end
                elseif petType == "Felguard" then
                    if not self:IsOnCooldown("Anguish") then
                        self:SetCooldown("Anguish", 40)
                        self:ExecuteAbility("Anguish")
                    end
                end
                
                -- Restaurar target del jugador (protegido)
                SafeRestoreTarget(playerTarget)
                
                return true
            end
        end
    end
    
    return false
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Guardian V2]|r Sistema mejorado cargado")
