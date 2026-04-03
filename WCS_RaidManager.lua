--[[
    WCS_RaidManager.lua
    Gestor de Raid — Asignaciones, healthstones, soulstones

    CORRECCIONES (Lua 5.0, Layout, Funcional):
    - Corregido this.nextTradeTime en OnTradeAccept() → variable local de módulo
    - Ajustados anchos para caber en frame 700px (300px + 360px en vez de 360+400)
    - Agregado UIPanelScrollFrameTemplate para barra de scroll visible
    - Corregido RAID_CLASS_COLORS con claves en MAYÚSCULAS
]]--

WCS_RaidManager = WCS_RaidManager or {}

local panel            = nil
local raidMembers      = {}
local assignments      = {}
local distributionActive = false
local tradeQueue       = {}
local nextTradeTime    = nil   -- CORRECCIÓN: variable de módulo, no this.nextTradeTime

function WCS_RaidManager:Initialize()
    if panel then return end

    panel = CreateFrame("Frame", "WCS_RaidManagerFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffff0000Gestor de Raid|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Columna de miembros (izquierda, 300px)
    local membersBg = CreateFrame("Frame", nil, panel)
    membersBg:SetPoint("TOPLEFT", 10, -40)
    membersBg:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    membersBg:SetWidth(300)
    local membersBgTex = membersBg:CreateTexture(nil, "BACKGROUND")
    membersBgTex:SetAllPoints()
    membersBgTex:SetTexture(0, 0, 0, 0.5)

    local membersTitle = membersBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    membersTitle:SetPoint("TOP", 0, -5)
    membersTitle:SetText("|cffFFD700Miembros de Raid|r")

    -- ScrollFrame CON barra visible
    local scrollFrame = CreateFrame("ScrollFrame", "WCS_RaidScrollFrame", membersBg, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",    5,  -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 5)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(260)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    self.memberScrollChild = scrollChild
    self.memberButtons = {}

    -- Columna derecha desde membersBg+10
    local rightX = 320

    -- Asignaciones (derecha arriba)
    local assignBg = CreateFrame("Frame", nil, panel)
    assignBg:SetPoint("TOPLEFT",  rightX, -40)
    assignBg:SetPoint("TOPRIGHT", -10, -40)
    assignBg:SetHeight(235)
    local assignBgTex = assignBg:CreateTexture(nil, "BACKGROUND")
    assignBgTex:SetAllPoints()
    assignBgTex:SetTexture(0, 0, 0, 0.5)

    local assignTitle = assignBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    assignTitle:SetPoint("TOP", 0, -5)
    assignTitle:SetText("|cffFFD700Asignaciones de Soulstone|r")

    self.assignText = assignBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.assignText:SetPoint("TOPLEFT", 10, -30)
    self.assignText:SetPoint("BOTTOMRIGHT", assignBg, "BOTTOMRIGHT", -10, 40)
    self.assignText:SetJustifyH("LEFT")
    self.assignText:SetJustifyV("TOP")
    self.assignText:SetText("Tanques y Healers prioritarios:\n\nNo hay asignaciones activas")

    local function MakeBtn(parent, anchorPoint, label, w, r, g, b)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetPoint(anchorPoint, parent, anchorPoint, 10 * (anchorPoint == "BOTTOMLEFT" and 1 or (anchorPoint == "BOTTOM" and 0 or -1)), 8)
        btn:SetWidth(w)
        btn:SetHeight(25)
        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(r, g, b, 0.8)
        local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
        txt:SetText(label)
        return btn
    end

    local assignTankBtn = MakeBtn(assignBg, "BOTTOMLEFT",  "Asignar Tanks",   110, 0.2, 0.5, 0.2)
    local assignHealBtn = MakeBtn(assignBg, "BOTTOM",      "Asignar Healers", 110, 0.2, 0.5, 0.2)
    local clearBtn      = MakeBtn(assignBg, "BOTTOMRIGHT", "Limpiar",         110, 0.5, 0.2, 0.2)

    assignTankBtn:SetScript("OnClick", function() WCS_RaidManager:AssignSoulstones("TANK") end)
    assignHealBtn:SetScript("OnClick", function() WCS_RaidManager:AssignSoulstones("HEALER") end)
    clearBtn:SetScript("OnClick", function()
        assignments = {}
        WCS_RaidManager:UpdateAssignments()
    end)

    -- Distribución de Healthstones (derecha abajo)
    local healthBg = CreateFrame("Frame", nil, panel)
    healthBg:SetPoint("TOPLEFT",  assignBg, "BOTTOMLEFT",  0, -10)
    healthBg:SetPoint("BOTTOMRIGHT", -10, 10)
    local healthBgTex = healthBg:CreateTexture(nil, "BACKGROUND")
    healthBgTex:SetAllPoints()
    healthBgTex:SetTexture(0, 0, 0, 0.5)

    local healthTitle = healthBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthTitle:SetPoint("TOP", 0, -5)
    healthTitle:SetText("|cffFFD700Distribución de Healthstones|r")

    self.healthText = healthBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.healthText:SetPoint("TOPLEFT", 10, -30)
    self.healthText:SetPoint("BOTTOMRIGHT", healthBg, "BOTTOMRIGHT", -10, 40)
    self.healthText:SetJustifyH("LEFT")
    self.healthText:SetJustifyV("TOP")

    local distributeBtn = MakeBtn(healthBg, "BOTTOM", "Distribuir Healthstones", 200, 0.2, 0.5, 0.2)
    distributeBtn:SetScript("OnClick", function() WCS_RaidManager:DistributeHealthstones() end)

    self.panel = panel

    panel:RegisterEvent("RAID_ROSTER_UPDATE")
    panel:RegisterEvent("PARTY_MEMBERS_CHANGED")
    panel:RegisterEvent("CHAT_MSG_WHISPER")
    panel:RegisterEvent("TRADE_SHOW")
    panel:RegisterEvent("TRADE_ACCEPT_UPDATE")
    panel:SetScript("OnEvent", function()
        if event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            WCS_RaidManager:UpdateRaidMembers()
        elseif event == "CHAT_MSG_WHISPER" then
            WCS_RaidManager:OnWhisper(arg1, arg2)
        elseif event == "TRADE_SHOW" then
            WCS_RaidManager:OnTradeShow()
        elseif event == "TRADE_ACCEPT_UPDATE" then
            WCS_RaidManager:OnTradeAccept()
        end
    end)

    panel:SetScript("OnUpdate", function()
        if not this.lastUpdate then this.lastUpdate = 0 end
        this.lastUpdate = this.lastUpdate + arg1
        if this.lastUpdate >= 2.0 then
            this.lastUpdate = 0
            WCS_RaidManager:UpdateHealthstoneInfo()
        end
        if nextTradeTime and GetTime() >= nextTradeTime then
            nextTradeTime = nil
            WCS_RaidManager:ProcessNextTrade()
        end
    end)

    self:UpdateRaidMembers()
    self:UpdateHealthstoneInfo()
end

function WCS_RaidManager:UpdateRaidMembers()
    raidMembers = {}
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, rank, subgroup, level, class = GetRaidRosterInfo(i)
            if name then
                table.insert(raidMembers, {name=name, class=class or "Unknown", subgroup=subgroup or 1, level=level or 60})
            end
        end
    else
        local numParty = GetNumPartyMembers()
        if numParty > 0 then
            for i = 1, numParty do
                local name = UnitName("party"..i)
                if name then
                    table.insert(raidMembers, {name=name, class=UnitClass("party"..i) or "Unknown", subgroup=1, level=UnitLevel("party"..i) or 60})
                end
            end
        end
    end
    self:UpdateMemberList()
end

function WCS_RaidManager:UpdateMemberList()
    for i = 1, table.getn(self.memberButtons) do self.memberButtons[i]:Hide() end
    for i = 1, table.getn(raidMembers) do
        local member = raidMembers[i]
        local btn = self.memberButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, self.memberScrollChild)
            btn:SetWidth(250)
            btn:SetHeight(25)
            btn:SetPoint("TOPLEFT", 5, -(i-1)*27)
            local bgTex = btn:CreateTexture(nil, "BACKGROUND")
            bgTex:SetAllPoints()
            bgTex:SetTexture(0.1, 0.1, 0.1, 0.8)
            btn.bg = bgTex
            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btnText:SetPoint("LEFT", 5, 0)
            btnText:SetJustifyH("LEFT")
            btn.text = btnText
            self.memberButtons[i] = btn
        end
        local classKey   = string.upper(member.class or "")
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]) or {r=1,g=1,b=1}
        btn.text:SetText(string.format("|cff%02x%02x%02x%s|r - G%d",
            math.floor(classColor.r*255), math.floor(classColor.g*255), math.floor(classColor.b*255),
            member.name, member.subgroup))
        btn:Show()
    end
    self.memberScrollChild:SetHeight(math.max(1, table.getn(raidMembers)*27))
end

function WCS_RaidManager:AssignSoulstones(role)
    self:UpdateRaidMembers()
    assignments = {}
    local priority = {}
    if role == "TANK" then
        priority = {WARRIOR=1, DRUID=2, PALADIN=3}
    else
        priority = {PRIEST=1, DRUID=2, PALADIN=3, SHAMAN=4}
    end
    for i = 1, table.getn(raidMembers) do
        local member   = raidMembers[i]
        local classKey = string.upper(member.class or "")
        if priority[classKey] then
            table.insert(assignments, {name=member.name, class=member.class, classKey=classKey, priority=priority[classKey]})
        end
    end
    -- Bubble sort Lua 5.0
    for i = 1, table.getn(assignments) do
        for j = i+1, table.getn(assignments) do
            if assignments[j].priority < assignments[i].priority then
                local tmp = assignments[i]; assignments[i] = assignments[j]; assignments[j] = tmp
            end
        end
    end
    self:UpdateAssignments()
end

function WCS_RaidManager:UpdateAssignments()
    if table.getn(assignments) == 0 then
        self.assignText:SetText("Tanques y Healers prioritarios:\n\nNo hay asignaciones activas")
        return
    end
    local text = "Asignaciones de Soulstone:\n\n"
    for i = 1, math.min(5, table.getn(assignments)) do
        local a = assignments[i]
        local classColor = (RAID_CLASS_COLORS and RAID_CLASS_COLORS[a.classKey]) or {r=1,g=1,b=1}
        text = text .. string.format("%d. |cff%02x%02x%02x%s|r (%s)\n",
            i, math.floor(classColor.r*255), math.floor(classColor.g*255), math.floor(classColor.b*255),
            a.name, a.class)
    end
    self.assignText:SetText(text)
end

function WCS_RaidManager:UpdateHealthstoneInfo()
    local numRaid  = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    local total    = numRaid > 0 and numRaid or (numParty > 0 and numParty + 1 or 1)
    local hs = 0
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, "Healthstone") then
                    local _, count = GetContainerItemInfo(bag, slot)
                    hs = hs + (count or 1)
                end
            end
        end
    end
    self.healthText:SetText(string.format(
        "Miembros: %d\nHealthstones: %d\nNecesarias: %d\n\n%s",
        total, hs, total,
        hs >= total and "|cff00ff00Suficientes|r" or "|cffff0000Faltan healthstones|r"))
end

function WCS_RaidManager:DistributeHealthstones()
    if distributionActive then
        distributionActive = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Raid Manager]|r Distribución DESACTIVADA")
        return
    end
    distributionActive = true
    tradeQueue = {}
    local playerName = UnitName("player")
    if GetNumRaidMembers() > 0 then
        SendChatMessage("Healthstones disponibles! Susurra !hs para recibir una. /w " .. playerName .. " !hs", "RAID")
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Raid Manager]|r Distribución ACTIVADA")
end

function WCS_RaidManager:OnWhisper(message, sender)
    if not distributionActive then return end
    local msg = string.lower(message or "")
    if not string.find(msg, "!hs") then return end
    local inRaid = false
    for i = 1, table.getn(raidMembers) do
        if raidMembers[i].name == sender then inRaid = true; break end
    end
    if not inRaid then return end
    for i = 1, table.getn(tradeQueue) do
        if tradeQueue[i] == sender then return end
    end
    table.insert(tradeQueue, sender)
    if table.getn(tradeQueue) == 1 then WCS_RaidManager:ProcessNextTrade() end
end

function WCS_RaidManager:ProcessNextTrade()
    if table.getn(tradeQueue) == 0 then return end
    InitiateTrade(tradeQueue[1])
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Raid Manager]|r Iniciando trade con " .. tradeQueue[1])
end

function WCS_RaidManager:OnTradeShow()
    if not distributionActive or table.getn(tradeQueue) == 0 then return end
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link and string.find(link, "Healthstone") then
                    PickupContainerItem(bag, slot)
                    ClickTradeButton(1)
                    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Raid Manager]|r Healthstone colocada.")
                    return
                end
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Raid Manager]|r Sin healthstones!")
end

function WCS_RaidManager:OnTradeAccept()
    if not distributionActive or table.getn(tradeQueue) == 0 then return end
    local player = table.remove(tradeQueue, 1)
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Raid Manager]|r Trade OK con " .. player)
    if table.getn(tradeQueue) > 0 then
        nextTradeTime = GetTime() + 1.0  -- variable de módulo, no this.nextTradeTime
    end
end

function WCS_RaidManager:Show()
    if self.panel then
        self.panel:Show()
        self:UpdateRaidMembers()
        self:UpdateHealthstoneInfo()
    end
end

function WCS_RaidManager:Hide()
    if self.panel then self.panel:Hide() end
end

_G["WCS_RaidManager"] = WCS_RaidManager
