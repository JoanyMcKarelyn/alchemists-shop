local configPath = require("JosephMcKean.alchemistsShop.data").mod
local defaultConfig = { debugMessageBox = false, companionEssential = true }

return mwse.loadConfig(configPath, defaultConfig)
