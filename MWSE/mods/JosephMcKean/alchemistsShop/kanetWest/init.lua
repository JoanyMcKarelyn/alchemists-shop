local common = require("JosephMcKean.alchemistsShop.common")
local data = require("JosephMcKean.alchemistsShop.data")
local ui = require("JosephMcKean.alchemistsShop.kanetWest.ui")
local log = require("logging.logger").new({ name = data.mod, logLevel = "DEBUG" })

local kanet ---@type tes3reference
local this = {}
this.ref = kanet
local deadKanet ---@type tes3reference
local lastHerbCount

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

---@param e activateEventData
local function activateKanet(e)
	if common.inShop then
		if e.target == kanet and e.activator == tes3.player then
			if not tes3.player.data.alchemistsShop.kanetWest.startUp then
				ui.createPasswordMenu(kanet)
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

---@param e activateEventData
local function examineDeadKanet(e)
	if common.inShop then
		if e.target == deadKanet and e.activator == tes3.player then
			ui.talkDeadKanet(
			"\nThis is a refurbished Centurion Spider with a glass tube. It appears to be shut down. There might be a way to turn on the construct again.\n",
			deadKanet, kanet)
		end
	end
end
event.register("activate", examineDeadKanet)

local function getKanetWestRef()
	if common.inShop() then
		kanet = tes3.getReference(data.kanetWest.id)
		deadKanet = tes3.getReference(data.kanetWest.deadKanetId)
		if not tes3.player.data.alchemistsShop.kanetWest.enabled then
			if not kanet.disabled then
				kanet:disable()
			end
		end
	end
end
event.register("cellChanged", getKanetWestRef)

return this
