local configPath = require("JosephMcKean.alchemistsShop.data").mod
local config = require("JosephMcKean.alchemistsShop.config")

local modConfig = {}
function modConfig.onCreate(parent)
	local pane = parent:createThinBorder{}
	pane.layoutWidthFraction = 1.0
	pane.layoutHeightFraction = 1.0
	pane.paddingAllSides = 24
	pane.flowDirection = "top_to_bottom"
	mwse.mcm.createOnOffButton(pane, {
		class = "OnOffButton",
		label = "Show debug messages ingame",
		leftSide = true,
		variable = mwse.mcm.createTableVariable({
			class = "TableVariable",
			table = config,
			id = "debugMessageBox",
			defaultSetting = false,
		}),
	})
	mwse.mcm.createOnOffButton(pane, {
		class = "OnOffButton",
		label = "Essential Companion Kanet West",
		leftSide = true,
		variable = mwse.mcm.createTableVariable({
			class = "TableVariable",
			table = config,
			id = "companionEssential",
			defaultSetting = true,
		}),
	})
end
event.register("modConfigReady", function()
	mwse.registerModConfig(configPath, modConfig)
end)
