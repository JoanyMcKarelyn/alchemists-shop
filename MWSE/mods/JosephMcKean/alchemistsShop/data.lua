local this = {}

this.mod = "Alchemist's Shop"
local log = require("logging.logger").new({ name = this.mod, logLevel = "DEBUG" })

this.defaultPlayerData = {
	kanetWest = {
		herbNeeded = 6,
		enabled = false, -- Dead Kanet is disabled and Kanet is enabled
		startUp = false, -- begin following the player
		follow = false, -- Kanet is currently following the player
		level = 1, -- used in scripted leveling, means kanet has (level - 1) abilities chosen
		abilities = {},
		stats = {
			energy = 100, -- determines health, increased by resting
			literacy = 0, -- determines magicka, increased by reading
			affection = 0, -- determines fatigue, increased by petting 
			hunger = 0, -- determines buff, increased by feeding herbs and teas
		},
	},
	potions = {
		{ effectId = tes3.effect.restoreHealth, effectName = "Restore Health", name = "potion of restore health" },
		{ effectId = tes3.effect.restoreMagicka, effectName = "Restore magicka", name = "potion of restore magicka" },
	},
	potionNum = { "one" },
	potionRequested = {},
}

this.shop = {
	cellId = "Aurelia Batienne: Alchemist",
	daedricAlphabet = {
		id = "jsmk_sc_daedric_abcs",
		openSound = "\\jsmk\\bd\\bookOpen.wav",
		closeSound = "\\jsmk\\bd\\bookClose.wav",
	},
	ladder = {
		id = "jsmk_as_de_shack_ladder",
		markerUp = { -24.315, 45.796, 215 },
		markerDown = { position = { -19.217, -71.849, 2 }, orientation = { 0, 0, 180 } },
		soundPath = { up = "\\jsmk\\as\\ladderUp.wav", down = "\\jsmk\\as\\ladderDown.wav" },
	},
	isPasswordNote = {
		["jsmk_as_bk_flowerpot_01"] = true,
		["jsmk_as_bk_flowerpot_02"] = true,
		["jsmk_as_bk_flowerpot_03"] = true,
		["jsmk_as_bk_flowerpot_04"] = true,
	},
}
this.kanetWest = {
	deadKanetId = "jsmk_as_kanetWest_dead",
	id = "jsmk_as_kanet_west",
	name = "Kanet West",
	herbNodeI = "Herbs I",
	herbNodeII = "Herbs II",
	abilities = {
		{
			category = "shock",
			level = 1,
			name = "Dancing Bolts",
			description = "Shock Damage 12 to 20 pts in 5 ft on Target",
			cost = 5,
			path = "icons\\s\\tx_s_shock_dmg.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.dancingBolts })
				tes3.messageBox("Spell Dancing Bolts has been added.")
			end,
		},
		{
			category = "shock",
			level = 2,
			name = "Jolting Touch",
			description = "Target: Shock Damage 16 to 27 pts on Touch\nJump Target (x2): Shock Damage 12 to 20 pts",
			cost = 10,
			path = "icons\\s\\tx_s_shock_dmg.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.joltingTouch01 })
				tes3.messageBox("Spell Jolting Shock has been added.")
			end,
		},
		{
			category = "shock",
			level = 3,
			name = "Shock",
			description = "Shock Damage 17 to 24 pts in 5 ft on Target",
			cost = 15,
			path = "icons\\s\\tx_s_shock_dmg.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.shock })
				tes3.messageBox("Spell Shock has been added.")
			end,
		},
		{
			category = "enchant",
			level = 2,
			name = "Fleet Feet",
			description = "Fortify Agility 5 pts for 30 secs on Party\nFortify Speed 5 pts for 30 secs on Party",
			cost = 10,
			path = "icons\\s\\tx_s_ftfy_attrib.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.fleetingFeet })
				tes3.messageBox("Spell Fleet Feet has been added.")
			end,
		},
		{
			category = "enchant",
			level = 3,
			name = "Against the Elements",
			description = "Resist Fire 5 pts for 60 secs on Party\n" .. "Resist Frost 5 pts for 60 secs on Party\n" ..
			"Resist Shock 5 pts for 60 secs on Party\n" .. "Resist Poison 5 pts for 60 secs on Party",
			cost = 15,
			path = "icons\\s\\tx_s_rst_fire.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.againstTheElements })
				tes3.messageBox("Spell Against the Elements has been added.")
			end,
		},
		{
			category = "passive",
			level = 1,
			name = "Fast Runner",
			description = "Increases Kanet West's Speed",
			path = "icons\\s\\tx_s_ftfy_attrib.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.fastRunner })
				tes3.messageBox("Ability Fast Runner has been added.")
			end,
		},
		{
			category = "passive",
			level = 2,
			name = "Machine Learning",
			description = "Gain scaling Fortify Attack effect and Damage as Kanet West levels",
			path = "icons\\s\\tx_s_ftfy_attack.tga",
			callback = function(kanet)
				tes3.addSpell({ reference = kanet, spell = this.kanetWest.spells.machineLearning })
				tes3.messageBox("Ability Machine Learning has been added.")
			end,
		},
		{
			category = "passive",
			level = 3,
			name = "Hardcore Metal",
			description = "Grants a +15% Damage bonus with melee attack",
			path = "icons\\s\\tx_s_ftfy_attack.tga",
			callback = function(kanet)
				kanet.object.attacks[1].min = math.ceil(kanet.object.attacks[1].min * 1.15)
				kanet.object.attacks[2].min = math.ceil(kanet.object.attacks[2].min * 1.15)
				kanet.object.attacks[3].min = math.ceil(kanet.object.attacks[3].min * 1.15)
				kanet.object.attacks[1].max = math.ceil(kanet.object.attacks[1].max * 1.15)
				kanet.object.attacks[2].max = math.ceil(kanet.object.attacks[2].max * 1.15)
				kanet.object.attacks[3].max = math.ceil(kanet.object.attacks[3].max * 1.15)
			end,
		},
	},
	spells = {
		dancingBolts = "jsmk_as_kanet_shock_01",
		joltingTouch01 = "jsmk_as_kanet_shock_02_01",
		joltingTouch02 = "jsmk_as_kanet_shock_02_02",
		joltingTouch03 = "jsmk_as_kanet_shock_02_03",
		shock = "jsmk_as_kanet_shock_03",
		fleetingFeet = "jsmk_as_kanet_enchant_01",
		againstTheElements = "jsmk_as_kanet_enchant_02",
		fastRunner = "jsmk_as_kanet_passive_01",
		machineLearning = "jsmk_as_kanet_passive_02",
	},
	uiID = {
		passwordMenuId = tes3ui.registerID("KanetWest_Password"),
		passwordMenuLabelHello = tes3ui.registerID("KanetWest_Password_label_hello"),
		passwordMenuLabelMay = tes3ui.registerID("KanetWest_Password_label_may"),
		passwordMenuBorder = tes3ui.registerID("KanetWest_Password_border"),
		passwordTextInput = tes3ui.registerID("KanetWest_Password_text_input"),
		passwordMenuCancel = tes3ui.registerID("KanetWest_Password_cancel_button"),
		levelUpMenu = tes3ui.registerID("KanetWest_LevelUp"),
		levelUpTextBlock = tes3ui.registerID("KanetWest_LevelUp_text_block"),
		levelUpTextKanet = tes3ui.registerID("KanetWest_LevelUp_text_kanet"),
		levelUpTextChoose = tes3ui.registerID("KanetWest_LevelUp_text_choose"),
		levelUpScrollPanes = tes3ui.registerID("KanetWest_LevelUp_scroll_panes"),
		levelUpShockPane = tes3ui.registerID("KanetWest_LevelUp_shock_pane"),
		levelUpEnchantPane = tes3ui.registerID("KanetWest_LevelUp_enchant_pane"),
		levelUpPassivePane = tes3ui.registerID("KanetWest_LevelUp_passive_pane"),
		fillbarsLayout = tes3ui.registerID("KanetWest_fillbars_layout"),
		health = tes3ui.registerID("KanetWest_health"),
		healthFillbar = tes3ui.registerID("KanetWest_health_fillbar"),
		healthIcon = tes3ui.registerID("KanetWest_health_icon"),
		magic = tes3ui.registerID("KanetWest_magic"),
		magicFillbar = tes3ui.registerID("KanetWest_magic_fillbar"),
		magicIcon = tes3ui.registerID("KanetWest_magic_icon"),
		fatigue = tes3ui.registerID("KanetWest_fatigue"),
		fatigueFillbar = tes3ui.registerID("KanetWest_fatigue_fillbar"),
		fatigueIcon = tes3ui.registerID("KanetWest_fatigue_icon"),
		hunger = tes3ui.registerID("KanetWest_hunger"),
		hungerFillbar = tes3ui.registerID("KanetWest_hunger_fillbar"),
		hungerIcon = tes3ui.registerID("KanetWest_hunger_icon"),
	},
	sound = {
		itemPickUp = "jsmk_as_spiderMoan",
		startUp = "\\jsmk\\as\\startUp.wav",
		talk = {
			"\\jsmk\\as\\spider01.wav",
			"\\jsmk\\as\\spider02.wav",
			"\\jsmk\\as\\spider03.wav",
			"\\jsmk\\as\\spider04.wav",
			"\\jsmk\\as\\spider05.wav",
			"\\jsmk\\as\\spider21.wav",
			"\\jsmk\\as\\spider22.wav",
			"\\jsmk\\as\\spider23.wav",
			"\\jsmk\\as\\spider24.wav",
			"\\jsmk\\as\\spider25.wav",
		},
		wrongPassword = "\\jsmk\\as\\wrongPassword.wav",
	},
}
this.kanetWest.isPartyBuff = {
	[this.kanetWest.spells.fleetingFeet] = true,
	[this.kanetWest.spells.againstTheElements] = true,
}
this.kanetWest.herbsByRegion = {
	-- solstheim
	['moesring mountains region'] = {},
	['felsaad coast region'] = { "ingred_belladonna_01", "ingred_belladonna_02", "ingred_holly_01" },
	['isinfier plains region'] = { "ingred_belladonna_01", "ingred_belladonna_02", "ingred_holly_01" },
	['brodir grove region'] = { "ingred_holly_01" },
	['thirsk region'] = { "ingred_belladonna_02" },
	['hirstaang forest region'] = { "ingred_belladonna_01", "ingred_belladonna_02", "ingred_holly_01" },
	-- mournhold
	['mournhold region'] = {
		"ingred_nirthfly_stalks_01",
		"ingred_meadow_rye_01",
		"ingred_sweetpulp_01",
		"ingred_timsa-come-by_01",
		"ingred_horn_lily_bulb_01",
		"ingred_scrib_cabbage_01",
		"ingred_noble_sedge_01",
		"ingred_lloramor_spines_01",
		"ingred_golden_sedge_01",
	},
	-- vvardenfell
	['sheogorad'] = {
		"ingred_black_anther_01",
		"ingred_kresh_fiber_01",
		"ingred_marshmerrow_01",
		"ingred_saltrice_01",
		"ingred_stoneflower_petals_01",
	},
	['ashlands region'] = {
		"ingred_scathecraw_01",
		"ingred_trama_root_01",
		"ingred_fire_fern_01",
		"ingred_red_lichen_01",
		"ingred_black_lichen_01",
	},
	["azura's coast region"] = {
		"ingred_gold_kanet_01",
		"ingred_kresh_fiber_01",
		"ingred_marshmerrow_01",
		"ingred_saltrice_01",
		"ingred_stoneflower_petals_01",
	},
	['ascadian isles region'] = {
		"ingred_heather_01",
		"ingred_corkbulb_root_01",
		"ingred_gold_kanet_01",
		"ingred_willow_anther_01",
		"ingred_stoneflower_petals_01",
		"ingred_comberry_01",
	},
	['grazelands region'] = {
		"ingred_hackle-lo_leaf_01",
		"ingred_wickwheat_01",
		"ingred_marshmerrow_01",
		"ingred_saltrice_01",
		"ingred_stoneflower_petals_01",
	},
	['bitter coast region'] = {
		"ingred_luminous_russula_01",
		"ingred_marshmerrow_01",
		"ingred_bc_bungler's_bane",
		"ingred_bc_hypha_facia",
		"ingred_violet_coprinus_01",
	},
	['west gash region'] = {
		"ingred_bittergreen_petals_01",
		"ingred_roobrush_01",
		"ingred_kresh_fiber_01",
		"ingred_muck_01",
		"ingred_marshmerrow_01",
		"ingred_saltrice_01",
		"ingred_green_lichen_01",
		"ingred_stoneflower_petals_01",
	},
	['molag mar region'] = { "ingred_scathecraw_01", "ingred_trama_root_01", "ingred_fire_fern_01" },
	['red mountain region'] = { "ingred_scathecraw_01" },
	-- tamriel rebuilt
	["roth roryn region"] = {
		"t_ingflor_stinkhorn_01",
		"t_ingflor_bluefoot_01",
		"t_ingflor_templedome_01",
		"t_ingflor_aloeverapulp_01",
		"t_ingflor_blackrosepetal_01",
	},
	["velothi mountains region"] = {
		"ingred_holly_01",
		"ingred_kresh_fiber_01",
		"ingred_stoneflower_petals_01",
		"ingred_heather_01",
		"ingred_scathecraw_01",
	},
	["armun ashlands region"] = { "ingred_scathecraw_01", "ingred_trama_root_01", "ingred_fire_fern_01" },
	["aanthirin region"] = {
		"ingred_kresh_fiber_01",
		"ingred_corkbulb_root_01",
		"t_ingflor_orangemoss_01",
		"ingred_willow_anther_01",
		"ingred_stoneflower_petals_01",
		"ingred_comberry_01",
		"ingred_black_anther_01",
		"t_ingflor_bluekanet_01",
		"t_ingflor_templedome_01",
	},
	["old ebonheart region"] = {
		"ingred_stoneflower_petals_01",
		"ingred_gold_kanet_01",
		"ingred_comberry_01",
		"ingred_scrib_cabbage_01",
		"ingred_willow_anther_01",
	},
	["alt orethan region"] = {
		"ingred_comberry_01",
		"ingred_bc_spore_pod",
		"ingred_nirthfly_stalks_01",
		"ingred_corkbulb_root_01",
		"ingred_wickwheat_01",
		"ingred_stoneflower_petals_01",
		"ingred_timsa-come-by_01",
		"ingred_luminous_russula_01",
		"ingred_violet_coprinus_01",
	},
	["sundered scar region"] = {
		"ingred_bc_spore_pod",
		"ingred_bc_ampoule_pod",
		"ingred_bc_coda_flower",
		"ingred_luminous_russula_01",
		"ingred_violet_coprinus_01",
	},
	["lan orethan region"] = {
		"ingred_comberry_01",
		"ingred_corkbulb_root_01",
		"ingred_willow_anther_01",
		"ingred_stoneflower_petals_01",
		"ingred_gold_kanet_01",
		"ingred_meadow_rye_01",
		"ingred_bc_bungler's_bane",
		"ingred_heather_01",
	},
	["nedothril region"] = {
		"ingred_corkbulb_root_01",
		"ingred_comberry_01",
		"ingred_golden_sedge_01",
		"ingred_horn_lily_bulb_01",
		"ingred_saltrice_01",
	},
	["padomaic ocean region"] = {
		"ingred_meadow_rye_01",
		"ingred_willow_anther_01",
		"ingred_black_anther_01",
		"ingred_nirthfly_stalks_01",
		"ingred_kresh_fiber_01",
		"ingred_stoneflower_petals_01",
		"ingred_gold_kanet_01",
		"ingred_ash_yam_01",
		"ingred_corkbulb_root_01",
	},
	["mephalan vales region"] = {
		"ingred_kresh_fiber_01",
		"ingred_roobrush_01",
		"ingred_chokeweed_01",
		"ingred_stoneflower_petals_01",
		"t_ingflor_blackrosepetal_01",
	},
	["sacred lands region"] = {
		"ingred_wickwheat_01",
		"ingred_hackle-lo_leaf_01",
		"ingred_stoneflower_petals_01",
		"ingred_kresh_fiber_01",
		"ingred_comberry_01",
		"t_ingflor_hamumroot_01",
		"ingred_meadow_rye_01",
	},
	["molag ruhn region"] = {
		"ingred_wickwheat_01",
		"ingred_hackle-lo_leaf_01",
		"ingred_black_lichen_01",
		"ingred_kresh_fiber_01",
		"ingred_saltrice_01",
		"ingred_stoneflower_petals_01",
	},
	["boethiah's spine region"] = {
		"ingred_kresh_fiber_01",
		"ingred_chokeweed_01",
		"ingred_stoneflower_petals_01",
		"ingred_muck_01",
		"ingred_comberry_01",
		"ingred_bc_spore_pod",
		"ingred_bc_ampoule_pod",
		"ingred_bc_coda_flower",
		"ingred_bc_hypha_facia",
		"ingred_bc_bungler's_bane",
		"ingred_wickwheat_01",
	},
	["dagon urul region"] = {
		"ingred_kresh_fiber_01",
		"ingred_black_anther_01",
		"ingred_willow_anther_01",
		"ingred_gold_kanet_01",
		"ingred_muck_01",
	},
	["sea of ghosts region"] = {
		"ingred_kresh_fiber_01",
		"ingred_muck_01",
		"ingred_gold_kanet_01",
		"ingred_green_lichen_01",
		"ingred_stoneflower_petals_01",
	},
	["sunad mora region"] = {
		"ingred_chokeweed_01",
		"ingred_bittergreen_petals_01",
		"ingred_timsa-come-by_01",
		"t_ingflor_blackrosepetal_01",
		"ingred_horn_lily_bulb_01",
	},
	["telvanni isles region"] = {
		"ingred_kresh_fiber_01",
		"ingred_marshmerrow_01",
		"ingred_saltrice_01",
		"ingred_muck_01",
		"ingred_black_anther_01",
		"t_ingflor_blackrosepetal_01",
	},
	-- Shotn
	["lorchwuir hearth region"] = {
		"t_ingflor_dragynia_01",
		"t_ingfood_appleskyrim_01",
		"t_ingfood_wheat_01",
		"t_ingflor_redpoppy_01",
		"t_ingflor_persarine_01",
	},
	["vorndgad forest region"] = {
		"ingred_holly_01",
		"t_ingflor_rustrussula_01",
		"t_ingflor_vicarherb_01",
		"t_ingflor_bearclaw_01",
		"t_ingflor_honeylily_02",
		"t_ingflor_honeylily_01",
		"t_ingflor_shadowfly_01",
		"t_ingflor_shadowfly_02",
		"t_ingflor_blacksporecap_01",
		"t_ingflor_taragetis_01",
	},
	["druadach highlands region"] = {
		"t_ingfood_silverpalmfruit_01",
		"t_ingflor_vicarherb_01",
		"t_ingflor_rustrussula_01",
		"t_ingflor_aspyrtea_01",
		"t_ingflor_persarine_01",
		"t_ingflor_trembleweedsap_01",
	},
	["sundered hills region"] = {
		"t_ingflor_forsythiatrroots_01",
		"t_ingflor_trembleweedsap_01",
		"t_ingflor_aspyrtea_01",
		"t_ingflor_blacksporecap_01",
		"t_ingflor_vicarherb_01",
		"t_ingflor_rustrussula_01",
		"t_ingflor_honeylily_02",
		"t_ingflor_honeylily_01",
		"t_ingflor_shadowfly_01",
		"t_ingflor_shadowfly_02",
		"ingred_holly_01",
		"t_ingflor_bearclaw_01",
	},
	["midkarth region"] = {
		"t_ingflor_rustrussula_01",
		"t_ingflor_honeylily_02",
		"t_ingflor_honeylily_01",
		"t_ingflor_blacksporecap_01",
		"t_ingflor_taragetis_01",
		"t_ingflor_bearclaw_01",
		"t_ingfood_grapewrothgarian_01",
	},
	["falkheim region"] = {
		"t_ingflor_vicarherb_01",
		"t_ingflor_tawnyfunnelcap_01",
		"t_ingflor_rustrussula_01",
		"t_ingflor_kingbolete_01",
		"t_ingflor_bleakbell_01",
	},
}
this.kanetWest.isHerb = { ["ab_ingflor_bluekanet_01"] = true }
for _, ingreds in pairs(this.kanetWest.herbsByRegion) do
	if not table.empty(ingreds) then
		for _, ingred in pairs(ingreds) do
			if not this.kanetWest.isHerb[ingred] then
				this.kanetWest.isHerb[ingred] = true
			end
		end
	end
end

this.customerContext = { isCustomer = "jsmk_as_customer" }
this.dialogueId = {
	customerGreeting = 19743273785952331,
	sellForGold = 249706614257109147,
	haggle = 4880113071668510069,
	accept = 25994134151356712917,
	decline = 29468443208114009,
}
this.journal = { intro = "jsmk_as_kanetWest_intro" }
this.haggle = {
	bonus = { [1] = 0.15, [2] = 0.2, [3] = 0.2, [4] = 0.25 },
	penalty = { [1] = 0.05, [2] = 0.1, [3] = 0.1, [4] = 0.15 },
}

this.storeBought = {
	["Restore Health"] = {
		{ tier = 1, id = "p_restore_health_b" },
		{ tier = 2, id = "p_restore_health_c" },
		{ tier = 3, id = "p_restore_health_s" },
		{ tier = 4, id = "p_restore_health_q" },
		{ tier = 5, id = "p_restore_health_e" },
	},
}
function this.calcStoreBoughtPotions()
	for effectName, v in pairs(this.storeBought) do
		table.sort(v, function(a, b)
			return a.tier < b.tier
		end)
		for _, vv in pairs(v) do
			local potion = tes3.getObject(vv.id)
			vv.totalPoints = potion.effects[1].min * potion.effects[1].duration
			vv.value = potion.value
		end
	end
	this.storeBoughtPotionsCalced = true
end

return this
