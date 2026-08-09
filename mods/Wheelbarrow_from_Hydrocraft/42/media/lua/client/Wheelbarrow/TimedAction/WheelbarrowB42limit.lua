require "Wheelbarrow/WheelbarrowLeverage"
require "Wheelbarrow/WheelbarrowLogger"

local original_ISInventoryTransferAction_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    if self.item ~= nil and self.srcContainer ~= nil and self.destContainer ~= nil then
        local srcIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(self.srcContainer)
        local destIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(self.destContainer)
        if srcIsWheelbarrow or destIsWheelbarrow then
            local snapshot = WheelbarrowLeverage.snapshot(self.item)
            WheelbarrowLeverage.applyProjectedValidationWeight(self.item, self.srcContainer, self.destContainer)
            local val = original_ISInventoryTransferAction_isValid(self)
            WheelbarrowLeverage.restoreSnapshot(self.item, snapshot)
            return val
        end
    end

    return original_ISInventoryTransferAction_isValid(self)
end

local original_ISInventoryPane_canPutIn = ISInventoryPane.canPutIn
function ISInventoryPane:canPutIn()
    local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging or {})
    if self.inventory ~= nil and #dragging > 0 then
        local snapshots = {}
        for _, item in ipairs(dragging) do
            snapshots[item] = WheelbarrowLeverage.snapshot(item)
            WheelbarrowLeverage.applyProjectedValidationWeight(item, item:getContainer(), self.inventory)
        end

        local val = original_ISInventoryPane_canPutIn(self)

        for _, item in ipairs(dragging) do
            WheelbarrowLeverage.restoreSnapshot(item, snapshots[item])
        end

        return val
    end

    return original_ISInventoryPane_canPutIn(self)
end

if ISInventoryPaneDraggedItems and ISInventoryPaneDraggedItems.update then
    local original_DraggedItems_update = ISInventoryPaneDraggedItems.update
    function ISInventoryPaneDraggedItems:update()
        self.playerNum = self.inventoryPane.player
        if not self.items then
            self.items = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
            self.inventoryPane:sortItemsByTypeAndWeight(self.items)
        end

        local targetContainer = self:getDropContainer()
        if type(targetContainer) == "table" then
            targetContainer = targetContainer[1]
        end

        local snapshots = {}
        if targetContainer ~= nil and self.items ~= nil then
            for _, item in ipairs(self.items) do
                snapshots[item] = WheelbarrowLeverage.snapshot(item)
                WheelbarrowLeverage.applyProjectedValidationWeight(item, item:getContainer(), targetContainer)
            end
        end

        original_DraggedItems_update(self)

        if self.items ~= nil then
            for _, item in ipairs(self.items) do
                WheelbarrowLeverage.restoreSnapshot(item, snapshots[item])
            end
        end
    end
end

if javaTransferItems then
    local original_javaTransferItems = javaTransferItems
    function javaTransferItems(character, item, srcContainer, destContainer)
        local actualDestContainer = destContainer
        local actualSrcContainer = srcContainer

        if instanceof(actualDestContainer, "InventoryContainer") then
            actualDestContainer = actualDestContainer:getInventory()
        end
        if instanceof(actualSrcContainer, "InventoryContainer") then
            actualSrcContainer = actualSrcContainer:getInventory()
        end

        if item ~= nil and actualSrcContainer ~= nil and actualDestContainer ~= nil then
            local snapshot = WheelbarrowLeverage.snapshot(item)
            WheelbarrowLeverage.applyProjectedValidationWeight(item, actualSrcContainer, actualDestContainer)
            original_javaTransferItems(character, item, srcContainer, destContainer)
            WheelbarrowLeverage.restoreSnapshot(item, snapshot)
            return
        end

        original_javaTransferItems(character, item, srcContainer, destContainer)
    end
end

if ISTransferAction and ISTransferAction.transferItem then
    local original_ISTransferAction_transferItem = ISTransferAction.transferItem
    function ISTransferAction:transferItem(character, item, srcContainer, destContainer, dropSquare)
        if item == nil or srcContainer == nil or destContainer == nil then
            return original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end

        local srcIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(srcContainer)
        local destIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(destContainer)
        if not srcIsWheelbarrow and not destIsWheelbarrow then
            return original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end

        local snapshot = WheelbarrowLeverage.snapshot(item)
        local baseWeight = WheelbarrowLeverage.getBaseWeight(item)

        WheelbarrowLeverage.applyProjectedValidationWeight(item, srcContainer, destContainer)
        local transferredItem = original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        local resolvedItem = transferredItem or item
        local transferSucceeded = resolvedItem ~= nil and resolvedItem.getContainer ~= nil and resolvedItem:getContainer() == destContainer

        if transferSucceeded then
            if destIsWheelbarrow and not srcIsWheelbarrow then
                WheelbarrowLeverage.markAdjusted(resolvedItem, baseWeight)
                WheelbarrowLogger.info("Applied leverage to " .. tostring(resolvedItem:getType()) .. " entering wheelbarrow")
            elseif srcIsWheelbarrow and not destIsWheelbarrow then
                WheelbarrowLeverage.clearAdjusted(resolvedItem)
                WheelbarrowLogger.info("Restored weight for " .. tostring(resolvedItem:getType()) .. " leaving wheelbarrow")
            end
        else
            WheelbarrowLeverage.restoreSnapshot(item, snapshot)
            WheelbarrowLogger.warn("Transfer involving wheelbarrow did not resolve; restored snapshot for " .. tostring(item:getType()))
        end

        return transferredItem
    end
end
