require "Wheelbarrow/WheelbarrowLogger"

WheelbarrowLeverage = WheelbarrowLeverage or {}

WheelbarrowLeverage.SANDBOX_NAMESPACE = "ApocalypseWheelbarrows"
WheelbarrowLeverage.MIN_ADVANTAGE = 1
WheelbarrowLeverage.MAX_ADVANTAGE = 10
WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY = "wb_originalWeight"
WheelbarrowLeverage.ADJUSTED_KEY = "wb_weightAdjusted"
WheelbarrowLeverage._registeredEvents = WheelbarrowLeverage._registeredEvents or false
WheelbarrowLeverage._loggedConfig = WheelbarrowLeverage._loggedConfig or false
WheelbarrowLeverage.VARIANTS = {
    WheelbarrowWood = {
        optionKey = "A01WoodAdvantage",
        defaultAdvantage = 4,
    },
    WheelbarrowMixed = {
        optionKey = "B01ReinforcedAdvantage",
        defaultAdvantage = 6,
    },
    WheelbarrowMetal = {
        optionKey = "C01MetalAdvantage",
        defaultAdvantage = 8,
    },
}
WheelbarrowLeverage.VARIANT_ORDER = {
    "WheelbarrowWood",
    "WheelbarrowMixed",
    "WheelbarrowMetal",
}

local function safeCall(target, methodName, ...)
    if target and target[methodName] then
        return target[methodName](target, ...)
    end
    return nil
end

local function toNumber(value, fallback)
    local numericValue = tonumber(value)
    if numericValue == nil then
        return fallback
    end
    return numericValue
end

local function getTextOrDefault(key, fallback)
    local translated = getText and getText(key)
    if translated and translated ~= key then
        return translated
    end
    return fallback
end

function WheelbarrowLeverage.getSandboxNamespace()
    return SandboxVars and SandboxVars[WheelbarrowLeverage.SANDBOX_NAMESPACE] or nil
end

function WheelbarrowLeverage.getSandboxAdvantage(typeName)
    local variant = WheelbarrowLeverage.VARIANTS[typeName]
    if not variant then
        return nil
    end

    local sandboxNamespace = WheelbarrowLeverage.getSandboxNamespace()
    if not sandboxNamespace then
        return nil
    end

    return sandboxNamespace[variant.optionKey]
end

function WheelbarrowLeverage.getTypeName(target)
    if not target or not target.getType then
        return nil
    end
    return target:getType()
end

function WheelbarrowLeverage.getVariant(target)
    local typeName = WheelbarrowLeverage.getTypeName(target)
    if not typeName then
        return nil
    end
    return WheelbarrowLeverage.VARIANTS[typeName]
end

function WheelbarrowLeverage.getOptionLabel(typeName)
    local labels = {
        WheelbarrowWood = "Wooden Wheelbarrow Advantage",
        WheelbarrowMixed = "Reinforced Wheelbarrow Advantage",
        WheelbarrowMetal = "Metal Wheelbarrow Advantage",
    }
    local variant = WheelbarrowLeverage.VARIANTS[typeName]
    local fallback = labels[typeName] or "Wheelbarrow Advantage"
    if not variant then
        return fallback
    end
    return getTextOrDefault("Sandbox_" .. WheelbarrowLeverage.SANDBOX_NAMESPACE .. "_" .. variant.optionKey, fallback)
end

function WheelbarrowLeverage.getOptionDescription(typeName)
    local descriptions = {
        WheelbarrowWood = "Wooden wheelbarrow leverage multiplier.",
        WheelbarrowMixed = "Reinforced wheelbarrow leverage multiplier.",
        WheelbarrowMetal = "Metal wheelbarrow leverage multiplier.",
    }
    local variant = WheelbarrowLeverage.VARIANTS[typeName]
    local fallback = descriptions[typeName] or "Wheelbarrow leverage multiplier."
    if not variant then
        return fallback
    end
    return getTextOrDefault("Sandbox_" .. WheelbarrowLeverage.SANDBOX_NAMESPACE .. "_" .. variant.optionKey .. "_tooltip", fallback)
end

function WheelbarrowLeverage.getDefaultAdvantage(target)
    local variant = WheelbarrowLeverage.getVariant(target)
    if not variant then
        return 4
    end
    return variant.defaultAdvantage
end

function WheelbarrowLeverage.getAdvantage(target)
    local typeName = WheelbarrowLeverage.getTypeName(target)
    local variant = typeName and WheelbarrowLeverage.VARIANTS[typeName] or nil
    if not variant then
        return WheelbarrowLeverage.getDefaultAdvantage(target)
    end

    local configuredValue = WheelbarrowLeverage.getSandboxAdvantage(typeName)

    local numericValue = math.floor(toNumber(configuredValue, variant.defaultAdvantage))
    if numericValue < WheelbarrowLeverage.MIN_ADVANTAGE then
        return WheelbarrowLeverage.MIN_ADVANTAGE
    end
    if numericValue > WheelbarrowLeverage.MAX_ADVANTAGE then
        return WheelbarrowLeverage.MAX_ADVANTAGE
    end
    return numericValue
end

function WheelbarrowLeverage.logConfiguration()
    if WheelbarrowLeverage._loggedConfig then
        return
    end

    local source = WheelbarrowLeverage.getSandboxNamespace() ~= nil and "sandbox settings" or "lua defaults"
    WheelbarrowLogger.info("Leverage configuration source: " .. source)
    for _, typeName in ipairs(WheelbarrowLeverage.VARIANT_ORDER) do
        WheelbarrowLogger.info(typeName .. " leverage active: " .. tostring(WheelbarrowLeverage.getAdvantage({ getType = function() return typeName end })) .. "x")
    end
    WheelbarrowLeverage._loggedConfig = true
end

function WheelbarrowLeverage.isWheelbarrowContainer(container)
    return container ~= nil
        and container.getType ~= nil
        and PFGMenu ~= nil
        and PFGMenu.typesTable ~= nil
        and PFGMenu.typesTable[container:getType()] == true
end

function WheelbarrowLeverage.getCurrentWeight(item)
    return toNumber(safeCall(item, "getActualWeight") or safeCall(item, "getWeight"), 0)
end

function WheelbarrowLeverage.getBaseWeight(item)
    if not item then
        return 0
    end

    local modData = item:getModData()
    local storedOriginalWeight = modData and modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY]
    if storedOriginalWeight ~= nil then
        return toNumber(storedOriginalWeight, WheelbarrowLeverage.getCurrentWeight(item))
    end

    return WheelbarrowLeverage.getCurrentWeight(item)
end

function WheelbarrowLeverage.getReducedWeightForTarget(baseWeight, target)
    local reducedWeight = toNumber(baseWeight, 0) / WheelbarrowLeverage.getAdvantage(target)
    if reducedWeight < 0.001 then
        return 0.001
    end
    return reducedWeight
end

function WheelbarrowLeverage.setLiveWeight(item, newWeight)
    if not item then
        return
    end

    if item.setActualWeight then
        item:setActualWeight(newWeight)
    end
    if item.setWeight then
        item:setWeight(newWeight)
    end
end

function WheelbarrowLeverage.snapshot(item)
    if not item then
        return nil
    end

    local modData = item:getModData()
    return {
        actualWeight = safeCall(item, "getActualWeight"),
        weight = safeCall(item, "getWeight"),
        originalWeight = modData and modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY] or nil,
        adjusted = modData and modData[WheelbarrowLeverage.ADJUSTED_KEY] or nil,
    }
end

function WheelbarrowLeverage.restoreSnapshot(item, snapshot)
    if not item or not snapshot then
        return
    end

    local restoredWeight = toNumber(snapshot.actualWeight, toNumber(snapshot.weight, WheelbarrowLeverage.getCurrentWeight(item)))
    WheelbarrowLeverage.setLiveWeight(item, restoredWeight)

    local modData = item:getModData()
    modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY] = snapshot.originalWeight
    modData[WheelbarrowLeverage.ADJUSTED_KEY] = snapshot.adjusted
end

function WheelbarrowLeverage.syncItemModData(item)
    if not item or not item.transmitModData then
        return
    end

    local ok, err = pcall(function()
        item:transmitModData()
    end)

    if not ok then
        WheelbarrowLogger.debug("Failed to transmit wheelbarrow item modData: " .. tostring(err))
    end
end

function WheelbarrowLeverage.applyProjectedValidationWeight(item, srcContainer, destContainer)
    if not item then
        return
    end

    local srcIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(srcContainer)
    local destIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(destContainer)
    local baseWeight = WheelbarrowLeverage.getBaseWeight(item)

    if destIsWheelbarrow and not srcIsWheelbarrow then
        WheelbarrowLeverage.setLiveWeight(item, WheelbarrowLeverage.getReducedWeightForTarget(baseWeight, destContainer))
        return
    end

    if srcIsWheelbarrow and not destIsWheelbarrow then
        WheelbarrowLeverage.setLiveWeight(item, baseWeight)
    end
end

function WheelbarrowLeverage.markAdjusted(item, originalWeight)
    if not item then
        return
    end

    local modData = item:getModData()
    local baseWeight = toNumber(originalWeight, WheelbarrowLeverage.getCurrentWeight(item))
    modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY] = baseWeight
    modData[WheelbarrowLeverage.ADJUSTED_KEY] = true
    WheelbarrowLeverage.setLiveWeight(item, WheelbarrowLeverage.getReducedWeightForTarget(baseWeight, item))
    WheelbarrowLeverage.syncItemModData(item)
    WheelbarrowLogger.debug("Adjusted " .. tostring(safeCall(item, "getFullType") or safeCall(item, "getType")) .. " from " .. tostring(baseWeight) .. " to " .. tostring(WheelbarrowLeverage.getCurrentWeight(item)))
end

function WheelbarrowLeverage.clearAdjusted(item)
    if not item then
        return
    end

    local modData = item:getModData()
    local originalWeight = modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY]
    if originalWeight ~= nil then
        WheelbarrowLeverage.setLiveWeight(item, toNumber(originalWeight, WheelbarrowLeverage.getCurrentWeight(item)))
    end
    modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY] = nil
    modData[WheelbarrowLeverage.ADJUSTED_KEY] = nil
    WheelbarrowLeverage.syncItemModData(item)
    WheelbarrowLogger.debug("Restored " .. tostring(safeCall(item, "getFullType") or safeCall(item, "getType")) .. " to " .. tostring(WheelbarrowLeverage.getCurrentWeight(item)))
end

function WheelbarrowLeverage.repairItem(item)
    if not item then
        return
    end

    local container = safeCall(item, "getContainer")
    local isInsideWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(container)
    local modData = item:getModData()
    local originalWeight = modData[WheelbarrowLeverage.ORIGINAL_WEIGHT_KEY]
    local adjusted = modData[WheelbarrowLeverage.ADJUSTED_KEY] == true

    if isInsideWheelbarrow then
        if originalWeight == nil then
            originalWeight = WheelbarrowLeverage.getCurrentWeight(item)
        end
        WheelbarrowLeverage.markAdjusted(item, originalWeight)
        return
    end

    if adjusted or originalWeight ~= nil then
        WheelbarrowLeverage.clearAdjusted(item)
    end
end

function WheelbarrowLeverage.visitContainerItems(container)
    if not container or not container.getItems then
        return
    end

    local items = container:getItems()
    if not items then
        return
    end

    for index = 0, items:size() - 1 do
        local item = items:get(index)
        WheelbarrowLeverage.repairItem(item)
        local nestedContainer = safeCall(item, "getItemContainer")
        if nestedContainer then
            WheelbarrowLeverage.visitContainerItems(nestedContainer)
        end
    end
end

function WheelbarrowLeverage.repairLocalPlayer(playerIndex)
    local resolvedPlayerIndex = playerIndex or 0
    local playerObj = getSpecificPlayer(resolvedPlayerIndex)
    if not playerObj then
        return
    end

    WheelbarrowLeverage.visitContainerItems(playerObj:getInventory())
end

if not WheelbarrowLeverage._registeredEvents then
    if Events.OnGameStart then
        Events.OnGameStart.Add(function()
            WheelbarrowLeverage.logConfiguration()
            if not isServer() then
                WheelbarrowLeverage.repairLocalPlayer(0)
            end
        end)
    end

    if isServer() and Events.OnInitGlobalModData then
        Events.OnInitGlobalModData.Add(function()
            WheelbarrowLeverage.logConfiguration()
        end)
    end

    WheelbarrowLeverage._registeredEvents = true
end
