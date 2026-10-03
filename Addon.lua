local _, ns = ...

local config = {
	showCheapestItem = false, -- true to show the cheapest item, false to show cheapest stack
}

local Baganator = Baganator
local cachedItems = nil

local MAX_QUALITY = Enum.ItemQuality.Uncommon

function ns:BAG_UPDATE()
	cachedItems = nil
	Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.ItemWidgets})
end

local function ItemShouldBeIgnored(itemInfo)
	if itemInfo.sellPrice == 0 then
		return true
	end

	if itemInfo.quality > MAX_QUALITY then
		return true
	end

	if itemInfo.classID == Enum.ItemClass.Questitem or
		itemInfo.classID == Enum.ItemClass.Key then
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
				local _, _, _, _, _, _, _, _, _, _, sellPrice, classID = C_Item.GetItemInfo(itemInfo.itemID)
				if not sellPrice then
					C_Item.RequestLoadItemDataByID(itemInfo.itemID)
					return nil
				end
				itemInfo.classID = classID
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

local function OnUpdate(icon, details)
	local items = CalculateCheapest()

	if not items then
		return nil
	end

	for _, v in ipairs(items) do
		if config.showCheapestItem then
			if details.itemLink == v.itemLink then
				return true
			end
		else
			if details.itemLocation and details.itemLocation.bagID == v.bagID
				and details.itemLocation.slotIndex == v.slotIndex then
				return true
			end
		end
	end

	return false
end

local function OnInit(itemButton)
	local icon = itemButton:CreateTexture(nil, "OVERLAY")
	icon:SetAtlas("bags-junkcoin")
	icon:SetSize(16, 14)
	return icon
end

function ns:OnLoad()
	Baganator.API.RegisterCornerWidget("Cheapest Item", "cheapest_item", OnUpdate, OnInit)
end
