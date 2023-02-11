-- This portion of the script is from NullCascade's Switchable Scriptures
local data = require("JosephMcKean.alchemistsShop.data")
local scriptureId = data.shop.daedricAlphabet.id
local openSound = data.shop.daedricAlphabet.openSound
local closeSound = data.shop.daedricAlphabet.closeSound

--- @param e activateEventData
local function onActivateScripture(e)
	if e.target.object.id == scriptureId then
		if not tes3ui.menuMode() then
			local switchNode = e.target.sceneNode.children[1]
			if switchNode.switchIndex == 0 then
				switchNode.switchIndex = 1
			else
				switchNode.switchIndex = 0
			end
			e.target.data.bookSwitchState = switchNode.switchIndex
			e.target.modified = true
			if e.target.sceneNode.children[1].switchIndex == 1 then -- the book is currently open
				tes3.playSound({ soundPath = openSound })
			else
				tes3.playSound({ soundPath = closeSound })
			end
			return false
		end
	end
end
event.register("activate", onActivateScripture, { priority = 950 }) -- higher than Book Pickup

--- @param e convertReferenceToItemEventData
local function onConvertReferenceToItem(e)
	if e.reference.object.id == scriptureId then
		e.reference.data.bookSwitchState = nil
	end
end
event.register("convertReferenceToItem", onConvertReferenceToItem)

--- @param e referenceSceneNodeCreatedEventData
local function onReferenceSceneNodeCreated(e)
	if e.reference.object.id == scriptureId then
		e.reference.sceneNode.children[1].switchIndex = 0 -- set switchNode to Closed
		e.reference.data.bookSwitchState = e.reference.sceneNode.children[1].switchIndex
		e.reference.modified = true
	end
end
event.register("referenceSceneNodeCreated", onReferenceSceneNodeCreated)
