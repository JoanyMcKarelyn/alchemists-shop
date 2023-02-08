local data = require("JosephMcKean.alchemistsShop.data")
local log = require("logging.logger").new({ name = data.mod, logLevel = "DEBUG" })

local this = {}

local deadKanet
local kanet

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
	levelUpScrollPanes.autoHeight = true
	levelUpScrollPanes.minWidth = 950
	levelUpScrollPanes.widthProportional = 1.0
	local levelUpShockPane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpShockPane })
	levelUpShockPane.maxWidth = 310
	levelUpShockPane.minHeight = 600
	levelUpShockPane.borderAllSides = 5
	local levelUpEnchantPane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpEnchantPane })
	levelUpEnchantPane.maxWidth = 310
	levelUpEnchantPane.minHeight = 600
	levelUpEnchantPane.borderAllSides = 5
	local levelUpPassivePane = levelUpScrollPanes:createVerticalScrollPane({ id = data.kanetWest.uiID.levelUpPassivePane })
	levelUpPassivePane.maxWidth = 310
	levelUpPassivePane.minHeight = 600
	levelUpPassivePane.borderAllSides = 5
	for index, ability in ipairs(data.kanetWest.abilities) do
		log:debug("Creating UI ability block for %s", ability.name)
		if (not tes3.player.data.alchemistsShop.kanetWest.abilities[ability.name]) or
		(ability.level <= tes3.player.data.alchemistsShop.kanetWest.level) then
			local menu = (ability.category == "shock") and levelUpShockPane or (ability.category == "enchant") and
			             levelUpEnchantPane or levelUpPassivePane
			local abilityBlock = menu:createThinBorder({ id = "KanetWest_Ability_" .. tostring(index) })
			abilityBlock.borderAllSides = 2
			abilityBlock.paddingAllSides = 2
			abilityBlock.flowDirection = "left_to_right"
			abilityBlock.autoHeight = true
			abilityBlock.widthProportional = 1
			local abilityIconBlock = abilityBlock:createBlock({ id = "KanetWest_Ability_icon_block_" .. tostring(index) })
			abilityIconBlock.minWidth = 26
			abilityIconBlock.autoWidth = true
			abilityIconBlock.heightProportional = 1
			local abilityIcon = abilityIconBlock:createImage({
				id = "KanetWest_Ability_icon_" .. tostring(index),
				path = ability.path,
			})
			abilityIcon.absolutePosAlignX = 0.5
			abilityIcon.absolutePosAlignY = 0.1
			local abilityTextBlock = abilityBlock:createBlock({ id = "KanetWest_Ability_text_block_" .. tostring(index) })
			abilityTextBlock.width = 240
			abilityTextBlock.autoHeight = true
			abilityTextBlock.borderAllSides = 2
			abilityTextBlock.paddingBottom = 2
			abilityTextBlock.flowDirection = "top_to_bottom"
			local abilityLabelName = abilityTextBlock:createLabel({ text = ability.name })
			abilityLabelName.color = tes3ui.getPalette(tes3.palette.whiteColor)
			local labelDescription = abilityTextBlock:createLabel({ text = ability.description })
			labelDescription.wrapText = true
			labelDescription.widthProportional = 1.0
			local costLabel
			if ability.cost then
				costLabel = abilityTextBlock:createLabel({ text = "Cost: " .. ability.cost })
			end
			abilityBlock.consumeMouseEvents = true
			log:debug("abilityBlock.consumeMouseEvents = %s", abilityBlock.consumeMouseEvents)
			abilityBlock:register("mouseOver", function()
				labelDescription.color = tes3ui.getPalette(tes3.palette.whiteColor)
				if costLabel then
					costLabel.color = tes3ui.getPalette(tes3.palette.whiteColor)
				end
				levelUpMenu:updateLayout()
			end)
			abilityBlock:register("mouseLeave", function()
				labelDescription.color = tes3ui.getPalette(tes3.palette.normalColor)
				if costLabel then
					costLabel.color = tes3ui.getPalette(tes3.palette.normalColor)
				end
				levelUpMenu:updateLayout()
			end)
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
			log:debug("abilityBlock:register(mouseClick)")
		end
	end
	log:debug("Finished looping through the abilities table")
	tes3ui.enterMenuMode(data.kanetWest.uiID.levelUpMenu)
	tes3.playSound({ sound = "skillraise" })
end

function this.createPasswordMenu(kanet)
	kanet = kanet
	local passwordMenu = tes3ui.createMenu({ id = data.kanetWest.uiID.passwordMenuId, fixedFrame = true })
	passwordMenu.minWidth = 400
	local passwordMenuLabelHello = passwordMenu:createLabel({
		id = data.kanetWest.uiID.passwordMenuLabelHello,
		text = "Hello, Athrisea.",
	})
	passwordMenuLabelHello.color = tes3ui.getPalette(tes3.palette.headerColor)
	passwordMenuLabelHello.borderAllSides = 10
	passwordMenuLabelHello.wrapText = true
	passwordMenuLabelHello.justifyText = "center"
	local passwordMenuLabelMay = passwordMenu:createLabel({
		id = data.kanetWest.uiID.passwordMenuLabelMay,
		text = "May I have your password please?",
	})
	passwordMenuLabelMay.borderAllSides = 10
	passwordMenuLabelMay.wrapText = true
	passwordMenuLabelMay.justifyText = "center"
	local passwordMenuBorder = passwordMenu:createThinBorder({ id = data.kanetWest.uiID.passwordMenuBorder })
	passwordMenuBorder.height = 30
	passwordMenuBorder.width = 300
	passwordMenuBorder.absolutePosAlignX = 0.5
	passwordMenuBorder.borderAllSides = 10
	passwordMenuBorder.borderBottom = 20
	passwordMenuBorder.paddingAllSides = 5
	passwordMenuBorder.paddingLeft = 8
	passwordMenuBorder.consumeMouseEvents = true
	local passwordTextInput = passwordMenuBorder:createTextInput({ id = data.kanetWest.uiID.passwordTextInput })
	passwordTextInput.color = tes3ui.getPalette(tes3.palette.whiteColor)
	passwordTextInput.absolutePosAlignX = 0.5
	passwordTextInput.absolutePosAlignY = 0.5
	passwordTextInput.font = 2
	passwordTextInput.consumeMouseEvents = false
	passwordTextInput:register("keyEnter", function(e)
		-- Correct!
		if passwordTextInput.text:lower() == "flowerpot" then
			tes3ui.acquireTextInput(nil)
			tes3.playSound({ reference = kanet, soundPath = data.kanetWest.sound.startUp, volume = 0.9, pitch = 0.9 })
			tes3ui.leaveMenuMode()
			tes3ui.findMenu(data.kanetWest.uiID.passwordMenuId):destroy()
			tes3.player.data.alchemistsShop.kanetWest.startUp = true
			tes3.setStatistic({ reference = kanet, attribute = tes3.attribute.speed, value = tes3.mobilePlayer.speed.base })
			tes3.player.data.alchemistsShop.kanetWest.follow = true
			tes3.setAIFollow({ reference = kanet, target = tes3.player })
			timer.delayOneFrame(function()
				if tes3.player.data.alchemistsShop.kanetWest.level <= math.min(tes3.player.object.level, 20) then
					levelUp()
				end
				timer.delayOneFrame(function()
					tes3.messageBox({
						message = "Kanet West has given you the Artificial Brilliance perk. While Kanet West is follwing you around, you gain a bonus to your intelligence and all party members are more accurate in their attacks against Dwemer constructs.",
						buttons = { "OK" },
						callback = function()
							tes3.messageBox("Following")
							tes3.updateJournal({ id = data.journal.intro, index = 100, showMessage = true })
						end,
					})
				end)
			end)
		else
			passwordTextInput.text = ""
			tes3.playSound({ reference = kanet, soundPath = data.kanetWest.sound.wrongPassword })
			tes3ui.acquireTextInput(passwordTextInput)
		end
	end)
	passwordMenuBorder:register("mouseClick", function()
		tes3ui.acquireTextInput(passwordTextInput)
	end)
	tes3ui.acquireTextInput(passwordTextInput)
	local passwordMenuCancel = passwordMenu:createButton({ id = data.kanetWest.uiID.passwordMenuCancel, text = "Quit()" })
	passwordMenuCancel.absolutePosAlignX = 0.5
	passwordMenuCancel.borderBottom = 12
	passwordMenuCancel:register("mouseClick", function()
		tes3ui.acquireTextInput(nil)
		tes3ui.leaveMenuMode()
		tes3ui.findMenu(data.kanetWest.uiID.passwordMenuId):destroy()
	end)
	tes3ui.enterMenuMode(data.kanetWest.uiID.passwordMenuId)
end

---@param message string
---@param deadKanetWest tes3reference?
function this.talkDeadKanet(message, deadKanetWest, kanetWest)

	if deadKanetWest then
		deadKanet = deadKanetWest
	end
	if kanetWest then
		kanet = kanetWest
	end

	local function wakeKanet()
		tes3.fadeOut({ duration = 0.01 })
		deadKanet:disable()
		timer.delayOneFrame(function()
			deadKanet:delete()
		end)
		kanet:enable()
		tes3.player.data.alchemistsShop.kanetWest.enabled = true
		tes3.fadeIn({ duration = 2.99 })
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
			this.talkDeadKanet(
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

return this
