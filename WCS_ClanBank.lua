--[[
    WCS_ClanBank.lua
    Inventario Personal — Tracking de recursos del brujo

    CORRECCIONES (Lua 5.0, Layout):
    - Reemplazado string.match() → string.find() con capturas (Lua 5.0)
    - Eliminados SetWidth de paneles que desbordaban el frame (760px → relativos)
    - Corregido GetItemInfo(link) → extraer itemID del link con string.find
    - Columnas de items ajustadas a 310px cada una (suma = 10+310+10+310+10 = 650 < 700 ✓)
]]--

WCS_ClanBank = WCS_ClanBank or {}

-- ============================================================================
-- WCSVault: Protocolo P2P de Sincronizacion de Banco
-- ============================================================================
WCS_ClanBank.Vault = {
    protocol  = "WCSVault",
    ledger    = {},
    maxEntries = 100
}

function WCS_ClanBank.Vault:BroadcastTransaction(txType, amount, player)
    local msg = string.format("%s:%s:%s", txType, tostring(amount), player)
    SendAddonMessage(self.protocol, msg, "GUILD")
end

function WCS_ClanBank.Vault:OnMessageReceived(prefix, message, sender)
    if prefix ~= self.protocol then return end

    -- CORRECCIÓN: string.match no existe en Lua 5.0 → usar string.find con capturas
    local _, _, txType, amount, player = string.find(message, "([^:]+):([^:]+):([^:]+)")
    if txType and amount and player then
        table.insert(self.ledger, 1, {
            type   = txType,
            amount = amount,
            player = player,
            time   = GetTime()
        })
        if table.getn(self.ledger) > self.maxEntries then
            table.remove(self.ledger)
        end
        WCS_Print(string.format("|cFF00FF00[WCSVault]|r Transaccion recibida: %s %sg de %s", txType, amount, player))
    end
end

local panel = nil
local bankData = {
    transactions = {}
}

-- Items comunes de brujo para trackear
local TRACKED_ITEMS = {
    {name = "Soul Shard",             id = 6265,  icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02"},
    {name = "Healthstone",            id = 5512,  icon = "Interface\\Icons\\INV_Stone_04"},       -- any HS rank
    {name = "Manastone",              id = 5514,  icon = "Interface\\Icons\\INV_Misc_Gem_Sapphire_01"},
    {name = "Soulstone",              id = 5232,  icon = "Interface\\Icons\\Spell_Shadow_SoulGem"},
    {name = "Spellstone",             id = 5522,  icon = "Interface\\Icons\\INV_Misc_Gem_Sapphire_01"},
    {name = "Firestone",              id = 1254,  icon = "Interface\\Icons\\INV_Ammo_FireTar"},
    {name = "Elixir of Shadow Power", id = 9264,  icon = "Interface\\Icons\\INV_Potion_46"},
    {name = "Flask of Supreme Power", id = 13512, icon = "Interface\\Icons\\INV_Potion_41"},
}

-- Todos los IDs por familia (para contar cualquier rango)
local ITEM_FAMILIES = {
    ["Soul Shard"]             = {6265},
    ["Healthstone"]            = {5512, 19004, 19005, 5511, 5509, 5510},
    ["Manastone"]              = {5514},
    ["Soulstone"]              = {5232, 16892, 16893, 16895, 16896},
    ["Spellstone"]             = {5522, 13602, 13603},
    ["Firestone"]              = {1254, 13699, 13700, 13701},
    ["Elixir of Shadow Power"] = {9264},
    ["Flask of Supreme Power"] = {13512},
}

function WCS_ClanBank:Initialize()
    if panel then return end

    panel = CreateFrame("Frame", "WCS_ClanBankFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()

    local isES = (GetLocale() == "esES" or GetLocale() == "esMX")
    local titleText = isES and "|cffffaa00Inventario Personal|r" or "|cffffaa00Personal Inventory|r"
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText(titleText)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    -- Panel de oro — relativo al padre
    local goldBg = CreateFrame("Frame", nil, panel)
    goldBg:SetPoint("TOPLEFT", 10, -40)
    goldBg:SetPoint("TOPRIGHT", -10, -40)
    goldBg:SetHeight(60)
    local goldBgTex = goldBg:CreateTexture(nil, "BACKGROUND")
    goldBgTex:SetAllPoints()
    goldBgTex:SetTexture(0, 0, 0, 0.5)

    self.goldText = goldBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.goldText:SetPoint("CENTER", 0, 10)
    local goldLabel = isES and "Tu Oro" or "Your Gold"
    self.goldText:SetText(goldLabel .. ": |cffffaa000g 0s 0c|r")

    local refreshBtn = CreateFrame("Button", nil, goldBg)
    refreshBtn:SetPoint("BOTTOM", 0, 5)
    refreshBtn:SetWidth(120)
    refreshBtn:SetHeight(20)
    local refreshBg = refreshBtn:CreateTexture(nil, "BACKGROUND")
    refreshBg:SetAllPoints()
    refreshBg:SetTexture(0.2, 0.5, 0.2, 0.8)
    local refreshText = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    refreshText:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
    refreshText:SetText("Actualizar")
    refreshBtn:SetScript("OnClick", function()
        WCS_ClanBank:UpdateGold()
        WCS_ClanBank:UpdateItems()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[Inventario]|r Actualizado")
    end)

    -- Panel de items — columna izquierda, ancho ~310px
    local itemsBg = CreateFrame("Frame", nil, panel)
    itemsBg:SetPoint("TOPLEFT", 10, -110)
    itemsBg:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    itemsBg:SetWidth(310)
    local itemsBgTex = itemsBg:CreateTexture(nil, "BACKGROUND")
    itemsBgTex:SetAllPoints()
    itemsBgTex:SetTexture(0, 0, 0, 0.5)

    local itemsTitle = itemsBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemsTitle:SetPoint("TOP", 0, -5)
    itemsTitle:SetText("|cffFFD700Tu Inventario|r")

    -- Grid 2×4 de items (80px por slot)
    self.itemFrames = {}
    for i = 1, table.getn(TRACKED_ITEMS) do
        local item = TRACKED_ITEMS[i]
        local col = math.mod(i - 1, 2)       -- 0 ó 1 (2 columnas)
        local row = math.floor((i - 1) / 2)  -- fila

        local frame = CreateFrame("Frame", nil, itemsBg)
        frame:SetPoint("TOPLEFT", 10 + col * 145, -30 - row * 100)
        frame:SetWidth(130)
        frame:SetHeight(90)

        local frameBg = frame:CreateTexture(nil, "BACKGROUND")
        frameBg:SetAllPoints()
        frameBg:SetTexture(0.1, 0.1, 0.1, 0.8)

        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOP", 0, -5)
        icon:SetWidth(50)
        icon:SetHeight(50)
        icon:SetTexture(item.icon)

        local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameText:SetPoint("BOTTOM", 0, 20)
        nameText:SetWidth(125)
        nameText:SetText(item.name)
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 8)

        local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        countText:SetPoint("BOTTOM", 0, 5)
        countText:SetText("0")

        frame.countText  = countText
        frame.itemName   = item.name
        self.itemFrames[i] = frame
    end

    -- Panel de historial — columna derecha anclada al frame izquierdo
    local transBg = CreateFrame("Frame", nil, panel)
    transBg:SetPoint("TOPLEFT", itemsBg, "TOPRIGHT", 10, 0)
    transBg:SetPoint("BOTTOMRIGHT", -10, 10)
    local transBgTex = transBg:CreateTexture(nil, "BACKGROUND")
    transBgTex:SetAllPoints()
    transBgTex:SetTexture(0, 0, 0, 0.5)

    local transTitle = transBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    transTitle:SetPoint("TOP", 0, -5)
    transTitle:SetText("|cffFFD700Historial de Cambios|r")

    local scrollFrame = CreateFrame("ScrollFrame", "WCS_BankScrollFrame", transBg)
    scrollFrame:SetPoint("TOPLEFT", 5, -25)
    scrollFrame:SetPoint("BOTTOMRIGHT", -5, 35)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(300)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    self.transScrollChild = scrollChild
    self.transText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.transText:SetPoint("TOPLEFT", 5, -5)
    self.transText:SetWidth(290)
    self.transText:SetJustifyH("LEFT")
    self.transText:SetText("Sin cambios registrados")

    local clearBtn = CreateFrame("Button", nil, transBg)
    clearBtn:SetPoint("BOTTOM", 0, 5)
    clearBtn:SetWidth(150)
    clearBtn:SetHeight(20)
    local clearBg = clearBtn:CreateTexture(nil, "BACKGROUND")
    clearBg:SetAllPoints()
    clearBg:SetTexture(0.5, 0.2, 0.2, 0.8)
    local clearText = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearText:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearText:SetText("Limpiar Historial")
    clearBtn:SetScript("OnClick", function()
        bankData.transactions = {}
        WCS_ClanBank:UpdateTransactions()
    end)

    self.panel = panel

    panel:RegisterEvent("BAG_UPDATE")
    panel:RegisterEvent("PLAYER_MONEY")
    panel:SetScript("OnEvent", function()
        if event == "BAG_UPDATE" then
            WCS_ClanBank:UpdateItems()
        elseif event == "PLAYER_MONEY" then
            WCS_ClanBank:UpdateGold()
        end
    end)

    -- Registrar evento de addon message para WCSVault
    local vaultFrame = CreateFrame("Frame")
    vaultFrame:RegisterEvent("CHAT_MSG_ADDON")
    vaultFrame:SetScript("OnEvent", function()
        WCS_ClanBank.Vault:OnMessageReceived(arg1, arg2, arg4)
    end)

    self:UpdateGold()
    self:UpdateItems()
    self:UpdateTransactions()
end

function WCS_ClanBank:UpdateGold()
    local totalCopper = GetMoney() or 0
    local gold   = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.floor(math.mod(totalCopper, 100))
    self.goldText:SetText(string.format("Tu Oro: |cffffaa00%dg %ds %dc|r", gold, silver, copper))
end

function WCS_ClanBank:UpdateItems()
    -- Contar items por ID (más fiable que por nombre en cliente ES/EN)
    local idCounts = {}

    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    -- CORRECCIÓN: extraer itemID del link con string.find
                    local _, _, idStr = string.find(link, "item:(%d+)")
                    if idStr then
                        local id = tonumber(idStr)
                        local _, count = GetContainerItemInfo(bag, slot)
                        count = count or 1
                        idCounts[id] = (idCounts[id] or 0) + count
                    end
                end
            end
        end
    end

    -- Sumar por familia de items
    for i = 1, table.getn(self.itemFrames) do
        local frame = self.itemFrames[i]
        local family = ITEM_FAMILIES[frame.itemName] or {}
        local total = 0
        for j = 1, table.getn(family) do
            total = total + (idCounts[family[j]] or 0)
        end
        frame.countText:SetText(tostring(total))

        if total == 0 then
            frame.countText:SetTextColor(0.5, 0.5, 0.5)
        elseif total < 5 then
            frame.countText:SetTextColor(1, 0, 0)
        elseif total < 20 then
            frame.countText:SetTextColor(1, 1, 0)
        else
            frame.countText:SetTextColor(0, 1, 0)
        end
    end
end

function WCS_ClanBank:UpdateTransactions()
    if table.getn(bankData.transactions) == 0 then
        self.transText:SetText("Sin cambios registrados")
        self.transScrollChild:SetHeight(1)
        return
    end

    local text = ""
    local maxShow = math.min(20, table.getn(bankData.transactions))

    for i = table.getn(bankData.transactions), table.getn(bankData.transactions) - maxShow + 1, -1 do
        local trans = bankData.transactions[i]
        if trans then
            local color = trans.type == "gain" and "|cff00ff00" or "|cffff0000"
            text = text .. string.format("%s[%s] %s|r\n",
                color, trans.time or "--:--", trans.desc or "")
        end
    end

    self.transText:SetText(text)
    self.transScrollChild:SetHeight(math.max(1, maxShow * 15))
end

function WCS_ClanBank:Show()
    if self.panel then
        self.panel:Show()
        self:UpdateGold()
        self:UpdateItems()
        self:UpdateTransactions()
    end
end

function WCS_ClanBank:Hide()
    if self.panel then self.panel:Hide() end
end

_G["WCS_ClanBank"] = WCS_ClanBank
