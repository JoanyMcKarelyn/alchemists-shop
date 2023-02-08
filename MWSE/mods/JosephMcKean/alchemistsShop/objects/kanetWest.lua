-- This script is deprecated
local common = require("JosephMcKean.alchemistsShop.common")
local data = require("JosephMcKean.alchemistsShop.data")
local ui = require("JosephMcKean.alchemistsShop.kanetWest.ui")
local log = require("logging.logger").new({ name = data.mod, logLevel = "DEBUG" })

local kanet ---@type tes3reference
local this = {}
this.ref = kanet
local deadKanet ---@type tes3reference
local lastHerbCount

--[[
    TODO:
    - Tooltip Test
	- Foe Only shock range spell Test
	- Level Progression for Kanet West: Electricity (Striker) or Enchanting (Defense)
	- Walking sound too annoying, volume down and frequency down
	- built in Easy Escort
    - Auto night light
	- Start up ask for password
]]

---@param e spellResistEventData
local function noFriendlyShock(e)
	local function isPlayerParty(ref)
		log:debug("Checking if %s is in the player party", ref and ref.id)
		return ref and (ref == tes3.player) or (tes3.getCurrentAIPackageId(ref) == tes3.aiPackage.follow)
	end
	if tes3.player.data.alchemistsShop.kanetWest.startUp then
		if e.caster == kanet then
			if e.target and isPlayerParty(e.target) then
				local isHarmful = false
				for _, effect in ipairs(e.source.effects) do
					if not isHarmful and effect.object.isHarmful then
						isHarmful = true
					end
				end
				if isHarmful then
					e.resistedPercent = 100
				end
			end
		end
	end
end
event.register("spellResist", noFriendlyShock)

---@return tes3ingredient?
local function getRandomIngred()
	if kanet.cell.region then
		local ingred = tes3.getObject(table.choice(data.kanetWest.herbsByRegion[kanet.cell.region.id:lower()])) ---@type any
		---@cast ingred tes3ingredient?
		return ingred
	end
end

local function randomIngredTimer()
	local kanetMobile = kanet.mobile
	local ingred = getRandomIngred()
	if ingred and kanetMobile and (kanetMobile.encumbrance.current + ingred.weight) < kanetMobile.encumbrance.base then
		tes3.addItem({ reference = kanet, item = ingred })
		tes3.playSound({ reference = kanet, sound = data.kanetWest.sound.itemPickUp })
	end
end

local function startTimers()
	lastHerbCount = -1
	if tes3.player.data.alchemistsShop.kanetWest.startUp then
		timer.start({ type = timer.game, iterations = -1, duration = math.random(1, 4), callback = randomIngredTimer })
	end
end
event.register("loaded", startTimers)

---@param e uiObjectTooltipEventData
local function kanetTooltip(e)
	if not (e.reference == kanet) then
		return
	end
	if not tes3.player.data.alchemistsShop.kanetWest.startUp then
		return
	end
	local fillbarsLayout = e.tooltip:createBlock({ id = data.kanetWest.uiID.fillbarsLayout })
	fillbarsLayout.autoHeight = true
	fillbarsLayout.autoWidth = true
	fillbarsLayout.minWidth = 200
	fillbarsLayout.flowDirection = "top_to_bottom"
	fillbarsLayout.paddingAllSides = 2
	local fillbarsData = {
		{
			blockId = data.kanetWest.uiID.health,
			id = data.kanetWest.uiID.healthFillbar,
			iconId = data.kanetWest.uiID.healthIcon,
			fillbarsId = data.kanetWest.uiID.healthFillbars,
			subFillbar = data.kanetWest.uiID.energy,
			iconPath = "icons\\k\\health.tga",
			label = "Health",
			description = "Rest to restore health.",
			current = kanet.mobile.health.current,
			max = kanet.mobile.health.base,
			subBarCurrent = tes3.player.data.alchemistsShop.kanetWest.stats.energy,
			subBarMax = 100,
			color = tes3ui.getPalette(tes3.palette.healthColor), -- red
		},
		{
			blockId = data.kanetWest.uiID.magic,
			id = data.kanetWest.uiID.magicFillbar,
			iconId = data.kanetWest.uiID.magicIcon,
			fillbarsId = data.kanetWest.uiID.magicFillbars,
			subFillbar = data.kanetWest.uiID.literature,
			iconPath = "icons\\k\\magicka.tga",
			label = "Magicka",
			description = "Keep Kanet West smart by reading them more books.",
			current = kanet.mobile.magicka.current,
			max = kanet.mobile.magicka.base,
			subBarCurrent = tes3.player.data.alchemistsShop.kanetWest.stats.literacy,
			subBarMax = 100,
			color = tes3ui.getPalette(tes3.palette.magicColor), -- blue
		},
		{
			blockId = data.kanetWest.uiID.fatigue,
			id = data.kanetWest.uiID.fatigueFillbar,
			iconId = data.kanetWest.uiID.fatigueIcon,
			fillbarsId = data.kanetWest.uiID.fatigueFillbars,
			subFillbar = data.kanetWest.uiID.affection,
			iconPath = "icons\\k\\fatigue.tga",
			label = "Fatigue",
			description = "Pet Kanet West to restore fatigue.",
			current = kanet.mobile.fatigue.current,
			max = kanet.mobile.fatigue.base,
			subBarCurrent = tes3.player.data.alchemistsShop.kanetWest.stats.affection,
			subBarMax = 100,
			color = tes3ui.getPalette(tes3.palette.fatigueColor), -- green
		},
		{
			blockId = data.kanetWest.uiID.hunger,
			id = data.kanetWest.uiID.hungerFillbar,
			iconId = data.kanetWest.uiID.hungerIcon,
			fillbarsId = data.kanetWest.uiID.hungerFillbars,
			noSubFillbar = true,
			iconPath = "icons\\jsmk\\as\\hunger.dds",
			label = "Hunger",
			description = "Kanet West love herbs and teas. Keep them fueled to receive a bonus to your intelligence. Thy will eat things from their inventory.",
			current = 100 - tes3.player.data.alchemistsShop.kanetWest.stats.hunger,
			max = 100,
			color = tes3ui.getPalette(tes3.palette.healthNpcColor), -- yellow
		},
	}
	for _, fillbarData in ipairs(fillbarsData) do
		local fillbarBlock = fillbarsLayout:createRect({ id = fillbarData.blockId, color = { 0.0, 0.0, 0.0 } })
		fillbarBlock.autoWidth = true
		fillbarBlock.height = 32
		fillbarBlock.widthProportional = 1.0
		fillbarBlock.borderAllSides = 2
		fillbarBlock.alpha = 0.8
		fillbarBlock.flowDirection = "left_to_right"
		local icon = fillbarBlock:createImage({ id = fillbarData.iconId, path = fillbarData.iconPath })
		icon.borderAllSides = 2
		icon.imageScaleX = 0.8
		icon.imageScaleY = 0.8
		local fillbars = fillbarBlock:createRect({ id = fillbarData.fillbarsId, color = { 0.0, 0.0, 0.0 } })
		fillbars.widthProportional = 1.0
		fillbars.height = 32
		fillbars.borderAllSides = 2
		fillbars.alpha = 0.8
		fillbars.flowDirection = "top_to_bottom"
		local fillbar = fillbars:createFillBar({ id = fillbarData.id, current = fillbarData.current, max = fillbarData.max })
		fillbar.widthProportional = 1.0
		fillbar.height = fillbarData.noSubFillbar and 26 or 20
		-- fillbar.widget.showText = false
		fillbar.widget.fillColor = fillbarData.color
		if not fillbarData.noSubFillbar then
			local subFillbar = fillbars:createFillBar({
				id = fillbarData.subFillbarId,
				current = fillbarData.subBarCurrent,
				max = fillbarData.subBarMax,
			})
			subFillbar.widthProportional = 1.0
			subFillbar.height = 6
			subFillbar.widget.showText = false
			subFillbar.widget.fillColor = tes3ui.getPalette(tes3.palette.weaponFillColor)
		end
	end
end
event.register("uiObjectTooltip", kanetTooltip)

local function isFriendly(mobileActor)
	if mobileActor and tes3.mobilePlayer then
		for _, friendlyActor in pairs(mobileActor.friendlyActors) do
			if tes3.mobilePlayer == friendlyActor then
				return true
			end
		end
	end
	return false
end

local function isHostile(mobileActor)
	if mobileActor and tes3.mobilePlayer then
		for _, hostileActor in pairs(mobileActor.hostileActors) do
			if tes3.mobilePlayer == hostileActor then
				return true
			end
		end
	end
	return false
end

---@param e spellCastedEventData
local function partyBuff(e)
	if e.caster == kanet then
		if e.target == kanet then
			if data.kanetWest.spells.isPartyBuff[e.source.id] then
				for _, mobileActor in pairs(tes3.findActorsInProximity({ reference = e.target, range = 4 })) do
					if isFriendly(mobileActor) then
						tes3.cast({
							reference = kanet,
							target = mobileActor,
							spell = data.kanetWest.spells.fleetFeet,
							instant = true,
							bypassResistances = true,
						})
					end
				end
			end
		end
	end
end
event.register("spellCasted", partyBuff)

---@param e spellTickEventData
local function joltingTouch(e)

	local function electricityJump(spellId)
		for _, mobileActor in pairs(tes3.findActorsInProximity({ reference = e.target, range = 4 })) do
			log:debug("Find actors in proximity of %s: %s", e.target, mobileActor.reference.id)
			if isHostile(mobileActor) then
				tes3.cast({ reference = kanet, target = mobileActor, spell = spellId, instant = false })
				return
			end
		end
	end

	if e.caster == kanet then
		if e.source.id == data.kanetWest.spells.joltingTouch01 then
			electricityJump(data.kanetWest.spells.joltingTouch02)
		end
		if e.source.id == data.kanetWest.spells.joltingTouch02 then
			electricityJump(data.kanetWest.spells.joltingTouch03)
		end
	end
end
event.register("spellTick", joltingTouch)

--[[
Today's Goals: 	
	Press enter when the password is wrong clear the field and play a failed sound
	UI Stuff
	Choose starting spells
	Maybe add a cancel button
	Testing spells
	All Spells
Future Goals:
 	Compatibility with keldium's companion leveler
	Daedric ABC Chart in Blackletter
	the Artificial Brilliance perk
	craft corkbulb bolts
]]

local function talkToKanet(message)
	local buttons = {}
	table.insert(buttons, {
		text = "Follow()",
		callback = function()
			tes3.player.data.alchemistsShop.kanetWest.follow = true
			tes3.setAIFollow({ reference = kanet, target = tes3.player })
			tes3.messageBox("Following")
		end,
		showRequirements = function()
			return tes3.player.data.alchemistsShop.kanetWest.startUp and not tes3.player.data.alchemistsShop.kanetWest.follow
		end,
	})
	table.insert(buttons, {
		text = "Wait()",
		callback = function()
			tes3.player.data.alchemistsShop.kanetWest.follow = false
			tes3.setAIWander({ reference = kanet, range = 443, idles = { 40, 30, 30, 0, 0, 0, 0, 0 } })
			tes3.messageBox("Waiting")
		end,
		showRequirements = function()
			return tes3.player.data.alchemistsShop.kanetWest.startUp and tes3.player.data.alchemistsShop.kanetWest.follow
		end,
	})
	table.insert(buttons, {
		text = "OpenInventory()",
		callback = function()
			timer.delayOneFrame(function()
				tes3.showContentsMenu({ reference = kanet })
			end)
		end,
		showRequirements = function()
			return tes3.player.data.alchemistsShop.kanetWest.startUp
		end,
	})
	tes3ui.showMessageMenu({
		header = "Kanet West",
		message = message,
		buttons = buttons,
		cancels = true,
		cancelText = "Quit()",
	})
	tes3.playSound({ reference = kanet, soundPath = table.choice(data.kanetWest.sound.talk) })
end

local function setAttributes()
	tes3.modStatistic({ attribute = tes3.attribute.intelligence, value = math.random(1, 5), reference = kanet })
	tes3.modStatistic({ attribute = tes3.attribute.willpower, value = math.random(1, 5), reference = kanet })
	tes3.modStatistic({ attribute = table.choice(tes3.attribute), value = math.random(1, 5), reference = kanet })
	tes3.modStatistic({ name = "health", value = math.round(kanet.mobile.endurance.base / 10), reference = kanet })
	if tes3.player.data.alchemistsShop.kanetWest.abilities["Machine Learning"] then
		local machineLearning = tes3.getObject(data.kanetWest.spells.machineLearning) ---@type any
		---@cast machineLearning tes3spell
		machineLearning.effects[1].min = machineLearning.effects[1].min + 1
		machineLearning.effects[1].max = machineLearning.effects[1].max + 1
		kanet.object.attacks[1].max = kanet.object.attacks[1].max + 1
		kanet.object.attacks[2].max = kanet.object.attacks[2].max + 1
		kanet.object.attacks[3].max = kanet.object.attacks[3].max + 1
	end
end

local function levelUp()
	local levelUpMenu = tes3ui.createMenu({ id = data.kanetWest.uiID.levelUpMenu, fixedFrame = true })
	local levelUpTextBlock = levelUpMenu:createBlock({ id = data.kanetWest.uiID.levelUpTextBlock })
	levelUpTextBlock.minWidth = 300
	levelUpTextBlock.autoHeight = true
	levelUpTextBlock.widthProportional = 1.0
	levelUpTextBlock.flowDirection = "top_to_bottom"
	local levelUpTextKanet = levelUpTextBlock:createLabel({
		id = data.kanetWest.uiID.levelUpTextKanet,
		text = string.format("Kanet West has ascended to Level %s", tes3.player.data.alchemistsShop.kanetWest.level),
	})
	levelUpTextKanet.widthProportional = 1.0
	levelUpTextKanet.wrapText = true
	levelUpTextKanet.justifyText = "center"
	local levelUpTextChoose = levelUpTextBlock:createLabel({
		id = data.kanetWest.uiID.levelUpTextChoose,
		text = "Choose an ability",
	})
	levelUpTextChoose.widthProportional = 1.0
	levelUpTextChoose.borderAllSides = 10
	levelUpTextChoose.wrapText = true
	levelUpTextChoose.justifyText = "center"
	local levelUpScrollPanes = levelUpMenu:createBlock({ id = data.kanetWest.uiID.levelUpScrollPanes })
	levelUpScrollPanes.flowDirection = "left_to_right"
	levelUpScrollPanes.autoWidth = true
	levelUpScrollPanes.autoHeight = true
	levelUpScrollPanes.height = 600
	levelUpScrollPanes.minWidth = 900
	levelUpScrollPanes.widthProportional = 1.0
	local levelUpShockPane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpShockPane })
	levelUpShockPane.minWidth = 300
	levelUpShockPane.borderAllSides = 5
	local levelUpEnchantPane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpEnchantPane })
	levelUpEnchantPane.minWidth = 300
	levelUpEnchantPane.borderAllSides = 5
	local levelUpPassivePane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpPassivePane })
	levelUpPassivePane.minWidth = 300
	levelUpEnchantPane.borderAllSides = 5
	for index, ability in ipairs(data.kanetWest.abilities) do
		log:debug("Creating UI ability block for %s", ability.name)
		if not tes3.player.data.alchemistsShop.kanetWest.abilities[ability.name] or ability.level <=
		tes3.player.data.alchemistsShop.kanetWest.level then
			log:debug("%s can be chosen at level %s", ability.name, tes3.player.data.alchemistsShop.kanetWest.level)
			local menu = (ability.category == "shock") and levelUpShockPane or (ability.category == "enchant") and
			             levelUpEnchantPane or levelUpPassivePane
			log:debug("Creating element in %s", menu.id)
			local abilityBlock = menu:createThinBorder({ id = "KanetWest_Ability_" .. tostring(index) })
			abilityBlock.flowDirection = "left_to_right"
			abilityBlock.autoHeight = true
			abilityBlock.widthProportional = 1
			local abilityIconBlock = abilityBlock:createBlock({ id = "KanetWest_Ability_icon_block_" .. tostring(index) })
			abilityIconBlock.autoHeight = true
			abilityIconBlock.autoWidth = true
			local abilityIcon = abilityIconBlock:createImage({
				id = "KanetWest_Ability_icon_" .. tostring(index),
				path = ability.path,
			})
			abilityIcon.absolutePosAlignX = 0.5
			abilityIcon.absolutePosAlignY = 1
			local abilityTextBlock = abilityBlock:createBlock({ id = "KanetWest_Ability_text_block_" .. tostring(index) })
			abilityTextBlock.width = 250
			abilityTextBlock.autoHeight = true
			abilityTextBlock.borderAllSides = 2
			abilityTextBlock.flowDirection = "top_to_bottom"
			local abilityLabelName = abilityTextBlock:createLabel({ text = ability.name })
			abilityLabelName.color = tes3ui.getPalette(tes3.palette.whiteColor)
			local labelDescription = abilityTextBlock:createLabel({ text = ability.description })
			labelDescription.wrapText = true
			labelDescription.widthProportional = 1.0
			if ability.cost then
				abilityTextBlock:createLabel({ text = "Cost: " .. ability.cost })
			end
			abilityBlock.consumeMouseEvents = true
			abilityBlock:register("mouseClick", function()
				tes3ui.leaveMenuMode()
				tes3ui.findMenu(data.kanetWest.uiID.levelUpMenu):destroy()
				tes3.player.data.alchemistsShop.kanetWest.abilities[ability.name] = true
				tes3.player.data.alchemistsShop.kanetWest.level = tes3.player.data.alchemistsShop.kanetWest.level + 1
				ability.callback(kanet)
				setAttributes()
				if tes3.player.data.alchemistsShop.kanetWest.level <= math.min(tes3.player.object.level, 20) then
					timer.delayOneFrame(levelUp)
				end
			end)
			menu[index] = abilityBlock
		end
	end
	tes3ui.enterMenuMode(data.kanetWest.uiID.levelUpMenu)
	tes3.playSound({ sound = "skillraise" })
end

---@param e activateEventData
local function activateKanet(e)
	if common.inShop then
		if e.target == kanet and e.activator == tes3.player then
			if not tes3.player.data.alchemistsShop.kanetWest.startUp then
				ui.createPasswordMenu()
			else
				talkToKanet("[Clang-clank-clink]")
			end
		end
	end
end
event.register("activate", activateKanet)

local function showIngredientsInTube()
	if kanet then
		local herbCount = 0
		for _, stack in pairs(kanet.object.inventory) do
			if data.kanetWest.isHerb[stack.object.id:lower()] then
				herbCount = herbCount + stack.count
			end
		end
		if herbCount ~= lastHerbCount then
			tes3.player.data.alchemistsShop.kanetWest.herbI = (herbCount >= 5)
			tes3.player.data.alchemistsShop.kanetWest.herbII = (herbCount >= 10)
			local sceneNode = kanet.sceneNode
			if sceneNode then
				local herbNodeI = sceneNode:getObjectByName(data.kanetWest.herbNodeI)
				local herbNodeII = sceneNode:getObjectByName(data.kanetWest.herbNodeII)
				herbNodeI.appCulled = not tes3.player.data.alchemistsShop.kanetWest.herbI
				herbNodeII.appCulled = not tes3.player.data.alchemistsShop.kanetWest.herbII
			end
			lastHerbCount = herbCount
		end
	end
end
event.register("simulate", showIngredientsInTube)

local function talkDeadKanet(message)

	local function wakeKanet()
		tes3.fadeOut({ duration = 0.25 })
		deadKanet:disable()
		timer.delayOneFrame(function()
			deadKanet:delete()
		end)
		kanet:enable()
		tes3.player.data.alchemistsShop.kanetWest.enabled = true
		tes3.fadeIn({ duration = 2.75 })
	end

	local function forceWakeKanet()
		tes3.cast({
			reference = deadKanet,
			target = tes3.player,
			spell = "shockball_large",
			instant = true,
			bypassResistances = true,
		})
		tes3.mobilePlayer:applyDamage({ damage = math.random(5, 15), resistAttribute = tes3.effectAttribute.resistShock })
		wakeKanet()
	end

	local buttons = {}
	table.insert(buttons, {
		text = "Try To Repair It (Armorer)",
		callback = function()
			tes3.player.data.alchemistsShop.kanetWest.pullItApartAnyway = true
			talkDeadKanet(
			"\n[Armorer 65] It seems like a power problem. But you are hesitated to pull it apart since the pieces can be very fragile and delicate.\n")
		end,
		showRequirements = function()
			return (tes3.mobilePlayer.armorer.current >= 65) and not tes3.player.data.alchemistsShop.kanetWest.pullItApartAnyway
		end,
	})
	table.insert(buttons, {
		text = "Try To Repair It (Armorer)",
		callback = function()
			tes3.playSound({ sound = "shock cast", volume = 0.5 })
			tes3.messageBox({
				message = "[Armorer - Requirement Not Met] As you start pulling the Centurion Spider apart, static charge slowly build on you. Then you see the signaling light turned on by itself.",
				buttons = { "OK" },
				callback = forceWakeKanet,
			})
		end,
		showRequirements = function()
			return tes3.mobilePlayer.armorer.current < 65 and not tes3.player.data.alchemistsShop.kanetWest.pullItApartAnyway
		end,
	})
	table.insert(buttons, {
		text = "Pull It Apart Anyway",
		callback = function()
			tes3.messageBox({
				message = "As you start pulling the Centurion Spider apart, static charge slowly build on you. Then you see the signaling light turned on by itself.",
				buttons = { "OK" },
				callback = forceWakeKanet,
			})
		end,
		showRequirements = function()
			return tes3.player.data.alchemistsShop.kanetWest.pullItApartAnyway
		end,
	})
	table.insert(buttons, {
		text = "Further Examine the Centurion Spider",
		callback = function()
			tes3.messageBox({
				message = "A closer exmaination reveals a label and four meters. The Centurion is apparently named Kanet West and it was refurbished by Athrisea Trandel and Aurelia Batienne. You have no clue what the meters are supposed to measure but you see a gold kanet icon next to the fourth bar. Maybe try fueling this robot with some kanet flowers.",
				buttons = { "OK" },
				callback = function()
					deadKanet.object.name = data.kanetWest.name
				end,
			})
			tes3.player.data.alchemistsShop.kanetWest.canFuelHerbs = true
		end,
		showRequirements = function()
			return not tes3.player.data.alchemistsShop.kanetWest.canFuelHerbs
		end,
	})
	table.insert(buttons, {
		text = "Fuel the Centurion Spider with herbs",
		callback = function()
			for _, stack in pairs(tes3.player.object.inventory) do
				local herbCount = tes3.player.data.alchemistsShop.kanetWest.herbNeeded
				if herbCount > 0 then
					if (stack.object.objectType == tes3.objectType.ingredient) and data.kanetWest.isHerb[stack.object.id:lower()] then
						if herbCount > stack.count then
							tes3.player.data.alchemistsShop.kanetWest.herbNeeded = herbCount - stack.count
							tes3.removeItem({ reference = tes3.player, item = stack.object, count = stack.count })
						else
							tes3.player.data.alchemistsShop.kanetWest.herbNeeded = 0
							tes3.removeItem({ reference = tes3.player, item = stack.object, count = herbCount })
							wakeKanet()
							return
						end
					end
				end
			end
			tes3.messageBox({ message = "The fourth meter goes up significantly but the centurion is still not responding." })
		end,
		enableRequirements = function()
			local herbCount = 0
			for _, stack in pairs(tes3.player.object.inventory) do
				if data.kanetWest.isHerb[stack.object.id:lower()] then
					herbCount = herbCount + stack.count
				end
			end
			return herbCount > 0
		end,
		showRequirements = function()
			return tes3.player.data.alchemistsShop.kanetWest.canFuelHerbs
		end,
		tooltipDisabled = { text = "You don't have any suitable herb." },
	})
	tes3ui.showMessageMenu({
		header = "Examine Shutdown Centurion Spider",
		message = message,
		buttons = buttons,
		cancels = true,
		cancelText = "Leave It Alone",
	})
end

---@param e activateEventData
local function examineDeadKanet(e)
	if common.inShop then
		if e.target == deadKanet and e.activator == tes3.player then
			talkDeadKanet(
			"\nThis is a refurbished Centurion Spider with a glass tube. It appears to be shut down. There might be a way to turn on the construct again.\n")
		end
	end
end
event.register("activate", examineDeadKanet)

local function getKanetWestRef()
	if common.inShop() then
		if not kanet then
			kanet = tes3.getReference(data.kanetWest.id)
			deadKanet = tes3.getReference(data.kanetWest.deadKanetId)
			if not tes3.player.data.alchemistsShop.kanetWest.enabled then
				if not kanet.disabled then
					kanet:disable()
				end
			end
		end
	end
end
event.register("cellChanged", getKanetWestRef)

return this
