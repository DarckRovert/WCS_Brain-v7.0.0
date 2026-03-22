--[[
    WCS_ClanBank.lua
    Inventario Personal - Tracking de recursos del brujo
]]--

WCS_ClanBank = WCS_ClanBank or {}

local panel = nil
local bankData = {
    transactions = {}
}

-- Items comunes de brujo para trackear
local TRACKED_ITEMS = {
    {name = "Soul Shard", icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02"},
    {name = "Healthstone", icon = "Interface\\Icons\\INV_Stone_04"},
    {name = "Manastone", icon = "Interface\\Icons\\INV_Misc_Gem_Sapphire_01"},
    {name = "Soulstone", icon = "Interface\\Icons\\Spell_Shadow_SoulGem"},
    {name = "Spellstone", icon = "Interface\\Icons\\INV_Misc_Gem_Sapphire_01"},
    {name = "Firestone", icon = "Interface\\Icons\\INV_Ammo_FireTar"},
    {name = "Elixir of Shadow Power", icon = "Interface\\Icons\\INV_Potion_46"},
    {name = "Flask of Supreme Power", icon = "Interface\\Icons\\INV_Potion_41"},
}

function WCS_ClanBank:Initialize()
    if panel then return end
    
    -- Asegurar Ledger DB global
    if not WCS_ClanUI_SavedVars then WCS_ClanUI_SavedVars = {} end
    if not WCS_ClanUI_SavedVars.bankLedger then
        WCS_ClanUI_SavedVars.bankLedger = { totalGold = 0, history = {} }
    end
    
    panel = CreateFrame("Frame", "WCS_ClanBankFrame", WCS_ClanUI.MainFrame.content)
    panel:SetAllPoints(WCS_ClanUI.MainFrame.content)
    panel:Hide()
    
    -- Título
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffffaa00Inventario Personal|r")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    
    -- Panel de oro (arriba)
    local goldBg = CreateFrame("Frame", nil, panel)
    goldBg:SetPoint("TOP", 0, -40)
    goldBg:SetWidth(760)
    goldBg:SetHeight(60)
    local goldBgTex = goldBg:CreateTexture(nil, "BACKGROUND")
    goldBgTex:SetAllPoints()
    goldBgTex:SetTexture(0, 0, 0, 0.5)
    
    self.goldText = goldBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.goldText:SetPoint("CENTER", 0, 10)
    self.goldText:SetText("Tu Oro: |cffffaa000g 0s 0c|r")
    
    -- Botón de actualizar
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
    
    -- Panel de items (izquierda)
    local itemsBg = CreateFrame("Frame", nil, panel)
    itemsBg:SetPoint("TOPLEFT", 10, -110)
    itemsBg:SetWidth(370)
    itemsBg:SetHeight(415)
    local itemsBgTex = itemsBg:CreateTexture(nil, "BACKGROUND")
    itemsBgTex:SetAllPoints()
    itemsBgTex:SetTexture(0, 0, 0, 0.5)
    
    local itemsTitle = itemsBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemsTitle:SetPoint("TOP", 0, -5)
    itemsTitle:SetText("|cffFFD700Tu Inventario|r")
    
    -- Grid de items
    self.itemFrames = {}
    for i = 1, table.getn(TRACKED_ITEMS) do
        local item = TRACKED_ITEMS[i]
        local row = math.mod(i-1, 4)
        local col = math.floor((i-1) / 4)
        
        local frame = CreateFrame("Frame", nil, itemsBg)
        frame:SetPoint("TOPLEFT", 10 + row*90, -30 - col*100)
        frame:SetWidth(80)
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
        nameText:SetWidth(75)
        nameText:SetText(item.name)
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 8)
        
        local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        countText:SetPoint("BOTTOM", 0, 5)
        countText:SetText("0")
        
        frame.countText = countText
        frame.itemName = item.name
        self.itemFrames[i] = frame
    end
    
    -- Botón de Lista de Materiales en el panel Izquierdo
    local matsBtn = CreateFrame("Button", nil, itemsBg)
    matsBtn:SetPoint("BOTTOM", 0, 10)
    matsBtn:SetWidth(220)
    matsBtn:SetHeight(25)
    local matsBg = matsBtn:CreateTexture(nil, "BACKGROUND")
    matsBg:SetAllPoints()
    matsBg:SetTexture(0.5, 0.1, 0.5, 0.8)
    local matsText = matsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matsText:SetPoint("CENTER", 0, 0)
    matsText:SetText("Consultar Materiales de Crafteo")
    matsBtn:SetScript("OnClick", function()
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00[Banco del Clan]|r Materiales Urgentes: Flask of Supreme Power, Elixir of Shadow Power, Stonescale Oil, Black Lotus, Arcane Crystal.")
    end)
    
    -- Panel de Libro de Cuentas del Clan (derecha)
    local ledgerBg = CreateFrame("Frame", nil, panel)
    ledgerBg:SetPoint("TOPRIGHT", -10, -110)
    ledgerBg:SetWidth(370)
    ledgerBg:SetHeight(415)
    local ledgerBgTex = ledgerBg:CreateTexture(nil, "BACKGROUND")
    ledgerBgTex:SetAllPoints()
    ledgerBgTex:SetTexture(0, 0, 0, 0.5)
    
    local ledgerTitle = ledgerBg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ledgerTitle:SetPoint("TOP", 0, -5)
    ledgerTitle:SetText("|cffFFD700Libro de Cuentas del Clan|r")
    
    self.clanGoldText = ledgerBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.clanGoldText:SetPoint("TOP", 0, -30)
    self.clanGoldText:SetText("Fondo del Clan: |cffffaa000g|r")
    
    -- Scroll frame para historial
    local scrollFrame = CreateFrame("ScrollFrame", "WCS_BankScrollFrame", ledgerBg)
    scrollFrame:SetPoint("TOPLEFT", 5, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -5, 45)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(350)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    self.transScrollChild = scrollChild
    self.transText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.transText:SetPoint("TOPLEFT", 5, -5)
    self.transText:SetWidth(340)
    self.transText:SetJustifyH("LEFT")
    self.transText:SetText("Sin transacciones registradas")
    
    -- Botones de Banco
    local btnWidth = 110
    local depositBtn = CreateFrame("Button", nil, ledgerBg)
    depositBtn:SetPoint("BOTTOMLEFT", 10, 10)
    depositBtn:SetWidth(btnWidth)
    depositBtn:SetHeight(25)
    local depositBg = depositBtn:CreateTexture(nil, "BACKGROUND")
    depositBg:SetAllPoints()
    depositBg:SetTexture(0.2, 0.5, 0.2, 0.8)
    local depositText = depositBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    depositText:SetPoint("CENTER", 0, 0)
    depositText:SetText("Depositar 10g")
    depositBtn:SetScript("OnClick", function()
        WCS_ClanBank:DepositGold(10)
    end)
    
    local loanBtn = CreateFrame("Button", nil, ledgerBg)
    loanBtn:SetPoint("BOTTOM", 0, 10)
    loanBtn:SetWidth(btnWidth)
    loanBtn:SetHeight(25)
    local loanBg = loanBtn:CreateTexture(nil, "BACKGROUND")
    loanBg:SetAllPoints()
    loanBg:SetTexture(0.5, 0.2, 0.2, 0.8)
    local loanText = loanBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    loanText:SetPoint("CENTER", 0, 0)
    loanText:SetText("Pedir Préstamo")
    loanBtn:SetScript("OnClick", function()
        WCS_ClanBank:RequestLoan(50)
    end)
    
    local syncBtn = CreateFrame("Button", nil, ledgerBg)
    syncBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    syncBtn:SetWidth(btnWidth)
    syncBtn:SetHeight(25)
    local syncBg = syncBtn:CreateTexture(nil, "BACKGROUND")
    syncBg:SetAllPoints()
    syncBg:SetTexture(0.2, 0.2, 0.8, 0.8)
    local syncText = syncBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    syncText:SetPoint("CENTER", 0, 0)
    syncText:SetText("Sincronizar")
    syncBtn:SetScript("OnClick", function()
        WCS_ClanBank:SyncBank()
    end)
    
    self.panel = panel
    
    -- Registrar evento para actualizar automáticamente
    panel:RegisterEvent("BAG_UPDATE")
    panel:RegisterEvent("PLAYER_MONEY")
    panel:RegisterEvent("CHAT_MSG_ADDON")
    panel:SetScript("OnEvent", function()
        if event == "BAG_UPDATE" then
            WCS_ClanBank:UpdateItems()
        elseif event == "PLAYER_MONEY" then
            WCS_ClanBank:UpdateGold()
        elseif event == "CHAT_MSG_ADDON" then
            WCS_ClanBank:OnAddonMessage(arg1, arg2, arg3, arg4)
        end
    end)
    
    -- Actualizar datos iniciales
    self:UpdateGold()
    self:UpdateItems()
    self:UpdateTransactions()
end

function WCS_ClanBank:UpdateGold()
    -- Obtener oro real del jugador
    local totalCopper = GetMoney()
    local gold = math.floor(totalCopper / 10000)
    local silver = math.floor(math.mod(totalCopper, 10000) / 100)
    local copper = math.mod(totalCopper, 100)
    
    self.goldText:SetText(string.format("Tu Oro: |cffffaa00%dg %ds %dc|r", gold, silver, copper))
end

function WCS_ClanBank:UpdateItems()
    -- Escanear inventario real del jugador
    local itemCounts = {}
    
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName = GetItemInfo(link)
                if itemName then
                    local _, count = GetContainerItemInfo(bag, slot)
                    count = count or 1
                    
                    -- Buscar coincidencias parciales con items trackeados
                    for i = 1, table.getn(TRACKED_ITEMS) do
                        local trackedName = TRACKED_ITEMS[i].name
                        if string.find(itemName, trackedName) or string.find(trackedName, itemName) then
                            itemCounts[trackedName] = (itemCounts[trackedName] or 0) + count
                        end
                    end
                end
            end
        end
    end
    
    -- Actualizar frames
    for i = 1, table.getn(self.itemFrames) do
        local frame = self.itemFrames[i]
        local count = itemCounts[frame.itemName] or 0
        frame.countText:SetText(tostring(count))
        
        -- Color según cantidad
        if count == 0 then
            frame.countText:SetTextColor(0.5, 0.5, 0.5)
        elseif count < 5 then
            frame.countText:SetTextColor(1, 0, 0)
        elseif count < 20 then
            frame.countText:SetTextColor(1, 1, 0)
        else
            frame.countText:SetTextColor(0, 1, 0)
        end
    end
end

function WCS_ClanBank:UpdateTransactions()
    local ledger = WCS_ClanUI_SavedVars.bankLedger
    if not ledger then return end
    
    if self.clanGoldText then
        self.clanGoldText:SetText("Fondo del Clan: |cffffaa00" .. ledger.totalGold .. "g|r")
    end
    
    if table.getn(ledger.history) == 0 then
        self.transText:SetText("Sin transacciones registradas")
        self.transScrollChild:SetHeight(1)
        return
    end
    
    local text = ""
    local maxShow = math.min(50, table.getn(ledger.history))
    
    -- Mostrar del más reciente al más antiguo
    for i = table.getn(ledger.history), table.getn(ledger.history) - maxShow + 1, -1 do
        local trans = ledger.history[i]
        if trans then
            local color = string.find(trans, "DEPOSITO") and "|cff00ff00" or "|cffff0000"
            if string.find(trans, "SYNC") then color = "|cffaaaaaa" end
            text = text .. color .. trans .. "|r\n"
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

function WCS_ClanBank:LogTransaction(msg)
    if not WCS_ClanUI_SavedVars.bankLedger then return end
    local timeStr = date("%H:%M")
    table.insert(WCS_ClanUI_SavedVars.bankLedger.history, "[" .. timeStr .. "] " .. msg)
    -- Límite de 100
    if table.getn(WCS_ClanUI_SavedVars.bankLedger.history) > 100 then
        table.remove(WCS_ClanUI_SavedVars.bankLedger.history, 1)
    end
    self:UpdateTransactions()
end

function WCS_ClanBank:DepositGold(amount)
    local player = UnitName("player")
    SendAddonMessage("WCSVault", "DEPOSIT:" .. amount .. ":" .. player, "GUILD")
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Vault]|r Has depositado " .. amount .. "g en el libro.")
end

function WCS_ClanBank:RequestLoan(amount)
    local player = UnitName("player")
    SendAddonMessage("WCSVault", "LOAN:" .. amount .. ":" .. player, "GUILD")
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Vault]|r Solicitaste un préstamo de " .. amount .. "g.")
end

function WCS_ClanBank:SyncBank()
    local ledger = WCS_ClanUI_SavedVars.bankLedger
    SendAddonMessage("WCSVault", "SYNC_REQ:" .. ledger.totalGold, "GUILD")
    DEFAULT_CHAT_FRAME:AddMessage("|cff9370DB[Vault]|r Solicitando sincronización de fondos...")
end

function WCS_ClanBank:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "WCSVault" then return end
    
    local ledger = WCS_ClanUI_SavedVars.bankLedger
    if not ledger then return end
    
    local args = {}
    for word in string.gfind(message, "[^:]+") do
        table.insert(args, word)
    end
    
    local action = args[1]
    
    if action == "DEPOSIT" then
        local amount = tonumber(args[2] or "0")
        local player = args[3] or "Desconocido"
        ledger.totalGold = ledger.totalGold + amount
        self:LogTransaction("DEPOSITO: " .. player .. " (+" .. amount .. "g)")
        
    elseif action == "LOAN" then
        local amount = tonumber(args[2] or "0")
        local player = args[3] or "Desconocido"
        ledger.totalGold = ledger.totalGold - amount
        self:LogTransaction("PRESTAMO: " .. player .. " (-" .. amount .. "g)")
        
    elseif action == "SYNC_REQ" then
        local remoteGold = tonumber(args[2] or "0")
        if ledger.totalGold > remoteGold then
            SendAddonMessage("WCSVault", "SYNC_RES:" .. ledger.totalGold, "GUILD")
        end
        
    elseif action == "SYNC_RES" then
        local remoteGold = tonumber(args[2] or "0")
        if remoteGold > ledger.totalGold then
            local diff = remoteGold - ledger.totalGold
            ledger.totalGold = remoteGold
            self:LogTransaction("SYNC: Actualizado desde red (+" .. diff .. "g)")
        end
    end
    
    if self.panel and self.panel:IsVisible() then
        self:UpdateTransactions()
    end
end

