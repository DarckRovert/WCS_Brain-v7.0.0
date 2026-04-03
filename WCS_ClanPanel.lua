--[[
    WCS_ClanPanel.lua
    Panel de Miembros del Clan para "El Séquito del Terror"

    CORRECCIONES (Lua 5.0, Layout):
    - Eliminado SetWidth(760) en statsFrame → ahora relativo (TOPRIGHT)
    - Corregido table.sort con booleano directo (crash Lua 5.0)
    - scrollFrame ahora usa BOTTOMRIGHT relativo en lugar de coordenadas fijas
]]--

WCS_ClanPanel = WCS_ClanPanel or {}

local panel = nil
local memberList = {}
local scrollFrame = nil

function WCS_ClanPanel:Initialize()
    if panel then return end

    panel = CreateFrame("Frame", "WCS_ClanPanelFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()

    -- Título
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cff00ff00Miembros del Séquito|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Estadísticas rápidas — relativas al padre
    local statsFrame = CreateFrame("Frame", nil, panel)
    statsFrame:SetPoint("TOPLEFT", 10, -40)
    statsFrame:SetPoint("TOPRIGHT", -10, -40)   -- no más SetWidth(760)
    statsFrame:SetHeight(60)
    statsFrame:SetBackdrop({
        bgFile  = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    statsFrame:SetBackdropColor(0.1, 0.0, 0.15, 0.8)
    statsFrame:SetBackdropBorderColor(0.2, 1.0, 0.2, 0.5)

    -- Total de miembros
    local totalText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalText:SetPoint("TOPLEFT", 10, -10)
    totalText:SetText("|cff00ff00Total:|r 0")
    panel.totalText = totalText

    -- Miembros online
    local onlineText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    onlineText:SetPoint("TOPLEFT", 10, -30)
    onlineText:SetText("|cff00ff00Online:|r 0")
    panel.onlineText = onlineText

    -- Nivel promedio
    local avgLevelText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    avgLevelText:SetPoint("LEFT", statsFrame, "LEFT", 200, 10)
    avgLevelText:SetText("|cff00ff00Nivel Promedio:|r 0")
    panel.avgLevelText = avgLevelText

    -- Brujos en el clan
    local warlocksText = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warlocksText:SetPoint("LEFT", statsFrame, "LEFT", 200, -10)
    warlocksText:SetText("|cff00ff00Brujos:|r 0")
    panel.warlocksText = warlocksText

    -- Botón de actualizar
    local refreshBtn = CreateFrame("Button", nil, statsFrame, "UIPanelButtonTemplate")
    refreshBtn:SetWidth(100)
    refreshBtn:SetHeight(25)
    refreshBtn:SetPoint("RIGHT", -10, 0)
    refreshBtn:SetText("Actualizar")
    refreshBtn:SetScript("OnClick", function()
        WCS_ClanPanel:UpdateMemberList()
    end)

    -- Scroll frame para lista de miembros — relativo al padre
    scrollFrame = CreateFrame("ScrollFrame", "WCS_ClanPanel_ScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -110)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(600)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    panel.scrollChild = scrollChild

    self.panel = panel
    self:UpdateMemberList()
end

function WCS_ClanPanel:UpdateMemberList()
    if not self.panel then return end

    -- Recrear el scroll child (Lua 5.0: no podemos DestroyFrame)
    if scrollFrame then
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(600)
        scrollChild:SetHeight(1)
        scrollFrame:SetScrollChild(scrollChild)
        self.panel.scrollChild = scrollChild
    end

    GuildRoster()
    local numTotal, numOnline = GetNumGuildMembers()
    numTotal  = numTotal  or 0
    numOnline = numOnline or 0

    if numTotal == 0 then
        local noGuildText = self.panel.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noGuildText:SetPoint("TOP", 0, -20)
        noGuildText:SetText("|cffff0000No estás en un clan o el roster no está cargado.|r")
        return
    end

    self.panel.totalText:SetText("|cff00ff00Total:|r " .. numTotal)
    self.panel.onlineText:SetText("|cff00ff00Online:|r " .. numOnline)

    local totalLevel  = 0
    local numWarlocks = 0
    local yOffset     = -5

    memberList = {}

    for i = 1, numTotal do
        local name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(i)
        if name then
            level   = level   or 1
            class   = class   or "Unknown"
            rank    = rank    or "Member"
            zone    = zone    or "Unknown"
            online  = online  or false

            totalLevel = totalLevel + level
            local classUpper = string.upper(class)
            if classUpper == "WARLOCK" then
                numWarlocks = numWarlocks + 1
            end

            table.insert(memberList, {
                name   = name,
                rank   = rank,
                level  = level,
                class  = class,
                zone   = zone,
                online = online
            })
        end
    end

    local avgLevel = math.floor(totalLevel / numTotal)
    self.panel.avgLevelText:SetText("|cff00ff00Nivel Promedio:|r " .. avgLevel)
    self.panel.warlocksText:SetText("|cff00ff00Brujos:|r " .. numWarlocks)

    -- CORRECCIÓN: table.sort con booleano → Lua 5.0 crash si return a.online
    -- Usar comparación numérica explícita
    table.sort(memberList, function(a, b)
        local ao = a.online and 1 or 0
        local bo = b.online and 1 or 0
        if ao ~= bo then
            return ao > bo  -- online primero
        end
        return a.level > b.level
    end)

    for i = 1, table.getn(memberList) do
        local member = memberList[i]
        local entry = CreateFrame("Frame", nil, self.panel.scrollChild)
        entry:SetWidth(590)
        entry:SetHeight(30)
        entry:SetPoint("TOPLEFT", 5, yOffset)

        local bg = entry:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(entry)
        if math.mod(i, 2) == 0 then
            bg:SetTexture(0.1, 0.1, 0.1, 0.5)
        else
            bg:SetTexture(0.15, 0.15, 0.15, 0.5)
        end

        local nameColor = member.online and "|cff00ff00" or "|cff888888"

        local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", 10, 0)
        nameText:SetText(nameColor .. member.name .. "|r")

        local levelText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        levelText:SetPoint("LEFT", 180, 0)
        levelText:SetText(nameColor .. "Nv " .. member.level .. "|r")

        local classText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        classText:SetPoint("LEFT", 240, 0)
        -- RAID_CLASS_COLORS usa claves en mayúsculas
        local classKey   = string.upper(member.class or "")
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]) or {r=1, g=1, b=1}
        classText:SetTextColor(classColor.r, classColor.g, classColor.b)
        classText:SetText(member.class or "Unknown")

        local rankText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rankText:SetPoint("LEFT", 340, 0)
        rankText:SetText(nameColor .. member.rank .. "|r")

        local zoneText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        zoneText:SetPoint("LEFT", 460, 0)
        zoneText:SetText(nameColor .. (member.zone or "?") .. "|r")

        yOffset = yOffset - 30
    end

    self.panel.scrollChild:SetHeight(math.abs(yOffset) + 10)
end

function WCS_ClanPanel:Show()
    if self.panel then
        self.panel:Show()
        self:UpdateMemberList()
    end
end

function WCS_ClanPanel:Hide()
    if self.panel then self.panel:Hide() end
end

_G["WCS_ClanPanel"] = WCS_ClanPanel
