local common = {}
local config = require("JosephMcKean.alchemistsShop.config")
local data = require("JosephMcKean.alchemistsShop.data")

function common.inShop()
	return tes3.player.cell.id == data.shop.cellId
end

function common.message(message, ...)
	if config.debugMessageBox then
		tes3.messageBox(string.format(message, ...))
	end
end

return common

