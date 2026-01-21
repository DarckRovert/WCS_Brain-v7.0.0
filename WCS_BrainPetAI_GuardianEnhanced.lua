--[[
    WCS_BrainPetAI_GuardianEnhanced.lua
    Mejoras para el Modo Guardián
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    Version: 1.1.0
    
    Este archivo mejora el modo guardián para que la mascota proteja mejor a los aliados.
    También integra el modo guardián con el sistema de coordinación.
    
    CHANGELOG v1.1.0:
    - Agregado soporte para Felguard (Anguish, Cleave)
    - Agregado soporte para Succubus (Seduction para CC)
    - Agregado soporte para Felhunter (Spell Lock, Devour Magic)
    - Agregado soporte para Imp (Fire Shield automático)
    - Todas las mascotas ahora tienen habilidades específicas en modo Guardián
]]--

if not WCS_BrainPetAI then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Guardian Enhanced]|r ERROR: WCS_BrainPetAI no encontrado")
    return
end

local PetAI = WCS_BrainPetAI

-- ============================================================================
-- VARIABLES DE MODO GUARDIÁN
-- ============================================================================

PetAI.Guardian = PetAI.Guardian or {}
PetAI.Guardian.lastHP = 0
PetAI.Guardian.hpDropTime = 0
PetAI.Guardian.isUnderAttack = false

-- ============================================================================
-- FUNCIONES MEJORADAS DE MODO GUARDIÁN
-- ============================================================================

-- Guardar la función original GuardianDefend
PetAI.GuardianDefend_Original = PetAI.GuardianDefend

-- Nueva función mejorada GuardianDefend
function PetAI:GuardianDefend(guardianUnit)
    if not guardianUnit then return false end
    
    local guardianHP = self:GetUnitHealthPercent(guardianUnit)
    local isInCombat = UnitAffectingCombat(guardianUnit)
    
    -- INTEGRACIÓN CON COMBATCACHE: Actualizar estado del aliado
    local now = GetTime()
    
    -- Usar CombatCache si está disponible
    if WCS_BrainCombatCache and WCS_BrainCombatCache.UpdateGuardianAlly then
        WCS_BrainCombatCache:UpdateGuardianAlly(guardianUnit)
        
        -- Obtener estado del cache
        local allyStatus = WCS_BrainCombatCache:GetGuardianAllyStatus(guardianUnit)
        if allyStatus then
            self.Guardian.isUnderAttack = allyStatus.isUnderAttack or allyStatus.isLosingHealthFast
            self.Guardian.dpsReceived = allyStatus.dpsReceived
            self.Guardian.hasActiveAttackers = allyStatus.hasActiveAttackers
        end
    else
        -- Fallback: Detección manual si CombatCache no está disponible
        local lastHP = self.Guardian.lastHP or guardianHP
        
        if lastHP > guardianHP and (lastHP - guardianHP) > 0.5 then
            self.Guardian.hpDropTime = now
            self.Guardian.isUnderAttack = true
        end
        
        -- Resetear flag si han pasado 3 segundos sin recibir daño
        if self.Guardian.hpDropTime and (now - self.Guardian.hpDropTime) > 3 then
            self.Guardian.isUnderAttack = false
        end
    end
    
    -- Actualizar HP para próxima comparación
    self.Guardian.lastHP = guardianHP
    
    -- Defender si:
    -- 1. El aliado está en peligro (< 50% HP)
    -- 2. El aliado está en combate
    -- 3. El aliado está siendo atacado (HP bajando)
    if guardianHP < 50 or isInCombat or self.Guardian.isUnderAttack then
        local guardianTarget = guardianUnit .. "target"
        local attackerFound = false
        local attackerUnit = nil
        
        -- PRIORIDAD 1: Usar CombatCache para obtener atacantes conocidos
        if WCS_BrainCombatCache and WCS_BrainCombatCache.Attackers then
            local attackers = WCS_BrainCombatCache.Attackers:GetAttackers(guardianUnit)
            if attackers and table.getn(attackers) > 0 then
                local attackerName = attackers[1]  -- Tomar el primer atacante
                -- Intentar targetear por nombre
                TargetByName(attackerName)
                if UnitExists("target") and UnitName("target") == attackerName then
                    attackerUnit = "target"
                    attackerFound = true
                    self:DebugPrint("[Guardián] Atacante encontrado en cache: " .. attackerName)
                end
            end
        end
        
        -- PRIORIDAD 2: Buscar quién está atacando al aliado (método manual)
        -- Verificar primero el target del aliado protegido
        if not attackerFound and UnitExists(guardianTarget) and UnitCanAttack("player", guardianTarget) then
            -- Verificar si el target del aliado está atacando al aliado
            local guardianTargetTarget = guardianTarget .. "target"
            if UnitExists(guardianTargetTarget) and UnitIsUnit(guardianTargetTarget, guardianUnit) then
                -- El target del aliado está atacando al aliado
                attackerUnit = guardianTarget
                attackerFound = true
                self:DebugPrint("[Guardián] Encontrado atacante: target del aliado")
            end
        end
        
        -- Si no encontramos atacante, buscar en el target del jugador
        if not attackerFound and UnitExists("target") and UnitCanAttack("player", "target") then
            local playerTargetTarget = "targettarget"
            if UnitExists(playerTargetTarget) and UnitIsUnit(playerTargetTarget, guardianUnit) then
                attackerUnit = "target"
                attackerFound = true
                self:DebugPrint("[Guardián] Encontrado atacante: target del jugador")
            end
        end
        
        -- Si aún no encontramos, buscar en party/raid
        if not attackerFound and (self.Guardian.isUnderAttack or guardianHP < 50) then
            if GetNumRaidMembers() > 0 then
                for i = 1, 40 do
                    local raidMember = "raid" .. i
                    if UnitExists(raidMember) and not UnitIsUnit(raidMember, "player") then
                        local raidTarget = raidMember .. "target"
                        if UnitExists(raidTarget) and UnitCanAttack("player", raidTarget) then
                            local raidTargetTarget = raidTarget .. "target"
                            if UnitExists(raidTargetTarget) and UnitIsUnit(raidTargetTarget, guardianUnit) then
                                attackerUnit = raidTarget
                                attackerFound = true
                                self:DebugPrint("[Guardián] Encontrado atacante: target de " .. UnitName(raidMember))
                                break
                            end
                        end
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, 4 do
                    local partyMember = "party" .. i
                    if UnitExists(partyMember) then
                        local partyTarget = partyMember .. "target"
                        if UnitExists(partyTarget) and UnitCanAttack("player", partyTarget) then
                            local partyTargetTarget = partyTarget .. "target"
                            if UnitExists(partyTargetTarget) and UnitIsUnit(partyTargetTarget, guardianUnit) then
                                attackerUnit = partyTarget
                                attackerFound = true
                                self:DebugPrint("[Guardián] Encontrado atacante: target de " .. UnitName(partyMember))
                                break
                            end
                        end
                    end
                end
            end
        end
        
        -- PRIORIDAD 2: Si encontramos al atacante, atacarlo Y usar taunt si es Voidwalker
        if attackerFound and attackerUnit then
            -- Cambiar target de la pet al atacante
            if not UnitExists("pettarget") or not UnitIsUnit("pettarget", attackerUnit) then
                TargetUnit(attackerUnit)
                PetAttack()
                self:Print("[Guardián] ¡ATACANDO AL AGRESOR de " .. self.GuardianTarget .. "!")
            end
            
            -- Usar habilidades de taunt/aggro según el tipo de mascota
            local petType = self:GetPetType()
            
            -- VOIDWALKER: Torment y Suffering
            if petType == "Voidwalker" then
                if not self:IsOnCooldown("Torment") then
                    self:SetCooldown("Torment", 5)
                    if self:ExecuteAbility("Torment") then
                        self:Print("|cFFFF6600[Guardián] Torment!|r Quitando aggro de " .. self.GuardianTarget)
                    end
                end
                
                -- Si el aliado está en peligro crítico, usar Suffering
                if guardianHP < 30 and not self:IsOnCooldown("Suffering") then
                    self:SetCooldown("Suffering", 120)
                    if self:ExecuteAbility("Suffering") then
                        self:Print("|cFFFF0000[Guardián] SUFFERING!|r Emergencia - quitando TODO el aggro")
                    end
                end
            
            -- FELGUARD: Anguish (taunt AoE)
            elseif petType == "Felguard" then
                if not self:IsOnCooldown("Anguish") then
                    self:SetCooldown("Anguish", 40)
                    if self:ExecuteAbility("Anguish") then
                        self:Print("|cFF8B0000[Guardián] Anguish!|r Taunt AoE - protegiendo a " .. self.GuardianTarget)
                    end
                end
                
                -- Cleave para generar más amenaza
                if guardianHP < 50 and not self:IsOnCooldown("Cleave") then
                    self:SetCooldown("Cleave", 6)
                    if self:ExecuteAbility("Cleave") then
                        self:DebugPrint("[Guardián] Cleave - generando amenaza")
                    end
                end
            
            -- SUCCUBUS: Seduction para CC al atacante
            elseif petType == "Succubus" then
                if guardianHP < 40 and not self:IsOnCooldown("Seduction") then
                    self:SetCooldown("Seduction", 18)
                    if self:ExecuteAbility("Seduction") then
                        self:Print("|cFFFF69B4[Guardián] Seduction!|r CC al atacante de " .. self.GuardianTarget)
                    end
                end
            
            -- FELHUNTER: Spell Lock para interrumpir
            elseif petType == "Felhunter" then
                -- Verificar si el atacante está casteando
                if UnitExists("pettarget") and self:IsEnemyCasting("pettarget") then
                    if not self:IsOnCooldown("Spell Lock") then
                        self:SetCooldown("Spell Lock", 24)
                        if self:ExecuteAbility("Spell Lock") then
                            self:Print("|cFF00FFFF[Guardián] Spell Lock!|r Interrumpiendo atacante de " .. self.GuardianTarget)
                        end
                    end
                end
                
                -- Devour Magic para quitar buffs del atacante
                if guardianHP < 60 and not self:IsOnCooldown("Devour Magic") then
                    if self:EnemyHasMagicBuff("pettarget") then
                        self:SetCooldown("Devour Magic", 8)
                        if self:ExecuteAbility("Devour Magic") then
                            self:DebugPrint("[Guardián] Devour Magic - quitando buff del atacante")
                        end
                    end
                end
            
            -- IMP: Fire Shield al aliado
            elseif petType == "Imp" then
                if not self:HasFireShield(guardianUnit) then
                    if not self:IsOnCooldown("Fire Shield") then
                        self:SetCooldown("Fire Shield", 4)
                        -- Guardar target actual
                        local oldTarget = nil
                        if UnitExists("target") then
                            oldTarget = UnitName("target")
                        end
                        
                        -- Targetear al aliado y aplicar Fire Shield
                        TargetUnit(guardianUnit)
                        if self:ExecuteAbility("Fire Shield") then
                            self:Print("|cFFFFD700[Guardián] Fire Shield!|r Protegiendo a " .. self.GuardianTarget)
                        end
                        
                        -- Restaurar target
                        if oldTarget then
                            TargetByName(oldTarget)
                        else
                            ClearTarget()
                        end
                    end
                end
            end
            
            return true
        end
        
        -- PRIORIDAD 3: Si el aliado tiene un target hostil, atacarlo (fallback)
        if UnitExists(guardianTarget) and UnitCanAttack("player", guardianTarget) then
            if not UnitExists("pettarget") or not UnitIsUnit("pettarget", guardianTarget) then
                AssistUnit(guardianUnit)
                PetAttack()
                
                if guardianHP < 50 then
                    self:DebugPrint("[Guardián] ¡DEFENDIENDO! " .. self.GuardianTarget .. " en peligro (HP: " .. string.format("%.0f", guardianHP) .. "%)")
                elseif self.Guardian.isUnderAttack then
                    self:DebugPrint("[Guardián] ¡PROTEGIENDO! " .. self.GuardianTarget .. " está siendo atacado")
                else
                    self:DebugPrint("[Guardián] Asistiendo a " .. self.GuardianTarget .. " en combate")
                end
                
                return true
            end
        end
    end
    
    return false
end

-- ============================================================================
-- PROTECCIÓN CONTRA SUICIDIO EN MODO GUARDIÁN
-- ============================================================================
-- (Esta sección se movió más abajo para evitar duplicación)

-- ============================================================================
-- INTEGRACIÓN CON SISTEMA DE COORDINACIÓN
-- ============================================================================

-- Verificar que las funciones existan antes de sobrescribirlas
if PetAI.GetAggressivenessModifier then
    -- Guardar la función original
    PetAI.GetAggressivenessModifier_Original = PetAI.GetAggressivenessModifier
    
    -- Nueva función que considera el modo guardián
    function PetAI:GetAggressivenessModifier()
        -- Obtener el modificador base del sistema de coordinación
        local modifier = 1.0
        if self.GetAggressivenessModifier_Original then
            modifier = self:GetAggressivenessModifier_Original()
        end
        
        -- Si estamos en modo guardián, ajustar según el estado del aliado
        if self.currentMode == 4 and self.GuardianTarget then
            local guardianUnit = self:FindGuardianUnit()
            if guardianUnit and UnitExists(guardianUnit) and not UnitIsDead(guardianUnit) then
                local guardianHP = self:GetUnitHealthPercent(guardianUnit)
                
                -- Si el aliado está en peligro, ser más defensivo
                if guardianHP < 30 then
                    modifier = modifier * 0.5  -- Muy defensivo
                elseif guardianHP < 50 then
                    modifier = modifier * 0.7  -- Defensivo
                elseif guardianHP > 80 then
                    modifier = modifier * 1.3  -- Puede ser más agresivo
                end
                
                -- Si el aliado está siendo atacado, priorizar defensa
                if self.Guardian.isUnderAttack then
                    modifier = modifier * 0.6
                end
            end
        end
        
        -- Limitar el rango del modificador
        if modifier < 0.2 then modifier = 0.2 end
        if modifier > 2.5 then modifier = 2.5 end
        
        return modifier
    end
end

if PetAI.ShouldPrioritizeDefense then
    -- Guardar la función original
    PetAI.ShouldPrioritizeDefense_Original = PetAI.ShouldPrioritizeDefense
    
    -- Nueva función que considera el modo guardián
    function PetAI:ShouldPrioritizeDefense()
        -- Verificar prioridades del jugador primero
        if self.ShouldPrioritizeDefense_Original then
            if self:ShouldPrioritizeDefense_Original() then
                return true
            end
        end
        
        -- Si estamos en modo guardián, verificar el estado del aliado
        if self.currentMode == 4 and self.GuardianTarget then
            local guardianUnit = self:FindGuardianUnit()
            if guardianUnit and UnitExists(guardianUnit) and not UnitIsDead(guardianUnit) then
                local guardianHP = self:GetUnitHealthPercent(guardianUnit)
                
                -- Priorizar defensa si el aliado está en peligro
                if guardianHP < 50 then return true end
                if self.Guardian.isUnderAttack then return true end
            end
        end
        
        return false
    end
end

if PetAI.ShouldPrioritizeAttack then
    -- Guardar la función original
    PetAI.ShouldPrioritizeAttack_Original = PetAI.ShouldPrioritizeAttack
    
    -- Nueva función que considera el modo guardián
    function PetAI:ShouldPrioritizeAttack()
        -- Verificar prioridades del jugador primero
        if self.ShouldPrioritizeAttack_Original then
            if self:ShouldPrioritizeAttack_Original() then
                return true
            end
        end
        
        -- Si estamos en modo guardián, verificar el estado del aliado
        if self.currentMode == 4 and self.GuardianTarget then
            local guardianUnit = self:FindGuardianUnit()
            if guardianUnit and UnitExists(guardianUnit) and not UnitIsDead(guardianUnit) then
                local guardianHP = self:GetUnitHealthPercent(guardianUnit)
                
                -- Priorizar ataque si el aliado está bien de salud
                if guardianHP > 80 and not self.Guardian.isUnderAttack then
                    return true
                end
            end
        end
        
        return false
    end
end

-- ============================================================================
-- SOBRESCRIBIR GuardianSacrifice - SOLO MIRAR VIDA DEL JUGADOR
-- ============================================================================

-- Guardar la función original
PetAI.GuardianSacrifice_Original = PetAI.GuardianSacrifice

-- Nueva función que SOLO mira la vida del JUGADOR para Sacrifice
-- NO la vida del aliado, porque el escudo solo se puede poner al jugador
function PetAI:GuardianSacrifice(guardianUnit)
    if not guardianUnit then return false end
    
    local petType = self:GetPetType()
    if petType ~= "Voidwalker" then return false end
    
    -- IMPORTANTE: Sacrifice SOLO mira la vida del JUGADOR
    -- El escudo solo se puede poner al jugador, no al aliado
    local playerHP = self:GetPlayerHealthPercent()
    
    -- Solo sacrificarse si el JUGADOR está en peligro crítico
    if playerHP < 20 and UnitAffectingCombat("player") then
        -- Verificar que Sacrifice esté disponible
        if not self:IsOnCooldown("Sacrifice") then
            -- El Sacrifice se aplica automáticamente al jugador
            if self:ExecuteAbility("Sacrifice") then
                self:Print("|cFFFF0000[GUARDIÁN]|r ¡Sacrificándose para proteger al JUGADOR (HP: " .. string.format("%.0f", playerHP) .. "%)!")
                self:SetCooldown("Sacrifice", 300)
                return true
            end
        end
    end
    
    return false
end

-- ============================================================================
-- SOBRESCRIBIR EvaluateVoidwalker PARA MODO GUARDIÁN
-- ============================================================================

-- Guardar la función original si existe
if PetAI.EvaluateVoidwalker then
    PetAI.EvaluateVoidwalker_Original = PetAI.EvaluateVoidwalker
else
    -- Si no existe, crear una función vacía como fallback
    PetAI.EvaluateVoidwalker_Original = function() return false end
end

-- Nueva función que considera SOLO la vida del JUGADOR para Sacrifice
function PetAI:EvaluateVoidwalker()
    local playerHP = self:GetPlayerHealthPercent()
    local petHP = self:GetPetHealthPercent()
    local cfg = self.Config
    local inCombat = UnitAffectingCombat("player") or UnitAffectingCombat("pet")
    
    -- EN MODO GUARDIÁN: Sacrifice SOLO mira la vida del JUGADOR
    -- NO la vida del aliado, porque el escudo solo se puede poner al jugador
    if self.currentMode == 4 and self.GuardianTarget then
        -- PRIORIDAD 1: Emergencia del JUGADOR - sacrificio inmediato
        if playerHP < (cfg.emergencyThreshold or 25) and inCombat then
            if not self:ShouldUseDefensive() then
                self:DebugPrint("[Voidwalker Guardian] Modo actual no permite Sacrifice")
                return false
            end
            self:Print("|cffff0000EMERGENCIA DEL JUGADOR!|r Tu HP: " .. string.format("%.0f", playerHP) .. "% - Sacrificando!")
            return self:ExecuteAbility("Sacrifice")
        end
        
        -- PRIORIDAD 2: Sacrificio inteligente - Voidwalker a punto de morir
        -- SOLO si el JUGADOR necesita el escudo (no el aliado)
        if cfg.smartSacrifice then
            local sacrificeThreshold = cfg.voidwalkerSacrificeHP or 15
            
            if petHP < sacrificeThreshold and inCombat then
                -- Verificar que el sacrificio sea útil para el JUGADOR
                if playerHP < 90 then
                    self:Print("|cffff6600SACRIFICIO INTELIGENTE!|r Voidwalker HP: " .. string.format("%.0f", petHP) .. "% - Protegiendo al JUGADOR!")
                    return self:ExecuteAbility("Sacrifice")
                else
                    self:DebugPrint("Voidwalker moribundo pero JUGADOR al " .. string.format("%.0f", playerHP) .. "% - no sacrifico")
                end
            end
        end
        
        -- PRIORIDAD 3: Suffering para quitar aggro del JUGADOR (no del aliado)
        if playerHP < 50 and inCombat then
            if not self:IsOnCooldown("Suffering") then
                if not self:ShouldUseDefensive() then
                    self:DebugPrint("[Voidwalker Guardian] Modo actual no permite Suffering")
                    return false
                end
                self:SetCooldown("Suffering", 120)
                self:Print("|cffFFFF00Suffering!|r Quitando aggro del JUGADOR")
                return self:ExecuteAbility("Suffering")
            end
        end
        
        -- PRIORIDAD 4: Torment para mantener aggro del atacante del aliado
        local guardianUnit = self:FindGuardianUnit()
        if guardianUnit and UnitExists(guardianUnit) and not UnitIsDead(guardianUnit) then
            local guardianHP = self:GetUnitHealthPercent(guardianUnit)
            
            -- Si el aliado está en peligro, usar Torment más agresivamente
            if guardianHP < 70 and inCombat then
                if not self:IsOnCooldown("Torment") then
                    if not self:ShouldUseOffensive() then
                        self:DebugPrint("[Voidwalker Guardian] Modo actual no permite Torment")
                        return false
                    end
                    self:SetCooldown("Torment", 5)
                    return self:ExecuteAbility("Torment")
                end
            end
        end
        
        -- PRIORIDAD 5: Curarse fuera de combate
        if petHP < 50 and not inCombat then
            if not self:IsOnCooldown("Consume Shadows") then
                self:SetCooldown("Consume Shadows", 30)
                self:DebugPrint("Consume Shadows - curando fuera de combate")
                return self:ExecuteAbility("Consume Shadows")
            end
        end
        
        return false
    end
    
    -- Si NO estamos en modo guardián, usar la lógica original
    if self.EvaluateVoidwalker_Original then
        return self:EvaluateVoidwalker_Original()
    end
    return false
end

-- ============================================================================
-- COMANDO /petcoord EXTENDIDO PARA MODO GUARDIÁN
-- ============================================================================

-- Guardar el comando original si existe
if SlashCmdList["PETCOORD"] then
    PetAI.PetCoordCommand_Original = SlashCmdList["PETCOORD"]
end

-- Extender el comando /petcoord
SlashCmdList["PETCOORD"] = function(msg)
    -- Ejecutar el comando original primero
    if PetAI.PetCoordCommand_Original then
        PetAI.PetCoordCommand_Original(msg)
    end
    
    -- Agregar información del modo guardián
    if PetAI.currentMode == 4 and PetAI.GuardianTarget then
        PetAI:Print("")
        PetAI:Print("=== Estado del Modo Guardián ===")
        PetAI:Print("Protegiendo a: " .. PetAI.GuardianTarget)
        
        local guardianUnit = PetAI:FindGuardianUnit()
        if guardianUnit and UnitExists(guardianUnit) and not UnitIsDead(guardianUnit) then
            local guardianHP = PetAI:GetUnitHealthPercent(guardianUnit)
            local isInCombat = UnitAffectingCombat(guardianUnit)
            
            PetAI:Print("HP del aliado: " .. string.format("%.1f", guardianHP) .. "%")
            PetAI:Print("En combate: " .. (isInCombat and "SÍ" or "NO"))
            PetAI:Print("Siendo atacado: " .. (PetAI.Guardian.isUnderAttack and "SÍ" or "NO"))
            
            local guardianTarget = guardianUnit .. "target"
            if UnitExists(guardianTarget) then
                local targetName = UnitName(guardianTarget)
                PetAI:Print("Target del aliado: " .. (targetName or "Desconocido"))
            else
                PetAI:Print("Target del aliado: Ninguno")
            end
        else
            PetAI:Print("|cFFFF0000Aliado no encontrado o muerto|r")
        end
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Guardian Enhanced]|r Modo Guardián mejorado cargado")
DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Guardian Enhanced]|r Usa /petguard [nombre] para asignar aliado a proteger")
