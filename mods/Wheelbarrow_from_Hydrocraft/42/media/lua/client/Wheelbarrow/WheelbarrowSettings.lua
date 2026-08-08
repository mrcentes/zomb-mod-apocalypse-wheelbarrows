require "PZAPI/ModOptions"

WheelbarrowSettings = WheelbarrowSettings or {}
WheelbarrowSettings.DEFAULT_CAPACITY = 180
WheelbarrowSettings.DEFAULT_ITEM_WEIGHT = 20
WheelbarrowSettings.MOD_OPTIONS_ID = "Wheelbarrow42plusFix"

function WheelbarrowSettings.init()
    local options = PZAPI.ModOptions:getOptions(WheelbarrowSettings.MOD_OPTIONS_ID)
    if options then
        return options
    end

    options = PZAPI.ModOptions:create(WheelbarrowSettings.MOD_OPTIONS_ID, "Wheelbarrow")
    options:addTitle("Wheelbarrow")
    options:addDescription("Build 42 wheelbarrow settings.")
    options:addSlider("capacity", "Wheelbarrow Capacity", 50, 300, 10, WheelbarrowSettings.DEFAULT_CAPACITY,
        "Effective storage capacity used by the Build 42 wheelbarrow compatibility layer.")
    PZAPI.ModOptions:load()
    return options
end

function WheelbarrowSettings.getCapacity()
    local options = WheelbarrowSettings.init()
    local capacityOption = options and options:getOption("capacity")
    local capacity = capacityOption and capacityOption:getValue() or WheelbarrowSettings.DEFAULT_CAPACITY
    return math.floor(tonumber(capacity) or WheelbarrowSettings.DEFAULT_CAPACITY)
end

function WheelbarrowSettings.getRawCapacity(item)
    local effectiveCapacity = WheelbarrowSettings.getCapacity()
    local itemWeight = WheelbarrowSettings.DEFAULT_ITEM_WEIGHT
    if item and item.getWeight then
        itemWeight = item:getWeight()
    end
    return math.floor(effectiveCapacity + itemWeight)
end
