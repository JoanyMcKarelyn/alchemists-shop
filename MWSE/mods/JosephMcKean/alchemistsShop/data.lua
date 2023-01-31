local this = {}

this.mod = "Alchemist's Shop"

this.shop = {
	cellId = "Aurelia Batienne: Alchemist",
	ladder = {
		id = "jsmk_as_de_shack_ladder",
		markerUp = { -24.315, 45.796, 215 },
		markerDown = { position = { -19.217, -71.849, 2 }, orientation = { 0, 0, 180 } },
		soundPath = { up = "\\jsmk\\as\\ladderUp.wav", down = "\\jsmk\\as\\ladderDown.wav" },
	},
}

this.kanetWest = { id = "jsmk_as_kanet_west" }

this.customerContext = { isCustomer = "jsmk_as_customer" }

this.dialogueId = {
	customerGreeting = 19743273785952331,
	sellForGold = 249706614257109147,
	haggle = 4880113071668510069,
	accept = 25994134151356712917,
	decline = 29468443208114009,
}

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

function this.getStoreBoughtPotionData()
	for effectName, v in pairs(this.storeBought) do
		table.sort(v, function(a, b)
			return a.tier < b.tier
		end)
		for _, vv in ipairs(v) do
			local potion = tes3.getObject(vv.id)
			vv.totalPoints = potion.effects[1].min * potion.effects[1].duration
			vv.value = potion.value
		end
	end
end

return this
