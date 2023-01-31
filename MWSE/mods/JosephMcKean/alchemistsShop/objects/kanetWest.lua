local data = require("JosephMcKean.alchemistsShop.data")
local kanet ---@type tes3reference
local lastHerbCount = -1

local function showIngredientsInTube()
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
event.register("simulate", showIngredientsInTube)

---@return tes3ingredient?
local function getRandomIngred()
	if kanet.cell.region then
		local ingred = table.choice(data.kanetWest.herbsByRegion[kanet.cell.region.id:lower()])
		return ingred
	end
end
local function randomIngredTimer()
	local kanetMobile = kanet.mobile
	local ingred = getRandomIngred()
	if ingred and kanetMobile and kanetMobile.encumbrance.current + ingred.weight < kanetMobile.encumbrance.base then
		tes3.addItem({ reference = kanet, item = ingred })
		tes3.playSound({ reference = kanet, sound = data.kanetWest.itemPickUpSound })
	end
end
local function startTimers()
	kanet = tes3.getReference(data.kanetWest.id)
	if tes3.player.data.alchemistsShop.kanetWest.acquinted then
		timer.start({ type = timer.game, iterations = -1, duration = math.random(1, 4), callback = randomIngredTimer })
	end
end
event.register("loaded", startTimers)
