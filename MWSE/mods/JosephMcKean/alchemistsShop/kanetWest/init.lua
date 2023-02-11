local common = require("JosephMcKean.alchemistsShop.common")
local config = require("JosephMcKean.alchemistsShop.config")
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
		return ref and (ref == tes3.player) or (tes3.getCurrentAIPackageId({ reference = ref }) == tes3.aiPackage.follow)
	end
	if tes3.player.data.alchemistsShop.kanetWest.startUp then
		if e.caster == kanet then
			if e.target and ((e.target == kanet) or isPlayerParty(e.target)) then
				local isHarmful = false
				for _, effect in ipairs(e.source.effects) do
					if not isHarmful and effect.object and effect.object.isHarmful then
						log:debug("Effect %s is Harmful", effect.object.name)
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

---@param e uiObjectTooltipEventData
local function kanetTooltip(e)
	if not (e.reference == kanet) then
		return
	end
	if not tes3.player.data.alchemistsShop.kanetWest.startUp then
		return
	end
	if kanet.mobile.isDead then
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

---@param mobileActor tes3mobileActor
---@return boolean
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
			if data.kanetWest.isPartyBuff[e.source.id] then
				for _, mobileActor in pairs(tes3.findActorsInProximity({ reference = e.target, range = 512 })) do
					if (mobileActor.reference ~= kanet) and isFriendly(mobileActor) then
						log:debug("%s is indeed friendly, casting party buff %s", mobileActor.reference.id, e.source.id)
						tes3.cast({
							reference = mobileActor,
							target = mobileActor,
							spell = e.source.id,
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

---@param e combatStartedEventData
local function combatStarted(e)
	if e.actor == kanet.mobile then
		local kanetMobile = e.actor
		if kanetMobile.combatSession then
			for buff, buffed in pairs(tes3.player.data.alchemistsShop.kanetWest.buffs) do
				if not buffed then
					common.message("Kanet casting party buff %s!", buff)
					tes3.cast({ reference = kanet, target = kanet, spell = buff, alwaysSucceeds = false })
					tes3.player.data.alchemistsShop.kanetWest.buffs[buff] = true
					timer.start({
						type = timer.simulate,
						duration = tes3.getObject(buff).effects[1].duration,
						callback = function()
							tes3.player.data.alchemistsShop.kanetWest.buffs[buff] = false
						end,
					})
				end
			end
		end
	end
end
event.register("combatStarted", combatStarted)

---@param spellId string|tes3spell
---@param fromTarget tes3reference
local function electricityJump(spellId, fromTarget)
	for _, mobileActor in pairs(tes3.findActorsInProximity({ reference = fromTarget, range = 256 })) do
		if (mobileActor.reference ~= fromTarget) and (mobileActor.reference ~= tes3.player) and
		(mobileActor.reference ~= kanet) then
			-- log:debug("Found actor in proximity of %s: %s", fromTarget, mobileActor.reference.id)
			if isHostile(mobileActor) then
				local success = tes3.cast({ reference = kanet, target = mobileActor, spell = spellId, instant = true })
				-- log:debug("%s is hostile, casting %s %s", mobileActor.reference.id, spellId, success and "success" or "failed")
				return
			else
				-- log:debug("%s is friendly, continue", mobileActor.reference.id)
			end
		end
	end
end

---@param e spellTickEventData
local function onJoltingTouch1Tick(e)
	if e.source.id == data.kanetWest.spells.joltingTouch01 then
		log:debug("%s under spell tick %s", e.target.id, e.source.id)
		electricityJump(data.kanetWest.spells.joltingTouch02, e.target)
		event.unregister("spellTick", onJoltingTouch1Tick)
	end
end
---@param e spellTickEventData
local function onJoltingTouch2Tick(e)
	if e.source.id == data.kanetWest.spells.joltingTouch02 then
		log:debug("%s under spell tick %s", e.target.id, e.source.id)
		electricityJump(data.kanetWest.spells.joltingTouch03, e.target)
		event.unregister("spellTick", onJoltingTouch2Tick)
	end
end

---@param e magicCastedEventData
local function onJoltingTouchCasted(e)
	if e.source.id == data.kanetWest.spells.joltingTouch01 then
		log:debug("%s casted %s at %s", e.caster.id, e.source.id, e.target.id)
		event.register("spellTick", onJoltingTouch1Tick)
	end
	if e.source.id == data.kanetWest.spells.joltingTouch02 then
		log:debug("%s casted %s at %s", e.caster.id, e.source.id, e.target.id)
		event.register("spellTick", onJoltingTouch2Tick)
	end
	if e.source.id == data.kanetWest.spells.joltingTouch03 then
		log:debug("%s casted %s at %s", e.caster.id, e.source.id, e.target.id)
	end
end
event.register("magicCasted", onJoltingTouchCasted)

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

--[[
███████ ███████ ███████ ███████ ███    ██ ████████ ██  █████  ██            
██      ██      ██      ██      ████   ██    ██    ██ ██   ██ ██            
█████   ███████ ███████ █████   ██ ██  ██    ██    ██ ███████ ██            
██           ██      ██ ██      ██  ██ ██    ██    ██ ██   ██ ██            
███████ ███████ ███████ ███████ ██   ████    ██    ██ ██   ██ ███████
--]]

---@param companion tes3reference
local function restoreHealthTimer(companion)
	if companion.mobile.fatigue.current < 0 then
		tes3.modStatistic({ reference = companion, name = "health", current = 1, limitToBase = true })
		timer.start({
			type = timer.simulate,
			duration = 1,
			iteration = 1,
			callback = function()
				restoreHealthTimer(companion)
			end,
		})

	end
end

local function knockOut(ref)
	tes3.player.data.alchemistsShop.kanetWest.follow = false
	tes3.setAIWander({ reference = kanet, range = 443, idles = { 40, 30, 30, 0, 0, 0, 0, 0 } })
	tes3.messageBox("Kanet West was knocked out!")
	tes3.setStatistic({ reference = ref, name = "fatigue", current = -150 })
	ref.mobile:stopCombat()
	timer.start({
		type = timer.simulate,
		duration = 1,
		iteration = 1,
		callback = function()
			restoreHealthTimer(ref)
		end,
	})
end

-- Code from JaceyS
--- @param e damageEventData
local function onDamage(e)
	if (e.reference == kanet and config.companionEssential) then
		if (e.source == "attack" and (kanet.mobile.health.current - math.abs(e.damage)) <= 1.1) then
			kanet.mobile.health.current = 1.1 + math.abs(e.damage)
			if tes3.player.data.alchemistsShop.kanetWest.follow then
				knockOut(kanet)
			end
		elseif (kanet.mobile.health.current - math.abs(e.damage) <= 1.1) then
			tes3.setStatistic({ reference = kanet, name = "health", current = kanet.mobile.health.current + math.abs(e.damage) })
			if tes3.player.data.alchemistsShop.kanetWest.follow then
				knockOut(kanet)
			end
		end
	end
end
event.register("damage", onDamage, { priority = -100 })

--[[																				 
 ██████  ██████  ███    ███ ██████   █████  ███    ██ ██  ██████  ███    ██ 
██      ██    ██ ████  ████ ██   ██ ██   ██ ████   ██ ██ ██    ██ ████   ██ 
██      ██    ██ ██ ████ ██ ██████  ███████ ██ ██  ██ ██ ██    ██ ██ ██  ██ 
██      ██    ██ ██  ██  ██ ██      ██   ██ ██  ██ ██ ██ ██    ██ ██  ██ ██ 
 ██████  ██████  ██      ██ ██      ██   ██ ██   ████ ██  ██████  ██   ████  					
]]

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

local function startTimers()
	lastHerbCount = -1
	timer.start({ type = timer.simulate, iterations = -1, duration = 0.5, callback = showIngredientsInTube })
	if tes3.player.data.alchemistsShop.kanetWest.startUp then
		timer.start({ type = timer.game, iterations = -1, duration = math.random(1, 4), callback = randomIngredTimer })
	end
end
event.register("loaded", startTimers)

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
