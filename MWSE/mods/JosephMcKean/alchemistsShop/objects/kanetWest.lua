local common = require("JosephMcKean.alchemistsShop.common")
local data = require("JosephMcKean.alchemistsShop.data")
local log = require("logging.logger").new({ name = data.mod, logLevel = "DEBUG" })

local kanet ---@type tes3reference
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
		return (ref == tes3.player) or (tes3.getCurrentAIPackageId(ref) == tes3.aiPackage.follow)
	end
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
event.register("spellResist", noFriendlyShock)

---@return tes3ingredient?
local function getRandomIngred()
	if kanet.cell.region then
		local ingred = table.choice(data.kanetWest.herbsByRegion[kanet.cell.region.id:lower()])
		return ingred and tes3.getObject(ingred)
	end
end
local function randomIngredTimer()
	local kanetMobile = kanet.mobile
	local ingred = getRandomIngred()
	if ingred and kanetMobile and (kanetMobile.encumbrance.current + ingred.weight) < kanetMobile.encumbrance.base then
		tes3.addItem({ reference = kanet, item = ingred })
		tes3.playSound({ reference = kanet, sound = data.kanetWest.itemPickUpSound })
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

--[[
	Jigsaw puzzle -> Daedric Translation -> Password
]]

local function talkToKanet(message)
	local buttons = {}
	table.insert(buttons, {
		text = "StartUp()",
		callback = function()
			tes3.player.data.alchemistsShop.kanetWest.startUp = true
			tes3.setStatistic({ reference = kanet, attribute = tes3.attribute.speed, value = tes3.mobilePlayer.speed.current })
			tes3.player.data.alchemistsShop.kanetWest.follow = true
			tes3.setAIFollow({ reference = kanet, target = tes3.player })
			tes3.messageBox("Following")
		end,
		showRequirements = function()
			return not tes3.player.data.alchemistsShop.kanetWest.startUp
		end,
	})
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
	tes3.playSound({ soundPath = table.choice(data.kanetWest.talkSound) })
end
---@param e activateEventData
local function activateKanet(e)
	if common.inShop then
		if e.target == kanet and e.activator == tes3.player then
			talkToKanet("[Clang-clank-clink]")
		end
	end
end
event.register("activate", activateKanet)
--[[
    [Makes metal cling-cling sounds]
    1: startUp() TalkedToPC == 0
        ;lua tes3.player.data.alchemistsShop.kanetWest.startUp = true
        ;lua timer.start({ duration = 1, type = timer.real, callback = function() tes3.closeDialogueMenu({}) end, })
        PlaySound3D "jsmk_as_spider02"
        MessageBox "Kanet West has given you the Artificial Brilliance perk. While Kanet West is follwing you around, you gain a bonus to your intelligence and all party members are more accurate in their attacks against Dwemer constructs." "OK"
        Journal jsmk_as_kanetWest_intro 100
    2: craftBolt() TalkedToPC == 1
    3: follow() TalkedToPC == 1
    4: wait() TalkedToPC == 1
    5: openInventory() TalkedToPC == 1
    6: talk() TalkedToPC == 1
    7: quit()
]]

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
