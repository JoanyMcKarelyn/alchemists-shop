local data = require("JosephMcKean.alchemistsShop.data")
local function randomActTimer()
	local kanetMobile = tes3.getReference(data.kanetWest.id).mobile
	local ingred = getRandomIngred()
	if ingred and kanetMobile and kanetMobile.encumbrance.current + ingred.weight < kanetMobile.encumbrance.base then
		animal:moveToAction(food, "eat", true)
		return false
	end
	timer.start({ type = timer.simulate, iterations = 1, duration = math.random(20, 40), callback = randomActTimer })
end
local function startTimers()
	if tes3.player.data.alchemistsShop.kanetWest.following then
		timer.start({ type = timer.simulate, iterations = 1, duration = math.random(5, 10), callback = randomActTimer })
	end
end
event.register("loaded", startTimers)

--[[
    Method 1:
    Upon cell changed,
    iterate over all the references in the cell,
    if the reference is a plants (use a non-configurable whitelist),
    get the ingredient inside the plant (use a non-configurable whitelist),
    store the list of ingredients in a table,
    start timer loop,
    callback is additem random ingredients from the table

    Method 2:
    start timer loop,
    callback is additem random ingredients,
    where the ingredients are predetermined using region as a criteria,
    I will need to go through the TR area to look up their flora
    but the performance is a lot better
    ]]
