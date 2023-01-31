-- Print all ingredients that has restore health effect (DONE)
-- Pring all ingredients and their alchemical effects (DONE)
-- Print all Restore Health potion recipes to Alchemy Recipes.log in Corkbulb Root + Saltrice = Restore Health format
local mwseLog = require("logging.logger").new({ name = "Alchemy Recipes", logLevel = "INFO" })

local outputFile = io.open("Alchemy Recipes.md", "w")

local function log(message)
	if outputFile then
		outputFile:write(message .. "\n\n")
		outputFile:flush()
	end
end

local this = {}
this.effectIngreds = {}
--[[
    local effectIngreds = {
        [tes3.effect.drainAttribute] = {
            [tes3.attribute.strength] = {"Chokeweed"}
        }
        [tes3.effect.drainSkill] = {
            [tes3.skill.block] = {}
        } -- Drain Skill - Block: 
        [tes3.effect.restoreHealth] = {
            "Corkbulb Root", "Saltrice"
        } -- Restore Health: Corbulb Root, Saltrice, ...
        [tes3.effect.banishDaedra] = {}
    }
]]

local function printIngredsByEffect()
	for effectId, v in pairs(this.effectIngreds) do
		if not table.empty(v) then
			local effect = tes3.getMagicEffect(effectId)
			if effect then
				local effectName = effect.name
				if effect.targetsAttributes or effect.targetsSkills then
					for attrOrSkillId, vv in pairs(v) do
						if not table.empty(vv) then
							if effect.targetsAttributes then
								effectName = effect.name .. " - " .. tes3.getAttributeName(attrOrSkillId)
							elseif effect.targetsSkills then
								effectName = effect.name .. " - " .. tes3.getSkillName(attrOrSkillId)
							end
							local ingreds = ""
							for i, ingred in ipairs(vv) do
								if i == 1 then
									ingreds = ingreds .. ": " .. ingred
								else
									ingreds = ingreds .. ", " .. ingred
								end
							end
							log(effectName .. ingreds)
						end
					end
				else
					local ingreds = ""
					for i, ingred in ipairs(v) do
						if i == 1 then
							ingreds = ingreds .. ": " .. ingred
						else
							ingreds = ingreds .. ", " .. ingred
						end
					end
					log(effectName .. ingreds)
				end
			end
		end
	end
end

local function getEffects()
	for _, effectId in pairs(tes3.effect) do
		this.effectIngreds[effectId] = {}
		local magicEffect = tes3.getMagicEffect(effectId)
		if magicEffect then
			if magicEffect.targetsAttributes then
				for _, attributeId in pairs(tes3.attribute) do
					this.effectIngreds[effectId][attributeId] = {}
				end
			elseif magicEffect.targetsSkills then
				for _, skillId in pairs(tes3.skill) do
					this.effectIngreds[effectId][skillId] = {}
				end
			end
		end
	end
end

-- Script From Alchemical Knowledge
local sameIngred = {}
local function getSameIngred()
	---@param a tes3ingredient
	---@param b tes3ingredient
	---@return boolean
	local function isSame(a, b)
		return (a.id == b.id) or (a.name == b.name) or (a.icon == b.icon)
	end
	local function hasSameEffect(a, b)
		for ingreda in tes3.iterateObjects(tes3.objectType.ingredient) do
			local ingred1 = ingreda ---@type tes3ingredient
			for ingredb in tes3.iterateObjects(tes3.objectType.ingredient) do
				local ingred2 = ingredb ---@type tes3ingredient
				local sameEffects = 0
				if isSame(ingred1, ingred2) then
					for i = 1, 4 do
						if ingred1.effects[i] == ingred2.effects[i] then
							local magicEffect = tes3.getMagicEffect(ingred1.effects[i])
							if magicEffect then
								if magicEffect.targetsAttributes then
									if ingred1.effectAttributeIds[i] == ingred2.effectAttributeIds[i] then
										sameEffects = sameEffects + 1
									else
										sameEffects = 0
									end
								elseif magicEffect.targetsSkills then
									if ingred1.effectSkillIds[i] == ingred2.effectSkillIds[i] then
										sameEffects = sameEffects + 1
									else
										sameEffects = 0
									end
								else
									sameEffects = sameEffects + 1
								end
							end
						else
							sameEffects = 0
						end
					end
					if sameEffects > 0 then
						sameIngred[ingred1.id] = sameIngred[ingred1.id] or {}
						sameIngred[ingred1.id][ingred2.id] = true
					end
				end
			end
		end
	end
end

local function isSame(ingred1, ingred2)
	if sameIngred[ingred1.id] and sameIngred[ingred1.id][ingred2.id] then
		return true
	elseif sameIngred[ingred2.id] and sameIngred[ingred2.id][ingred1.id] then
		return true
	end
	return false
end

local blacklist = {
	"Girith's Guar Hide",
	"Marsus' Guar Hide",
	"Meteor Slime",
	"Muffin",
	"Poison",
	"Roland's Tear",
	"Treated Bittergreen Petals",
	"Blood of an Innocent",
	"Flaming Eye of the Lightkeeper",
	"Heart of an Innocent",
	"Heart of the Udyrfrykte",
	"Heart of the Wolf",
	"Pinetear",
}

local function toSkip(ingred)
	for _, name in ipairs(blacklist) do
		if ingred.name == name then
			return true
		end
	end
	return string.find(ingred.name, "Deprecated") or string.find(ingred.name, "DEPRECATED")
end

local function getIngredsByEffect()
	for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
		local ingred = ingredient ---@type tes3ingredient
		if not toSkip(ingred) then
			for i = 1, 4 do
				local effectId = ingred.effects[i]
				local magicEffect = tes3.getMagicEffect(effectId)
				if magicEffect then
					if magicEffect.targetsAttributes then
						local effectAttributeId = ingred.effectAttributeIds[i]
						if this.effectIngreds[effectId] and this.effectIngreds[effectId][effectAttributeId] then
							if not table.find(this.effectIngreds[effectId][effectAttributeId], ingred.name) then
								table.bininsert(this.effectIngreds[effectId][effectAttributeId], ingred.name)
							end
						end
					elseif magicEffect.targetsSkills then
						local effectSkillId = ingred.effectSkillIds[i]
						if this.effectIngreds[effectId] and this.effectIngreds[effectId][effectSkillId] then
							if not table.find(this.effectIngreds[effectId][effectSkillId], ingred.name) then
								table.bininsert(this.effectIngreds[effectId][effectSkillId], ingred.name)
							end
						end
					else
						if not table.find(this.effectIngreds[effectId], ingred.name) then
							table.bininsert(this.effectIngreds[effectId], ingred.name)
						end
					end
				end
			end
		end
	end
end

this.ingreds = {}
this.ingredNames = {}
--[[
	this.ingreds = {
		{ 
			ind = 1, 
			name = "Corkbulb Root", 
			effects = {"Restore Health", "Resist Paralysis", "Lightning Shield", "Blind"}
		}
		-- 1. Corkbulb Root: Restore Health, Resist Paralysis, Lightning Shield, Blind
	}
]]

local function getIngreds()
	local ind = 1
	for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
		local ingred = ingredient ---@type tes3ingredient
		if not toSkip(ingred) then
			local ingredName = ingred.name
			-- mwseLog:debug("%s not to skip", ingredName)
			if not this.ingredNames[ingredName] then
				this.ingreds[ind] = { ind = ind, name = ingredName, effects = {}, value = ingred.value }
				mwseLog:debug("this.ingreds[%s] = { ind = %s, name = %s, value = %s }", ind, this.ingreds[ind].ind,
				              this.ingreds[ind].name, this.ingreds[ind].value)
				this.ingredNames[ingredName] = true
				for i = 1, 4 do
					local effect = tes3.getMagicEffect(ingred.effects[i])
					mwseLog:debug("this.ingreds[%s].effects[%s] = %s", ind, i, effect and effect.name)
					if effect then
						local effectName = effect.name
						if effect.targetsAttributes then
							effectName = string.sub(effect.name, 1, string.len(effect.name) - string.len("Attribute")) ..
							             tes3.getAttributeName(ingred.effectAttributeIds[i])
						elseif effect.targetsSkills then
							effectName = string.sub(effect.name, 1, string.len(effect.name) - string.len("Skill")) ..
							             tes3.getSkillName(ingred.effectSkillIds[i])
						end
						if not table.find(this.ingreds[ind].effects, effectName) then
							table.insert(this.ingreds[ind].effects, effectName)
						end
					end
				end
			end
			ind = ind + 1
		end
	end
end

local function printIngreds()
	for ind, v in pairs(this.ingreds) do
		-- mwseLog:debug("Scanning %s %s", ind, v.name)
		local message = v.name
		for i, effect in ipairs(v.effects) do
			if i == 1 then
				message = message .. ": " .. effect
			else
				message = message .. ", " .. effect
			end
		end
		log(message)
	end
end

this.recipes = {}
--[[
	this.recipes = {
		{ 
			ind = 1, 
			ingreds = {"Corkbulb Root", "Saltrice"}, 
			effects = {"Restore Health"}
		}
		-- Corkbulb Root + Saltrice = Restore Health
	}
]]

local function getRecipes()
	local ind = 1
	local isPotion = false
	for i1, v1 in pairs(this.ingreds) do
		for i2, v2 in pairs(this.ingreds) do
			if i1 < i2 then
				-- mwseLog:debug("Checking %s + %s", v1.name, v2.name)
				local effectCount = 0
				for i = 1, 4 do
					for j = 1, 4 do
						-- mwseLog:debug("Checking %s's %s and %s's %s", v1.name, v1.effects[i], v2.name, v2.effects[j])
						if v1.effects[i] and v2.effects[j] and (v1.effects[i] == v2.effects[j]) then
							-- mwseLog:debug("A match!")
							if not this.recipes[ind] then
								this.recipes[ind] = { ind = ind, effects = {} }
							end
							table.insert(this.recipes[ind].effects, v1.effects[i])
							effectCount = effectCount + 1
							isPotion = true
						end
					end
				end
				if isPotion then
					if effectCount >= 4 then
						this.recipes[ind] = { ind = ind, effects = {} }
					else
						this.recipes[ind].ingreds = { v1.name, v2.name }
						this.recipes[ind].cost = v1.value + v2.value
						ind = ind + 1
					end
					isPotion = false
				end
			end
		end
	end
end

local function printRecipes()
	for ind, v in ipairs(this.recipes) do
		local message = ""
		local effectCount = 0
		for i, effect in ipairs(v.effects) do
			if i == 1 then
				message = effect
			else
				message = message .. " + " .. effect
			end
			effectCount = effectCount + 1
		end
		message = message .. ": " .. v.ingreds[1] .. " + " .. v.ingreds[2] .. " (" .. v.cost .. " gold)"
		log(message)
	end
end

local function onInit()
	-- getEffects()
	-- getSameIngred()
	-- getIngredsByEffect()
	-- printIngredsByEffect()
	getIngreds()
	-- printIngreds()
	getRecipes()
	printRecipes()
end
event.register("initialized", onInit)
