--[[
    WCS_DataManager.lua - Resource Intelligence v9.3.0 (Alignment)
    Compatible con Lua 5.0 (WoW 1.12 / Turtle WoW)
]]--

WCS = WCS or {}
WCS.DataManager = WCS.DataManager or {}
local DM = WCS.DataManager

DM.Items = { shards = 0, healthstones = 0, soulstones = 0 }

function DM:ScanResources()
    self.Items = { shards = 0, healthstones = 0, soulstones = 0 }
    for b = 0, 4 do for s = 1, GetContainerNumSlots(b) do
        local link = GetContainerItemLink(b, s)
        if link then
            local name = self:Normalize(link)
            if string.find(name, "Fragmento") or string.find(name, "Soul Shard") then self.Items.shards = self.Items.shards + 1
            elseif string.find(name, "Piedra de salud") or string.find(name, "Healthstone") then self.Items.healthstones = self.Items.healthstones + 1
            elseif string.find(name, "Piedra de alma") or string.find(name, "Soulstone") then self.Items.soulstones = self.Items.soulstones + 1 end
        end
    end end
    return self.Items
end

function DM:Normalize(link)
    local _, _, name = string.find(link, "%[(.+)%]")
    return name or ""
end

function DM:GetShardCount() return self.Items.shards end
function DM:HasHealthstone() return self.Items.healthstones > 0 end

-- [Turtle WoW Pet Detection]
function DM:GetPetType()
    if not UnitExists("pet") then return nil end
    local tex = GetPetActionInfo(1) -- Cleave tex check
    if tex and string.find(tex, "Cleave") then return "Felguard" end
    return "Minion"
end

WCS:Log("DataManager v9.3.0 (Hyper-Aware) Ready.")
