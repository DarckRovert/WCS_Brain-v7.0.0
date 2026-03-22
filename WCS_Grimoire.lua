--[[
    WCS_Grimoire.lua
    Grimorio de Brujo - Base de datos de hechizos y rotaciones
]]--

WCS_Grimoire = WCS_Grimoire or {}

local panel = nil
local selectedSpell = nil
local selectedSpec = "Affliction"

-- Clasificación de hechizos dinámica mediante GetSpellTabInfo en tiempo real

-- Función para escanear el spellbook del jugador
function WCS_Grimoire:ScanPlayerSpells()
    local spells = {}
    local i = 1
    local numTabs = GetNumSpellTabs()
    
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        
        -- Extraer el nombre base del hechizo (sin "Rank X")
        local baseName = spellName
        local rank = 0
        
        if spellRank then
            local _, _, rankNum = string.find(spellRank, "Rank (%d+)")
            if rankNum then
                rank = tonumber(rankNum)
            end
        end
        
        -- Obtener la escuela determinando el tab del libro
        local school = "Other"
        if numTabs then
            for t = 1, numTabs do
                local tabName, _, offset, numSpells = GetSpellTabInfo(t)
                if tabName and i > offset and i <= (offset + numSpells) then
                    school = tabName
                    break
                end
            end
        end
        
        -- Obtener información del hechizo
        local spellTexture = GetSpellTexture(i, BOOKTYPE_SPELL)
        
        -- Verificar si ya tenemos este hechizo
        local existing = spells[baseName]
        if not existing or rank > existing.rank then
            -- Este es el rango más alto que hemos visto
            spells[baseName] = {
                name = baseName,
                rank = rank,
                school = school,
                texture = spellTexture,
                spellId = i
            }
        end
        
        i = i + 1
    end
    
    -- Convertir tabla a array
    local spellArray = {}
    for name, spell in spells do
        table.insert(spellArray, spell)
    end
    
    return spellArray
end

-- ROTATIONS eliminadas por estaticidad, se manejan live desde WCS_DecisionEngine

function WCS_Grimoire:Initialize()
    if panel then return end
    
    panel = CreateFrame("Frame", "WCS_GrimoireFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()
    
    -- Título
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff9370DBGrimorio Oscuro|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Botones de especialización dinámicos según GetSpellTabInfo
    local specButtons = {}
    local numTabs = GetNumSpellTabs()
    local specs = {}
    
    if numTabs and numTabs > 1 then
        for i = 2, numTabs do
            local name = GetSpellTabInfo(i)
            if name then table.insert(specs, name) end
        end
    else
        specs = {"Affliction", "Destruction", "Demonology"}
    end
    
    if table.getn(specs) > 0 then
        selectedSpec = specs[1]
    end

    for i = 1, table.getn(specs) do
        local spec = specs[i]
        local btn = CreateFrame("Button", nil, panel)
        btn:SetPoint("TOPLEFT", 10 + (i-1)*120, -40)
        btn:SetWidth(110)
        btn:SetHeight(25)
        
        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetTexture(0, 0, 0, 0.7)
        btn.bg = btnBg
        
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btnText:SetText(spec)
        
        btn:SetScript("OnClick", function()
            selectedSpec = spec
            WCS_Grimoire:UpdateSpecButtons()
            WCS_Grimoire:UpdateSpellList()
            WCS_Grimoire:UpdateRotation()
        end)
        
        specButtons[spec] = btn
    end
    
    self.specButtons = specButtons
    
    -- Lista de hechizos (izquierda)
    local spellListBg = CreateFrame("Frame", nil, panel)
    spellListBg:SetPoint("TOPLEFT", 10, -75)
    spellListBg:SetWidth(360)
    spellListBg:SetHeight(450)
    local spellListBgTex = spellListBg:CreateTexture(nil, "BACKGROUND")
    spellListBgTex:SetAllPoints()
    spellListBgTex:SetTexture(0, 0, 0, 0.5)
    
    local spellListTitle = spellListBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spellListTitle:SetPoint("TOP", 0, -5)
    spellListTitle:SetText("|cffFFD700Lista de Hechizos|r")
    
    -- Scroll frame para hechizos
    local scrollFrame = CreateFrame("ScrollFrame", "WCS_GrimoireScrollFrame", spellListBg)
    scrollFrame:SetPoint("TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -5, 5)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(340)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    self.spellScrollChild = scrollChild
    self.spellButtons = {}
    
    -- Panel de detalles (derecha)
    local detailsBg = CreateFrame("Frame", nil, panel)
    detailsBg:SetPoint("TOPRIGHT", -10, -75)
    detailsBg:SetWidth(400)
    detailsBg:SetHeight(250)
    local detailsBgTex = detailsBg:CreateTexture(nil, "BACKGROUND")
    detailsBgTex:SetAllPoints()
    detailsBgTex:SetTexture(0, 0, 0, 0.5)
    
    local detailsTitle = detailsBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailsTitle:SetPoint("TOP", 0, -5)
    detailsTitle:SetText("|cffFFD700Detalles del Hechizo|r")
    
    self.detailsText = detailsBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.detailsText:SetPoint("TOPLEFT", 10, -30)
    self.detailsText:SetWidth(380)
    self.detailsText:SetJustifyH("LEFT")
    self.detailsText:SetText("Selecciona un hechizo para ver detalles")
    
    -- Panel de rotación (derecha abajo)
    local rotationBg = CreateFrame("Frame", nil, panel)
    rotationBg:SetPoint("TOPRIGHT", -10, -335)
    rotationBg:SetWidth(400)
    rotationBg:SetHeight(190)
    local rotationBgTex = rotationBg:CreateTexture(nil, "BACKGROUND")
    rotationBgTex:SetAllPoints()
    rotationBgTex:SetTexture(0, 0, 0, 0.5)
    
    local rotationTitle = rotationBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rotationTitle:SetPoint("TOP", 0, -5)
    rotationTitle:SetText("|cffFFD700Rotación Recomendada|r")
    
    self.rotationText = rotationBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.rotationText:SetPoint("TOPLEFT", 10, -30)
    self.rotationText:SetWidth(380)
    self.rotationText:SetJustifyH("LEFT")
    
    self.panel = panel
    
    -- Inicializar
    self:UpdateSpecButtons()
    self:UpdateSpellList()
    self:UpdateRotation()
end

function WCS_Grimoire:UpdateSpecButtons()
    for spec, btn in pairs(self.specButtons) do
        if spec == selectedSpec then
            btn.bg:SetTexture(0.4, 0.2, 0.6, 0.8)
        else
            btn.bg:SetTexture(0, 0, 0, 0.7)
        end
    end
end

function WCS_Grimoire:UpdateSpellList()
    -- Limpiar botones anteriores
    for i = 1, table.getn(self.spellButtons) do
        self.spellButtons[i]:Hide()
    end
    
    -- Escanear hechizos del jugador
    local playerSpells = self:ScanPlayerSpells()
    
    -- Filtrar hechizos por especialización
    local filteredSpells = {}
    for i = 1, table.getn(playerSpells) do
        local spell = playerSpells[i]
        if spell.school == selectedSpec then
            table.insert(filteredSpells, spell)
        end
    end
    
    -- Crear/actualizar botones
    for i = 1, table.getn(filteredSpells) do
        local spell = filteredSpells[i]
        local btn = self.spellButtons[i]
        
        if not btn then
            btn = CreateFrame("Button", nil, self.spellScrollChild)
            btn:SetWidth(330)
            btn:SetHeight(30)
            btn:SetPoint("TOPLEFT", 5, -(i-1)*32)
            
            local btnBg = btn:CreateTexture(nil, "BACKGROUND")
            btnBg:SetAllPoints()
            btnBg:SetTexture(0.1, 0.1, 0.1, 0.8)
            btn.bg = btnBg
            
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btnText:SetPoint("LEFT", 5, 0)
            btnText:SetJustifyH("LEFT")
            btn.text = btnText
            
            self.spellButtons[i] = btn
        end
        
        btn.spell = spell
        local rankText = ""
        if spell.rank and spell.rank > 0 then
            rankText = " (Rank " .. spell.rank .. ")"
        end
        btn.text:SetText(string.format("|cff9370DB%s|r%s", spell.name, rankText))
        
        btn:SetScript("OnClick", function()
            selectedSpell = this.spell
            WCS_Grimoire:UpdateSpellDetails()
        end)
        
        btn:SetScript("OnEnter", function()
            this.bg:SetTexture(0.3, 0.2, 0.4, 0.9)
        end)
        
        btn:SetScript("OnLeave", function()
            this.bg:SetTexture(0.1, 0.1, 0.1, 0.8)
        end)
        
        btn:Show()
    end
    
    self.spellScrollChild:SetHeight(math.max(1, table.getn(filteredSpells) * 32))
end

function WCS_Grimoire:UpdateSpellDetails()
    if not selectedSpell then
        self.detailsText:SetText("Selecciona un hechizo para ver detalles")
        return
    end
    
    local details = string.format(
        "|cffFFD700Nombre:|r %s\n" ..
        "|cffFFD700Rango:|r %d\n" ..
        "|cffFFD700Escuela:|r %s\n" ..
        "|cffFFD700Daño:|r %s\n" ..
        "|cffFFD700Maná:|r %s\n" ..
        "|cffFFD700Rango:|r %s\n" ..
        "|cffFFD700Tiempo de Lanzamiento:|r %s\n" ..
        "|cffFFD700Cooldown:|r %s",
        selectedSpell.name or "Desconocido",
        selectedSpell.rank or 0,
        selectedSpell.school or "Desconocido",
        selectedSpell.damage or "N/A",
        tostring(selectedSpell.mana or "N/A"),
        tostring(selectedSpell.range or "N/A") .. " yardas",
        selectedSpell.cast or "N/A",
        tostring(selectedSpell.cooldown or "N/A") .. "s"
    )
    
    self.detailsText:SetText(details)
end

function WCS_Grimoire:UpdateRotation()
    local text = "|cff00ff00Rotación Táctica Predictiva:|r\n"
    
    if WCS and WCS.ClassRotations and WCS.ClassRotations.GetRotation then
        local rotation = WCS.ClassRotations:GetRotation()
        if rotation and table.getn(rotation) > 0 then
            for i = 1, table.getn(rotation) do
                text = text .. string.format("%d. %s\n", i, rotation[i])
            end
        else
            text = text .. "No hay rotación definida para esta clase."
        end
    else
        text = text .. "Motor WCS_DecisionEngine activo."
    end
    self.rotationText:SetText(text)
end

function WCS_Grimoire:Show()
    if self.panel then self.panel:Show() end
end

function WCS_Grimoire:Hide()
    if self.panel then self.panel:Hide() end
end

-- ============================================================================
-- MULTI-CLASS ROTATION ROUTING
-- GetBestRotation() returns the priority rotation for the current player class.
-- If WCS.ClassEngine is loaded, it uses it; otherwise falls back to the
-- hardcoded Warlock rotation for backward compatibility.
-- ============================================================================
function WCS_Grimoire:GetBestRotation()
    -- Route through ClassEngine if available (multi-class support)
    if WCS and WCS.ClassEngine and WCS.ClassEngine.GetRotation then
        return WCS.ClassEngine:GetRotation()
    end

    -- Warlock fallback (pre-ClassEngine compatibility)
    local spec = selectedSpec or "Affliction"
    if spec == "Affliction" then
        return { "Curse of Agony", "Corruption", "Siphon Life", "Shadow Bolt" }
    elseif spec == "Destruction" then
        return { "Immolate", "Curse of Doom", "Conflagrate", "Shadow Bolt" }
    else -- Demonology
        return { "Curse of Agony", "Corruption", "Shadow Bolt" }
    end
end

-- Expose under WCS namespace so WCS_Core and DecisionEngine can find it
_G["WCS_Grimoire"] = WCS_Grimoire
if WCS then WCS.Grimoire = WCS_Grimoire end
