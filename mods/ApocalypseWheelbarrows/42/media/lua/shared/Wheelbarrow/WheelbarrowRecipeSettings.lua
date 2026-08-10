require "Wheelbarrow/WheelbarrowLogger"

WheelbarrowRecipeSettings = WheelbarrowRecipeSettings or {}

WheelbarrowRecipeSettings.SANDBOX_NAMESPACE = "ApocalypseWheelbarrows"
WheelbarrowRecipeSettings.MIN_SKILL_LEVEL = 0
WheelbarrowRecipeSettings.MAX_SKILL_LEVEL = 10
WheelbarrowRecipeSettings._registeredEvents = WheelbarrowRecipeSettings._registeredEvents or false
WheelbarrowRecipeSettings._lastSummary = WheelbarrowRecipeSettings._lastSummary or nil
WheelbarrowRecipeSettings._hasResolvedAnyRecipe = WheelbarrowRecipeSettings._hasResolvedAnyRecipe or false

WheelbarrowRecipeSettings.RECIPES = {
    craft_wheelbarrow_wood = {
        outputItem = "Wheelbarrow.WheelbarrowWood",
        { perk = "Woodwork", optionKey = "WoodRecipeWoodwork", defaultLevel = 2 },
        { perk = "Mechanics", optionKey = "WoodRecipeMechanics", defaultLevel = 0 },
        { perk = "MetalWelding", optionKey = "WoodRecipeMetalWelding", defaultLevel = 0 },
    },
    craft_wheelbarrow_mixed = {
        outputItem = "Wheelbarrow.WheelbarrowMixed",
        { perk = "Woodwork", optionKey = "ReinforcedRecipeWoodwork", defaultLevel = 4 },
        { perk = "Mechanics", optionKey = "ReinforcedRecipeMechanics", defaultLevel = 2 },
        { perk = "MetalWelding", optionKey = "ReinforcedRecipeMetalWelding", defaultLevel = 0 },
    },
    craft_wheelbarrow_metal = {
        outputItem = "Wheelbarrow.WheelbarrowMetal",
        { perk = "Woodwork", optionKey = "MetalRecipeWoodwork", defaultLevel = 0 },
        { perk = "Mechanics", optionKey = "MetalRecipeMechanics", defaultLevel = 4 },
        { perk = "MetalWelding", optionKey = "MetalRecipeMetalWelding", defaultLevel = 4 },
    },
}

local function clampLevel(value, fallback)
    local numericValue = math.floor(tonumber(value) or fallback)
    if numericValue < WheelbarrowRecipeSettings.MIN_SKILL_LEVEL then
        return WheelbarrowRecipeSettings.MIN_SKILL_LEVEL
    end
    if numericValue > WheelbarrowRecipeSettings.MAX_SKILL_LEVEL then
        return WheelbarrowRecipeSettings.MAX_SKILL_LEVEL
    end
    return numericValue
end

local function getSandboxNamespace()
    return SandboxVars and SandboxVars[WheelbarrowRecipeSettings.SANDBOX_NAMESPACE] or nil
end

local function getConfiguredLevel(requirement)
    local sandboxNamespace = getSandboxNamespace()
    local configuredValue = sandboxNamespace and sandboxNamespace[requirement.optionKey] or nil
    return clampLevel(configuredValue, requirement.defaultLevel)
end

local function getPerk(perkName)
    if not Perks then
        return nil
    end
    return Perks[perkName]
end

local function collectRecipes(target, accumulator, seen)
    if not target then
        return
    end

    for index = 0, target:size() - 1 do
        local recipe = target:get(index)
        if recipe and not seen[recipe] then
            seen[recipe] = true
            accumulator[#accumulator + 1] = recipe
        end
    end
end

local function getAllLoadedRecipes(scriptManager)
    local recipes = {}
    local seen = {}

    if scriptManager.getAllCraftRecipes then
        collectRecipes(scriptManager:getAllCraftRecipes(), recipes, seen)
    end

    if scriptManager.getAllBuildableRecipes then
        collectRecipes(scriptManager:getAllBuildableRecipes(), recipes, seen)
    end

    return recipes
end

local function recipeOutputsItem(recipe, fullType)
    if not recipe or not recipe.getOutputs or not fullType then
        return false
    end

    local outputs = recipe:getOutputs()
    if not outputs then
        return false
    end

    for index = 0, outputs:size() - 1 do
        local output = outputs:get(index)
        if output and output.getPossibleResultItems then
            local items = output:getPossibleResultItems()
            if items then
                for itemIndex = 0, items:size() - 1 do
                    local item = items:get(itemIndex)
                    if item and item.getFullName and item:getFullName() == fullType then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function resolveRecipes(scriptManager, recipeId, recipeConfig)
    local resolved = {}
    local directRecipe = scriptManager.getCraftRecipe and scriptManager:getCraftRecipe(recipeId) or nil
    if directRecipe then
        resolved[#resolved + 1] = directRecipe
        WheelbarrowLogger.debug("Resolved recipe by id " .. recipeId .. " as " .. tostring(directRecipe:getName()))
    else
        WheelbarrowLogger.debug("No direct craft recipe found for id " .. recipeId)
    end

    local outputItem = recipeConfig.outputItem
    if outputItem then
        local allRecipes = getAllLoadedRecipes(scriptManager)
        WheelbarrowLogger.debug("Scanning " .. tostring(#allRecipes) .. " loaded recipes for output " .. outputItem)
        for _, recipe in ipairs(allRecipes) do
            local alreadyIncluded = false
            for _, existing in ipairs(resolved) do
                if existing == recipe then
                    alreadyIncluded = true
                    break
                end
            end

            if not alreadyIncluded and recipeOutputsItem(recipe, outputItem) then
                resolved[#resolved + 1] = recipe
                WheelbarrowLogger.debug("Resolved recipe by output " .. outputItem .. " as " .. tostring(recipe:getName()))
            end
        end
    end

    return resolved
end

function WheelbarrowRecipeSettings.apply()
    local scriptManager = ScriptManager and ScriptManager.instance or getScriptManager and getScriptManager()
    if not scriptManager then
        WheelbarrowLogger.warn("Recipe skill override skipped: script manager unavailable")
        return
    end

    local source = getSandboxNamespace() ~= nil and "sandbox settings" or "lua defaults"
    local allSummaries = {}

    if scriptManager.getAllCraftRecipes then
        local craftRecipes = scriptManager:getAllCraftRecipes()
        WheelbarrowLogger.debug("Craft recipe pool size: " .. tostring(craftRecipes and craftRecipes:size() or 0))
    end

    if scriptManager.getAllBuildableRecipes then
        local buildableRecipes = scriptManager:getAllBuildableRecipes()
        WheelbarrowLogger.debug("Buildable recipe pool size: " .. tostring(buildableRecipes and buildableRecipes:size() or 0))
    end

    for recipeName, recipeConfig in pairs(WheelbarrowRecipeSettings.RECIPES) do
        local resolvedRecipes = resolveRecipes(scriptManager, recipeName, recipeConfig)
        if #resolvedRecipes > 0 then
            local requirements = {}
            for _, requirement in ipairs(recipeConfig) do
                requirements[#requirements + 1] = requirement
            end

            for _, recipe in ipairs(resolvedRecipes) do
                recipe:clearRequiredSkills()
            end

            local summary = {}
            for _, requirement in ipairs(requirements) do
                local perk = getPerk(requirement.perk)
                local level = getConfiguredLevel(requirement)
                if perk then
                    if level > 0 then
                        for _, recipe in ipairs(resolvedRecipes) do
                            recipe:addRequiredSkill(perk, level)
                        end
                        summary[#summary + 1] = requirement.perk .. ":" .. tostring(level)
                    else
                        summary[#summary + 1] = requirement.perk .. ":off"
                    end
                else
                    WheelbarrowLogger.error("Recipe skill override skipped unknown perk " .. tostring(requirement.perk) .. " for " .. recipeName)
                end
            end

            local resolvedNames = {}
            for _, recipe in ipairs(resolvedRecipes) do
                resolvedNames[#resolvedNames + 1] = tostring(recipe:getName())
            end

            allSummaries[#allSummaries + 1] = recipeName .. "->[" .. table.concat(resolvedNames, ",") .. "]=" .. table.concat(summary, ",")
        else
            local outputItem = recipeConfig.outputItem or "unknown output"
            local level = WheelbarrowRecipeSettings._hasResolvedAnyRecipe and WheelbarrowLogger.warn or WheelbarrowLogger.debug
            level("Recipe skill override skipped missing recipe " .. recipeName .. " for output " .. outputItem)
        end
    end

    local combinedSummary = source .. "|" .. table.concat(allSummaries, "|")
    if WheelbarrowRecipeSettings._lastSummary ~= combinedSummary then
        WheelbarrowLogger.info("Recipe requirement configuration source: " .. source)
        for _, recipeSummary in ipairs(allSummaries) do
            WheelbarrowLogger.info("Recipe requirements active for " .. recipeSummary)
        end
        WheelbarrowRecipeSettings._lastSummary = combinedSummary
    end

    if #allSummaries > 0 then
        WheelbarrowRecipeSettings._hasResolvedAnyRecipe = true
    end
end

if not WheelbarrowRecipeSettings._registeredEvents then
    if Events.OnGameBoot then
        Events.OnGameBoot.Add(function()
            WheelbarrowRecipeSettings.apply()
        end)
    end

    if Events.OnGameStart then
        Events.OnGameStart.Add(function()
            WheelbarrowRecipeSettings.apply()
        end)
    end

    if Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(function()
            WheelbarrowRecipeSettings.apply()
        end)
    end

    if isServer() and Events.OnInitGlobalModData then
        Events.OnInitGlobalModData.Add(function()
            WheelbarrowRecipeSettings.apply()
        end)
    end

    WheelbarrowRecipeSettings._registeredEvents = true
end
