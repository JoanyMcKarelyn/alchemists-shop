local common = require("JosephMcKean.alchemistsShop.common")
local data = require("JosephMcKean.alchemistsShop.data")
local log = require("logging.logger").new({ name = data.mod, logLevel = "INFO" })

---@param e activateEventData
local function climbLadder(e)
	if common.inShop() then
		if e.target.id == data.shop.ladder.id then
			if e.activator.position.z < e.target.position.z then
				tes3.playSound({ soundPath = data.shop.ladder.soundPath.up })
				tes3.positionCell({
					reference = e.activator,
					cell = tes3.getCell({ id = data.shop.cellId }),
					position = data.shop.ladder.markerUp,
					teleportCompanions = false,
				})
			else
				tes3.playSound({ soundPath = data.shop.ladder.soundPath.down })
				tes3.positionCell({
					reference = e.activator,
					cell = tes3.getCell({ id = data.shop.cellId }),
					position = data.shop.ladder.markerDown.position,
					orientation = data.shop.ladder.markerDown.orientation,
					teleportCompanions = false,
				})
			end
		end
	end
end
event.register("activate", climbLadder)
