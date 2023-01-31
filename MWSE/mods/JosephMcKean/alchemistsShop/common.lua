local common = {}
local data = require("JosephMcKean.alchemistsShop.data")

function common.inShop()
	return tes3.player.cell.id == data.shop.cellId
end

return common
