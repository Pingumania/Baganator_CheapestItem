local _, A = ...

local config = {
    showCheapestItem = false, -- true to show the cheapest item, false to show cheapest stack
}

local Baganator = Baganator
local cachedItems = nil

if A:IsClassicEra() then
    Enum.ItemQuality.Common = 1
    Enum.ItemQuality.Uncommon = 2
    Enum.ItemQuality.Rare = 3
end

function A:BAG_UPDATE()
    cachedItems = nil
    Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.ItemWidgets})
end

local function ItemShouldBeIgnored(itemInfo)
    if itemInfo.sellPrice == 0 then
        return true
    end

    if itemInfo.quality > Enum.ItemQuality.Uncommon then
        return true
    end

    if itemInfo.itemType == Enum.ItemClass.Questitem or
        itemInfo.itemType == Enum.ItemClass.Key then
        return true
    end

    return false
end

local function CalculateCheapest()
    if cachedItems then
        return cachedItems
    end
    local cheapest = math.huge
    local items = {}
    local seen = {}
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and not seen[itemLink] then
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                local _, _, _, _, _, itemType, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemLink)
                itemInfo.itemType = itemType
                itemInfo.sellPrice = sellPrice
                if not ItemShouldBeIgnored(itemInfo) then
                    local price = sellPrice * itemInfo.stackCount
                    if price <= cheapest then
                        if price < cheapest then
                            items = {}
                            wipe(seen)
                        end
                        cheapest = price
                        local itemLocation = {
                            bagID = bag,
                            slotIndex = slot,
                            itemLink = itemLink,
                        }
                        table.insert(items, itemLocation)
                        seen[itemLink] = true
                    end
                end
            end
        end
    end
    cachedItems = items
    return items
end

local function onUpdate(icon, details)
    local items = CalculateCheapest()
    for _, v in ipairs(items) do
        if config.showCheapestItem then
            if details.itemLink == v.itemLink then
                return true
            end
        else
            if details.itemLocation.bagID == v.bagID and details.itemLocation.slotIndex == v.slotIndex then
                return true
            end
        end
    end
    return false
end

local function onInit(itemButton)
    local icon = itemButton:CreateTexture(nil, "OVERLAY")
    icon:SetTexture("interface\\transmogrify\\transmogrify")
    local offset = 0.005
    icon:SetTexCoord(0.533203125 + offset, 0.58203125 - offset, 0.248046875 + offset, 0.294921875 - offset)
    icon:SetSize(16, 16)
    return icon
end

function A:OnLoad()
    Baganator.API.RegisterCornerWidget("Cheapest Item", "cheapest_item", onUpdate, onInit)
end
