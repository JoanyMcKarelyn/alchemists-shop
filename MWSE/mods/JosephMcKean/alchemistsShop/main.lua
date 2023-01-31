local data = require("JosephMcKean.alchemistsShop.data")
local mod = data.mod
local log = require("logging.logger").new({ name = mod, logLevel = "INFO" })

---@param effectName string
---@param potion tes3alchemy
---@return number?
local function getPotionBaseValue(effectName, potion)
	local effect = potion.effects[1]
	local totalPoint = effect.min * effect.duration
	local tier = 0
	for _, v in ipairs(data.storeBought[effectName]) do
		if totalPoint < v.totalPoint then
			if v.tier == 1 then
				return 0
			else
				return data.storeBought[effectName][tier].value
			end
		elseif totalPoint == v.totalPoint then
			return v.value
		else
			tier = v.tier
		end
	end
	if tier == 5 then
		return data.storeBought[effectName][tier].value
	else
		log:info("getPotionBaseValue() error")
		return nil
	end
end

---@return tes3alchemy|nil
local function getPotionBrewed(potionRequested)
	for _, itemStack in pairs(tes3.mobilePlayer.inventory) do
		if itemStack.object.objectType == tes3.objectType.alchemy then
			local potion = itemStack.object ---@type tes3alchemy
			local matched = false
			for _, effect in ipairs(potion.effects) do
				if effect and (effect.id == potionRequested.effectId) then
					matched = true
				else
					matched = false
				end
			end
			if matched then
				return potion
			end
		end
	end
	return nil
end

---@return tes3reference?
local function customerTalking()
	local menuDialog = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
	if menuDialog then
		local npc = menuDialog:getPropertyObject("PartHyperText_actor")
		if npc and npc.context[data.customerContext.isCustomer] == 1 then
			return npc
		end
	end
end

local function haggle(basePrice)
	local mercantile = tes3.mobilePlayer.mercantile.current
	local tier = 0
	local totalBonus = 0
	if mercantile >= 20 then
		tier = tier + 1
		if mercantile >= 40 then
			tier = tier + 1
			if mercantile >= 60 then
				tier = tier + 1
				if mercantile >= 80 then
					tier = tier + 1
				end
			end
		end
	end
	for i = 1, tier do
		if mercantile > math.random(101) then
			totalBonus = totalBonus + data.haggle.bonus[tier]
		else
			totalBonus = totalBonus - data.haggle.panalty[tier]
		end
	end
	return basePrice * (1 + totalBonus)
end

--- @param e infoGetTextEventData
local function greetCustomer(e)
	local customer = customerTalking()
	if customer then
		local potionRequested = tes3.player.data.alchemistsShop.potionRequested[customer.baseObject.id]
		if not potionRequested then
			potionRequested = table.choice(tes3.player.data.alchemistsShop.potions)
			-- potionNumText = table.choice(tes3.player.data.alchemistsShop.potionNum)
		end
		local potionBrewed = getPotionBrewed(potionRequested)
		local value = potionBrewed and getPotionBaseValue(potionRequested.effectName, potionBrewed)
		if e.info.id == data.dialogueId.customerGreeting then
			-- local plural = (potionNumText == "one") and "" or "s"
			-- e.text = string.format("Hello, alchemist. Do you have any %s? I need %s bottle%s.", potionRequested.name,potionNumText, plural)
			e.text = string.format("Hello, alchemist. Do you have any %s?", potionRequested.name)
			if potionBrewed then
				tes3ui.choice(string.format("[Sell for %s gold]", value), 1)
				if tes3.mobilePlayer.mercantile.current >= 20 then
					tes3ui.choice("[Haggle]", 2)
				end
			end
			tes3ui.choice("[Accept and Leave]", 3)
			tes3ui.choice("[Decline]", 4)
		elseif e.info.id == data.dialogueId.sellForGold then
			if potionBrewed then
				tes3.addItem({ reference = tes3.player, item = "gold_001", count = value, showMessage = true })
				tes3.transferItem({ from = tes3.player, to = customer, item = potionBrewed })
			end
		elseif e.info.id == data.dialogueId.haggle then
			local haggledPrice = haggle(value)
		end
	end
end

local function loadPlayerData()
	tes3.player.data.alchemistsShop = tes3.player.data.alchemistsShop or data.defaultPlayerData
end

local currentDay
local function clearCustomerData()
	local newDay = tes3.findGlobal("DaysPassed").value
	if newDay ~= currentDay then
		currentDay = newDay
		tes3.player.data.alchemistsShop.potionRequested = {}
	end
end

local function onInit()
	event.register("loaded", loadPlayerData, { priority = 73 })
	-- item scrips
	require("JosephMcKean.alchemistsShop.objects")
	-- npc scripts
	event.register("infoGetText", greetCustomer)
	event.register("cellChanged", clearCustomerData)
end
event.register("initialized", onInit)
