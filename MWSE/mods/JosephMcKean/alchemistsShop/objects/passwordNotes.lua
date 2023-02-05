local data = require("JosephMcKean.alchemistsShop.data")

---@param e activateEventData
local function blockNoteReading(e)
	if data.shop.isPasswordNote[e.target.id] then
		return false
	end
end
event.register("activate", blockNoteReading)
