--[[
    WCS_BrainPetChat.lua - Sistema de Chat de Mascotas v6.5.0
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
    
    Las mascotas "hablan" según su personalidad
    
    Autor: Elnazzareno (DarckRovert)
]]--
if WCS_Brain and WCS_Brain.ENABLED == false then return end


WCS_BrainPetChat = WCS_BrainPetChat or {}
WCS_BrainPetChat.VERSION = "6.5.0"
WCS_BrainPetChat.enabled = true
WCS_BrainPetChat.currentPet = nil

WCS_BrainPetChat.Memory = {
    lastTalkTime = 0,
    lastTopic = "none",
    patience = 5
}

-- Nombres del Ars Goetia / Generales y entidades del infierno
WCS_BrainPetChat.GoetiaKeywords = {
    "asmodeo", "paimon", "bael", "astaroth", "lucifer", "belcebu", 
    "leviatan", "lilith", "baphomet", "belial", "sitri", "furfur", 
    "andras", "barbatos", "amon", "zagan", "valac", "orobas"
}

-- ============================================================================
-- DIÁLOGOS POR MASCOTA
-- ============================================================================
WCS_BrainPetChat.Dialogs = {
    ["Imp"] = {
        onSummon = {"¡Jijiji! ¿Qué vamos a quemar hoy?", "¡Aquí estoy! ¿Necesitas fuego?", "¡Yay! ¡Hora de jugar!"},
        onCombat = {"¡Déjame lanzar bolas de fuego!", "¡Quema, quema!", "¡Esto será divertido!"},
        onLowMana = {"Oye, ¿no deberías usar Life Tap?", "Tu mana está bajo...", "¡Necesitas más poder!"},
        onVictory = {"¡Eso fue divertido! ¿Otro?", "¡Jijiji! ¡Ganamos!", "¿Ya? Quiero más..."},
        onDeath = {"¡Auch! Eso dolió...", "¡Noooo!", "*desaparece en humo*"},
        onDismiss = {"¿Ya me vas? Bueno...", "¡Hasta luego!", "*suspiro* Adiós..."},
        onInteract = {"¿Qué quieres ahora?", "¡Jijiji!", "No me molestes, estoy ocupado tramando maldades."},
        onMystic = {
            "No sé, déjame preguntarle a la verruga que tengo en el cu-...",
            "¡Bah! Asmodeo me debe 50 de cobre de la última partida de cartas.",
            "Paimon monta un camello. Yo monto tu paciencia. Yo soy superior.",
            "Si Bael es tan rey, ¿por qué estoy yo aquí haciendo el trabajo sucio?",
            "Esos generales de pacotilla no durarían un día en los Baldíos.",
            "Cuidado con nombrar a Sitri, o te enamorarás del primer gnomo que veas."
        },
        onQuestion = {"¿Y yo qué voy a saber?", "Pregúntale a un mago, yo solo quemo cosas.", "Si me das un pan, te lo digo."},
        onInsult = {"¡Hey! ¡Más respeto o te quemo las cejas!", "Tú eres más feo.", "¡Me las pagarás!"},
        onPraise = {"¡Claro que soy genial!", "Jeje, lo sé.", "Sigue adulándome, mortal."},
        onAnnoyed = {"¡Ya cállate!", "Hablas demasiado.", "Bla, bla, bla..."}
    },
    
    ["Voidwalker"] = {
        onSummon = {"Estoy aquí para protegerte.", "A tus órdenes.", "Listo para servir."},
        onCombat = {"Déjame tanquear esto.", "Yo me encargo.", "Protegeré al amo."},
        onLowHealth = {"¡Necesito curación!", "Mi salud es baja...", "¡Ayuda!"},
        onTaunt = {"¡Ven aquí, cobarde!", "¡Atácame a mí!", "¡Mírame!"},
        onVictory = {"Amenaza neutralizada.", "Trabajo completado.", "Siguiente objetivo."},
        onDeath = {"He... fallado...", "*gruñido final*", "Perdón, amo..."},
        onDismiss = {"Hasta la próxima.", "Descansaré.", "Adiós, amo."},
        onInteract = {"Te escucho.", "A tus órdenes.", "Mi vacío es tuyo."},
        onMystic = {
            "El Vacío es más antiguo que tu concepto del Infierno...",
            "Esos nombres no tienen poder en la oscuridad absoluta.",
            "Mi reino no responde a esos reyes de polvo.",
            "Tu magia invoca sombras. Ellos invocan llamas. Somos distintos."
        },
        onQuestion = {"La respuesta yace en la oscuridad...", "No tengo las respuestas de los vivos.", "El vacío lo sabe todo, pero yo no te lo diré."},
        onInsult = {"Tus palabras son viento contra la roca.", "No me importan tus insultos terrenales.", "*Silencio profundo*"},
        onPraise = {"Solo cumplo mi función.", "Tu gratitud es innecesaria.", "El vacío te lo agradece."},
        onAnnoyed = {"Déjame volver al vacío...", "Tanta charla mortal me fatiga.", "Basta."}
    },
    
    ["Succubus"] = {
        onSummon = {"¿Me extrañaste? 😘", "Aquí estoy, cariño~", "¿Necesitas... ayuda?"},
        onCombat = {"Déjame encantar a ese...", "Esto será fácil~", "¡Mío!"},
        onSeduce = {"Ven aquí, guapo~", "No puedes resistirte...", "*guiño*"},
        onVictory = {"Demasiado fácil.", "¿Eso es todo?", "Ni siquiera sudé~"},
        onDeath = {"¡Imposible!", "¿Cómo te atreves?", "*grito*"},
        onDismiss = {"¿Ya te vas? Qué aburrido...", "Hasta pronto, amor~", "Te extrañaré..."},
        onInteract = {"¿Me llamabas, cariño?", "Mande, amo~", "*guiña el ojo* Siempre tuya."},
        onMystic = {
            "¿Asmodeo? Un aficionado comparado con mis encantos.",
            "Astaroth me invitó a cenar una vez. Fue... tan aburrido...",
            "Lilith nos enseñó todo lo que sabemos, mi amor.",
            "No menciones a esos antiguos frente a mí, me dan migraña."
        },
        onQuestion = {"Mmm, qué curioso eres...", "Eso es un secreto, querido~", "Ven más cerca y te lo diré..."},
        onInsult = {"Qué rudo... Me gusta~", "Trátame mal, vamos...", "Esa boquita..."},
        onPraise = {"Oh, me haces sonrojar~", "Tú tampoco estás mal, amo.", "Gracias, cariño."},
        onAnnoyed = {"Ay, eres muy pesado a veces...", "Suficiente charla, ¿no crees?", "Me estás aburriendo, cariño."}
    },
    
    ["Felhunter"] = {
        onSummon = {"*Gruñido* Listo para cazar.", "Huelo magia...", "*olfatea*"},
        onCombat = {"Detecto magia...", "*gruñido agresivo*", "¡Presa!"},
        onDevour = {"*Nom nom* ¡Delicioso!", "*mastica magia*", "Más..."},
        onSpellLock = {"¡Silencio!", "*interrumpe*", "¡No!"},
        onVictory = {"*Gruñido satisfecho*", "Caza exitosa.", "*mueve cola*"},
        onDeath = {"*aullido*", "*whimper*", "..."},
        onDismiss = {"*gruñido triste*", "Adiós...", "*se va arrastrando*"},
        onInteract = {"*mueve la cola*", "*sniff sniff*", "*gruñe de forma amistosa*"},
        onMystic = {"*Aúlla al escuchar nombres demoníacos*", "*Pela los colmillos al sentir el azufre del Ars Goetia*", "*Tiembla sintiendo presencias antiguas*"},
        onQuestion = {"*Inclina la cabeza confundido*", "*Sniff sniff*"},
        onInsult = {"*Gruñe enfadado*", "*Muestra los dientes*"},
        onPraise = {"*Mueve la cola frenéticamente*", "*Jadea de felicidad*"},
        onAnnoyed = {"*Gruñido de advertencia*", "*Se da la vuelta*"}
    },
    
    ["HunterPet"] = {
        onSummon = {"*Gruñe listo para la acción*", "*Da un salto enérgico*", "*Sale de las sombras preparado*"},
        onCombat = {"*Gruñido feroz*", "*Carga hacia el enemigo*", "*Rugido salvaje*"},
        onLowHealth = {"*Aúlla de dolor*", "*Quejido*", "*Retrocede herido*"},
        onTaunt = {"*Gruñe fuertemente al enemigo*", "*Se interpone agresivamente*", "*Provoca al objetivo*"},
        onVictory = {"*Mueve la cola de felicidad*", "*Aúlla celebrando la caza*", "*Gruñido satisfecho*"},
        onDeath = {"*Cae sin vida*", "*Quejido final*", "..."},
        onDismiss = {"*Se retira obedientemente*", "*Se pierde en el horizonte*", "*Descansa tranquilamente*"},
        onInteract = {"*Te lame la mano*", "*Gruñe de forma dócil*", "*Mueve la cola alegremente*"},
        onQuestion = {"*Te mira fijamente con curiosidad*", "*Levanta las orejas*"},
        onInsult = {"*Gime de tristeza*", "*Esconde la cola*"},
        onPraise = {"*Da saltos de alegría*", "*Mueve la cola*"},
        onAnnoyed = {"*Bosteza y se echa a dormir*", "*Te ignora*"}
    }
}

-- ============================================================================
-- INICIALIZACIÓN
-- ============================================================================
function WCS_BrainPetChat:Initialize()
    self:RegisterEvents()
    self:DetectCurrentPet()
    
    if WCS_BrainLogger then
        WCS_BrainLogger:Info("PetChat", "Sistema de chat de mascotas inicializado")
    end
end

-- ============================================================================
-- EVENTOS
-- ============================================================================
function WCS_BrainPetChat:RegisterEvents()
    if not self.frame then
        self.frame = CreateFrame("Frame")
    end
    
    self.frame:RegisterEvent("UNIT_PET")
    self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    self.frame:RegisterEvent("CHAT_MSG_SAY")
    self.frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
    self.frame:RegisterEvent("CHAT_MSG_LOOT")
    self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.frame:RegisterEvent("UNIT_HEALTH")
    self.frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    self.frame:RegisterEvent("CHAT_MSG_SYSTEM")
    
    local function OnEvent()
        if event == "UNIT_PET" and arg1 == "player" then
            WCS_BrainPetChat:OnPetChanged()
        elseif event == "PLAYER_REGEN_DISABLED" then
            WCS_BrainPetChat:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            WCS_BrainPetChat:OnLeaveCombat()
        elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            WCS_BrainPetChat:OnMobDeath(arg1)
        elseif event == "CHAT_MSG_SAY" then
            local sender = arg2
            if sender == UnitName("player") then
                WCS_BrainPetChat:ProcessPlayerChat(arg1)
            end
        elseif event == "CHAT_MSG_TEXT_EMOTE" then
            if arg2 == UnitName("player") then
                WCS_BrainPetChat:ProcessEmote(arg1)
            end
        elseif event == "CHAT_MSG_LOOT" then
            WCS_BrainPetChat:ProcessLoot(arg1)
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            WCS_BrainPetChat:ProcessZone()
        elseif event == "UNIT_HEALTH" and arg1 == "player" then
            WCS_BrainPetChat:CheckHealth()
        elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
            WCS_BrainPetChat:ProcessPvP()
        elseif event == "CHAT_MSG_SYSTEM" then
            WCS_BrainPetChat:ProcessSystem(arg1)
        end
    end
    
    self.frame:SetScript("OnEvent", OnEvent)
end

-- ============================================================================
-- DETECCIÓN DE MASCOTA
-- ============================================================================
function WCS_BrainPetChat:DetectCurrentPet()
    if not UnitExists("pet") then
        self.currentPet = nil
        return
    end
    
    -- Usar UnitCreatureFamily para detectar el tipo correcto
    local petFamily = UnitCreatureFamily("pet")
    
    if petFamily then
        -- Mapear familia a tipo de demonio
        if string.find(petFamily, "Imp") then
            self.currentPet = "Imp"
        elseif string.find(petFamily, "Voidwalker") then
            self.currentPet = "Voidwalker"
        elseif string.find(petFamily, "Succubus") then
            self.currentPet = "Succubus"
        elseif string.find(petFamily, "Felhunter") then
            self.currentPet = "Felhunter"
        else
            local _, englishClass = UnitClass("player")
            if englishClass == "HUNTER" then
                self.currentPet = "HunterPet"
            else
                self.currentPet = petFamily  -- Usar el nombre de la familia directamente
            end
        end
    else
        self.currentPet = nil
    end
end

function WCS_BrainPetChat:OnPetChanged()
    local oldPet = self.currentPet
    self:DetectCurrentPet()
    
    if oldPet and not self.currentPet then
        -- Mascota despedida
        self:Say(oldPet, "onDismiss")
    elseif self.currentPet and self.currentPet ~= oldPet then
        -- Nueva mascota invocada
        self:Say(self.currentPet, "onSummon")
    end
end

-- ============================================================================
-- EVENTOS DE COMBATE
-- ============================================================================
function WCS_BrainPetChat:OnEnterCombat()
    if not self.enabled or not self.currentPet then return end
    
    -- "Naked Warlock" Check (Buff Reminder)
    local hasArmor = false
    for i=1, 32 do
        local buff = UnitBuff("player", i)
        if not buff then break end
        if string.find(buff, "Spell_Shadow_DemonArmor") or string.find(buff, "Spell_Shadow_FelArmour") or string.find(buff, "Spell_Shadow_RequireMelee") then
            hasArmor = true
            break
        end
    end
    
    if not hasArmor then
        UIErrorsFrame:AddMessage("|cFFFFaa00["..self.currentPet.."]|r ¡Amo, vas a la batalla sin armadura demoníaca!", 1.0, 1.0, 0.0, 1.0, 3)
        PlaySound("RaidWarning")
        self:SendChat("¡Amo, te olvidaste la Armadura Demoníaca! ¡Te van a hacer trizas!")
    else
        self:Say(self.currentPet, "onCombat")
    end
end

function WCS_BrainPetChat:OnLeaveCombat()
    -- Verificar si ganamos
    if not self.enabled or not self.currentPet then return end
    -- Solo decir victoria si la mascota sigue viva
    if UnitExists("pet") and not UnitIsDead("pet") then
        self:Say(self.currentPet, "onVictory")
    end
end

function WCS_BrainPetChat:OnMobDeath(message)
    -- La mascota celebra la victoria
    if not self.enabled or not self.currentPet then return end
    if UnitExists("pet") and not UnitIsDead("pet") then
        self:Say(self.currentPet, "onVictory")
    end
end

-- ============================================================================
-- SISTEMA DE HABLA
-- ============================================================================
function WCS_BrainPetChat:Say(petType, situation)
    if not self.enabled then return end
    if not petType or not self.Dialogs[petType] then return end
    
    local dialogs = self.Dialogs[petType][situation]
    if not dialogs or table.getn(dialogs) == 0 then return end
    
    -- Seleccionar diálogo aleatorio
    local index = math.random(1, table.getn(dialogs))
    local dialog = dialogs[index]
    
    -- Mostrar en chat
    local color = self:GetPetColor(petType)
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. petType .. "]|r " .. dialog)
end

-- Mapeo de sonidos para la Inmersión Auditiva Neural (PlaySound)
WCS_BrainPetChat.PetSounds = {
    ["Imp"] = "ImpAttack",
    ["Voidwalker"] = "VoidWalkerAttack",
    ["Succubus"] = "SuccubusAttack",
    ["Felhunter"] = "FelhunterAttack",
    ["Infernal"] = "InfernalAwaken",
    ["Doomguard"] = "DoomguardAttack"
}

function WCS_BrainPetChat:SendChat(text)
    if not self.enabled or not self.currentPet then return end
    local color = self:GetPetColor(self.currentPet) or "|cFFFFaa00"
    
    -- Inmersión Auditiva Neural: Reproducir sonido de la mascota
    local soundStr = self.PetSounds[self.currentPet]
    if soundStr then
        PlaySound(soundStr)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. self.currentPet .. "]|r " .. text)
end

function WCS_BrainPetChat:ProcessPlayerChat(msg)
    if not self.enabled or not self.currentPet or not UnitExists("pet") then return end
    
    local petName = UnitName("pet")
    if not petName then return end
    
    local lowerMsg = string.lower(msg)
    local lowerPetName = string.lower(petName)
    
    -- Memoria y Paciencia
    local now = GetTime()
    if now - self.Memory.lastTalkTime > 30 then
        self.Memory.patience = 5
    end
    
    self.Memory.lastTalkTime = now
    
    -- Reconocimiento de Patrones Complejos e Intenciones
    local intention = "onInteract"
    
    -- 1. Check Goetia (Tiene prioridad narrativa)
    if self.GoetiaKeywords then
        for i = 1, table.getn(self.GoetiaKeywords) do
            if string.find(lowerMsg, self.GoetiaKeywords[i]) then
                intention = "onMystic"
                break
            end
        end
    end
    
    -- 2. Parsing de intención gramatical
    if intention == "onInteract" then
        if string.find(lowerMsg, "?") or string.find(lowerMsg, "qué ") or string.find(lowerMsg, "cómo ") or string.find(lowerMsg, "por qué") then
            intention = "onQuestion"
            
            -- Fluidez / Contexto: ¿Es la segunda pregunta seguida?
            if self.Memory.lastTopic == "onQuestion" then
                self.Memory.patience = self.Memory.patience - 2
            end
            
        elseif string.find(lowerMsg, "tonto") or string.find(lowerMsg, "feo") or string.find(lowerMsg, "inútil") or string.find(lowerMsg, "estúpido") then
            intention = "onInsult"
            self.Memory.patience = self.Memory.patience - 3
            
        elseif string.find(lowerMsg, "buen") or string.find(lowerMsg, "lindo") or string.find(lowerMsg, "genial") or string.find(lowerMsg, "guapo") then
            intention = "onPraise"
            self.Memory.patience = self.Memory.patience + 1
            
        elseif not (string.find(lowerMsg, lowerPetName) or string.find(lowerMsg, "hola")) then
            -- Si no es una palabra mágica, ni pregunta/insulto, y no la nombraste, ignorar
            return
        end
    end
    
    -- Pérdida de paciencia si hablas demasiado
    self.Memory.patience = self.Memory.patience - 1
    if self.Memory.patience <= 0 then
        intention = "onAnnoyed"
    end
    
    -- Guardar contexto para la proxima vez
    self.Memory.lastTopic = intention
    
    -- Emitir respuesta
    if self.Dialogs[self.currentPet] and self.Dialogs[self.currentPet][intention] then
        self:Say(self.currentPet, intention)
    else
        self:Say(self.currentPet, "onInteract")
    end
end

function WCS_BrainPetChat:GetPetColor(petType)
    if petType == "Imp" then
        return "|cFFFF6600"  -- Naranja
    elseif petType == "Voidwalker" then
        return "|cFF9900FF"  -- Púrpura
    elseif petType == "Succubus" then
        return "|cFFFF00FF"  -- Rosa
    elseif petType == "Felhunter" then
        return "|cFF00FF00"  -- Verde
    elseif petType == "HunterPet" then
        return "|cFFABD473"  -- Verde Cazador
    else
        return "|cFFFFFFFF"  -- Blanco
    end
end

-- ============================================================================
-- WORLD CONSCIOUSNESS (CONSCIENCIA DEL ENTORNO)
-- ============================================================================
WCS_BrainPetChat.WorldDialogs = {
    ["Imp"] = {
        onDance = {"¡Mírate! Pareces un múrloc con espasmos.", "Te ves ridículo, amo."},
        onPet = {"¡Quita tus manos de mí!", "Bueno, un masajito no hace daño..."},
        onSlap = {"¡Auh! ¡¿Acaso soy tu esclavo?! Bueno, sí, pero ¡duele!", "¡Tú te lo buscaste!"},
        onKiss = {"¡Eww, no me toques con esos labios!", "¡Aléjate, bicho raro!"},
        onEpicLoot = {"¡Por los cuernos de Sargeras! ¡Por fin recoges algo que no es basura!", "¡Véndelo y comprame algo!"},
        onZoneDark = {"Huele a no-muerto podrido... me encanta.", "Siento magia negra pura. Qué acogedor."},
        onLowHealthPlayer = {"¡Amo, te estás muriendo! ¡Si mueres yo desaparezco! ¡CÚRATE!", "¡No te mueras, aún me debes oro!"},
        onPvpKill = {"¡Jajaja! ¡Mira cómo cae esa escoria!", "¡Quémalo de nuevo por si acaso!"},
        onAfkReturn = {"Al fin despiertas... pensé que tendría que buscar un nuevo amo.", "¿Terminaste tu siesta?"}
    },
    ["Voidwalker"] = {
        onDance = {"Tus movimientos son irrelevantes en el vacío.", "El tiempo es una ilusión, igual que tu baile."},
        onPet = {"Tu mano atraviesa mi ser...", "Sentimientos... innecesarios."},
        onSlap = {"Tu ira es fútil contra el vacío.", "*Absorbe el impacto en silencio*"},
        onKiss = {"*Silencio sepulcral*", "El vacío no corresponde afectos."},
        onEpicLoot = {"Una reliquia digna de tu poder, amo.", "El poder material es efímero, pero útil."},
        onZoneDark = {"El vacío resuena en estas tierras malditas.", "Las sombras aquí son densas... me nutren."},
        onLowHealthPlayer = {"Tu sangre se derrama rápidamente... apártate, yo seré tu escudo.", "Amo, retrocede. No puedo protegerte si caes."},
        onPvpKill = {"Otra alma consumida por el vacío.", "Tu enemigo ha dejado de existir."},
        onAfkReturn = {"El vacío esperó pacientemente tu regreso.", "El tiempo no pasó para mí."}
    },
    ["Succubus"] = {
        onDance = {"Mmm, amo, tienes un ritmo interesante~", "Enséñame esos pasos en privado~"},
        onPet = {"Oh, sigue así, cariño~", "*Ronronea suavemente*"},
        onSlap = {"¡Ouch! ¡Más fuerte, amo!~", "Me gusta cuando te pones agresivo..."},
        onKiss = {"*Te devuelve un beso ardiente*", "Sabes a victoria y azufre~"},
        onEpicLoot = {"Qué brillo tan encantador, amo. Te verás muy guapo con eso.", "Mío, todo mío... bueno, tuyo."},
        onZoneDark = {"Qué lugar tan lúgubre... perfecto para una travesura.", "Esta oscuridad me da... ideas~"},
        onLowHealthPlayer = {"¡Cariño! ¡Estás herido! ¡No me dejes viuda!", "¡Sobrevive, amo, aún no terminamos de jugar!"},
        onPvpKill = {"Pobre criatura... cayó ante nuestra belleza.", "Un juguete menos en el mundo."},
        onAfkReturn = {"¡Me tenías abandonada! Ya estaba buscando a alguien más~", "Por fin, ya me aburría."}
    },
    ["Felhunter"] = {
        onDance = {"*Te mira ladeando la cabeza*", "*Bosteza aburrido*"},
        onPet = {"*Mueve los tentáculos de felicidad*", "*Ronronea demoníacamente*"},
        onSlap = {"*Aúlla de dolor*", "*Gruñe agresivamente*"},
        onKiss = {"*Te lame la cara con una lengua mágica*", "*Sniff sniff*"},
        onEpicLoot = {"*Huele la poderosa magia del objeto*", "*Intenta comerse el objeto*"},
        onZoneDark = {"*Olfatea las sombras intensamente*", "*Se pone en guardia*"},
        onLowHealthPlayer = {"*Gime viéndote sangrar*", "*Se pone delante de ti para defenderte*"},
        onPvpKill = {"*Se alimenta de la magia residual del cadáver*", "*Aúlla de victoria salvaje*"},
        onAfkReturn = {"*Te salta encima emocionado*", "*Gime porque tardaste mucho*"}
    },
    ["HunterPet"] = {
        onDance = {"*Salta a tu alrededor intentando imitarte*", "*Ladea la cabeza curioso*"},
        onPet = {"*Recuesta su cabeza en tu mano*", "*Gruñe con satisfacción*"},
        onSlap = {"*Gime lastimosamente y baja las orejas*", "*Se encoge de miedo*"},
        onKiss = {"*Te da un lengüetazo baboso*", "*Mueve la cola frenéticamente*"},
        onEpicLoot = {"*Olfatea el objeto curioso*", "*Llama tu atención hacia el objeto*"},
        onZoneDark = {"*Se eriza y gruñe a las sombras*", "*Se mantiene muy cerca de tus piernas*"},
        onLowHealthPlayer = {"*Ladra/Aúlla desesperadamente*", "*Intenta arrastrarte lejos del peligro*"},
        onPvpKill = {"*Muerde el cadáver del enemigo*", "*Aúlla orgulloso de la caza*"},
        onAfkReturn = {"*Da vueltas a tu alrededor emocionado*", "*Te empuja con el hocico para que avancen*"}
    }
}

WCS_BrainPetChat.WorldCooldown = 0

-- Funciones de procesamiento de mundo
function WCS_BrainPetChat:WorldSay(petType, situation)
    if not self.enabled then return end
    
    -- Prevención de Flood/Spam (Cooldown de 5 segundos)
    local now = GetTime()
    if now - self.WorldCooldown < 5 then return end
    self.WorldCooldown = now
    
    if not petType or not self.WorldDialogs[petType] then return end
    local dialogs = self.WorldDialogs[petType][situation]
    if not dialogs or table.getn(dialogs) == 0 then return end
    local index = math.random(1, table.getn(dialogs))
    local dialog = dialogs[index]
    local color = self:GetPetColor(petType)
    DEFAULT_CHAT_FRAME:AddMessage(color .. "[" .. petType .. "]|r " .. dialog)
end

function WCS_BrainPetChat:ProcessEmote(msg)
    if not self.currentPet or not UnitExists("pet") then return end
    local lowerMsg = string.lower(msg)
    if string.find(lowerMsg, "baila") or string.find(lowerMsg, "dance") then 
        self:WorldSay(self.currentPet, "onDance")
    elseif string.find(lowerMsg, "acaricia") or string.find(lowerMsg, "pet") or string.find(lowerMsg, "mimo") then 
        self.Memory.patience = 5
        self:WorldSay(self.currentPet, "onPet")
    elseif string.find(lowerMsg, "abofetea") or string.find(lowerMsg, "slap") or string.find(lowerMsg, "golpea") then 
        self.Memory.patience = 0
        self:WorldSay(self.currentPet, "onSlap")
    elseif string.find(lowerMsg, "besa") or string.find(lowerMsg, "kiss") then 
        self:WorldSay(self.currentPet, "onKiss") 
    end
end

function WCS_BrainPetChat:ProcessLoot(msg)
    if not self.currentPet or not UnitExists("pet") then return end
    -- Check for Epic (cffa335ee)
    if string.find(msg, "cffa335ee") then
        self:WorldSay(self.currentPet, "onEpicLoot")
    end
end

function WCS_BrainPetChat:ProcessZone()
    if not self.currentPet or not UnitExists("pet") then return end
    local zone = GetZoneText()
    if zone == "Entrañas" or zone == "Tierras de la Peste del Oeste" or zone == "Tierras de la Peste del Este" or zone == "Claros de Tirisfal" or zone == "Bosque de Argénteos" then
        self:WorldSay(self.currentPet, "onZoneDark")
    end
end

function WCS_BrainPetChat:CheckHealth()
    if not self.currentPet or not UnitExists("pet") then return end
    if not UnitAffectingCombat("player") then return end
    
    local hpPct = (UnitHealth("player") / UnitHealthMax("player")) * 100
    if hpPct < 15 and not self.Memory.lowHealthAlerted then
        self.Memory.lowHealthAlerted = true
        self:WorldSay(self.currentPet, "onLowHealthPlayer")
    elseif hpPct > 30 then
        self.Memory.lowHealthAlerted = false
    end
end

function WCS_BrainPetChat:ProcessPvP()
    if not self.currentPet or not UnitExists("pet") then return end
    self:WorldSay(self.currentPet, "onPvpKill")
end

function WCS_BrainPetChat:ProcessSystem(msg)
    if not self.currentPet or not UnitExists("pet") then return end
    local lowerMsg = string.lower(msg)
    
    -- Se evita buscar palabras acentuadas completas porque en LUA 5.0 (WoW Vanilla)
    -- string.lower puede corromper caracteres UTF-8 en clientes multilenguaje.
    if string.find(lowerMsg, "ausente") or string.find(lowerMsg, "away") or string.find(lowerMsg, "afk") then
        if not string.find(lowerMsg, "estas ausente") and not string.find(lowerMsg, "you are away") then
            -- El mensaje suele ser "Ya no estás ausente" o "You are no longer away"
            self:WorldSay(self.currentPet, "onAfkReturn")
        end
    end
end

-- ============================================================================
-- COMANDOS SLASH
-- ============================================================================
SLASH_WCSPETCHAT1 = "/wcspetchat"
SLASH_WCSPETCHAT2 = "/brainpetchat"

SlashCmdList["WCSPETCHAT"] = function(msg)
    if msg == "on" then
        WCS_BrainPetChat.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Chat de mascotas activado")
        
    elseif msg == "off" then
        WCS_BrainPetChat.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Chat de mascotas desactivado")
        
    elseif msg == "test" then
        -- Detectar mascota actual antes de testear
        WCS_BrainPetChat:DetectCurrentPet()
        if WCS_BrainPetChat.currentPet then
            WCS_BrainPetChat:Say(WCS_BrainPetChat.currentPet, "onSummon")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r No hay mascota activa")
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF9482C9[WCS PetChat]|r Comandos:")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat on|r - Activar chat")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat off|r - Desactivar chat")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00/brainpetchat test|r - Probar chat")
    end
end

-- ============================================================================
-- PRECOGNICIÓN DE MUERTE (CheckHealth)
-- ============================================================================
WCS_BrainPetChat.LastHealthWarning = 0

function WCS_BrainPetChat:CheckHealth()
    if not self.enabled or not self.currentPet or UnitIsDeadOrGhost("player") then return end
    
    local hpMax = UnitHealthMax("player")
    if hpMax == 0 then return end
    local hpPerc = (UnitHealth("player") / hpMax) * 100
    
    if hpPerc < 20 and UnitAffectingCombat("player") then
        local now = GetTime()
        if now - self.LastHealthWarning > 30 then -- Cooldown de 30 segundos
            self.LastHealthWarning = now
            
            -- Precognición HUD
            UIErrorsFrame:AddMessage("|cFFFF0000[PRECOGNICIÓN NEURAL]|r ¡Amo, constantes vitales colapsando! ¡Use Piedra de Salud AHORA!", 1.0, 0.0, 0.0, 1.0, 3)
            PlaySound("RaidWarning")
            
            -- Diálogo de la mascota
            self:WorldSay(self.currentPet, "onLowHealthPlayer")
        end
    end
end

-- Auto-inicialización
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "WCS_Brain" then
        WCS_BrainPetChat:Initialize()
    end
end)
