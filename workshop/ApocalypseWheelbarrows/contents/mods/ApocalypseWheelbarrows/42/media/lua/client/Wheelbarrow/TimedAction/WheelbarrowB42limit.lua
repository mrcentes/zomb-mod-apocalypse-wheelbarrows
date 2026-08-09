require "Wheelbarrow/WheelbarrowLeverage"
require "Wheelbarrow/WheelbarrowLogger"

WheelbarrowB42limit = WheelbarrowB42limit or {}

local function withItemSnapshot(item, callback)
    if item == nil then
        return callback()
    end

    local snapshot = WheelbarrowLeverage.snapshot(item)
    local ok, result = pcall(callback)
    WheelbarrowLeverage.restoreSnapshot(item, snapshot)
    if not ok then
        error(result)
    end
    return result
end

local function withItemSnapshots(items, callback)
    local snapshots = {}

    if items ~= nil then
        for _, item in ipairs(items) do
            snapshots[item] = WheelbarrowLeverage.snapshot(item)
        end
    end

    local ok, result = pcall(callback)

    if items ~= nil then
        for _, item in ipairs(items) do
            WheelbarrowLeverage.restoreSnapshot(item, snapshots[item])
        end
    end

    if not ok then
        error(result)
    end

    return result
end

if not WheelbarrowB42limit._patchedTransferActionIsValid then
    WheelbarrowB42limit._patchedTransferActionIsValid = true
    WheelbarrowB42limit._original_ISInventoryTransferAction_isValid = WheelbarrowB42limit._original_ISInventoryTransferAction_isValid or ISInventoryTransferAction.isValid

    function ISInventoryTransferAction:isValid()
        if self.item ~= nil and self.srcContainer ~= nil and self.destContainer ~= nil then
            local srcIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(self.srcContainer)
            local destIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(self.destContainer)
            if srcIsWheelbarrow or destIsWheelbarrow then
                return withItemSnapshot(self.item, function()
                    WheelbarrowLeverage.applyProjectedValidationWeight(self.item, self.srcContainer, self.destContainer)
                    return WheelbarrowB42limit._original_ISInventoryTransferAction_isValid(self)
                end)
            end
        end

        return WheelbarrowB42limit._original_ISInventoryTransferAction_isValid(self)
    end
end

if not WheelbarrowB42limit._patchedInventoryPaneCanPutIn then
    WheelbarrowB42limit._patchedInventoryPaneCanPutIn = true
    WheelbarrowB42limit._original_ISInventoryPane_canPutIn = WheelbarrowB42limit._original_ISInventoryPane_canPutIn or ISInventoryPane.canPutIn

    function ISInventoryPane:canPutIn()
        local dragging = ISInventoryPane.getActualItems(ISMouseDrag.dragging or {})
        if self.inventory ~= nil and #dragging > 0 then
            return withItemSnapshots(dragging, function()
                for _, item in ipairs(dragging) do
                    WheelbarrowLeverage.applyProjectedValidationWeight(item, item:getContainer(), self.inventory)
                end
                return WheelbarrowB42limit._original_ISInventoryPane_canPutIn(self)
            end)
        end

        return WheelbarrowB42limit._original_ISInventoryPane_canPutIn(self)
    end
end

if ISInventoryPaneDraggedItems and ISInventoryPaneDraggedItems.update and not WheelbarrowB42limit._patchedDraggedItemsUpdate then
    WheelbarrowB42limit._patchedDraggedItemsUpdate = true
    WheelbarrowB42limit._original_DraggedItems_update = WheelbarrowB42limit._original_DraggedItems_update or ISInventoryPaneDraggedItems.update

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

        if targetContainer ~= nil and self.items ~= nil then
            return withItemSnapshots(self.items, function()
                for _, item in ipairs(self.items) do
                    WheelbarrowLeverage.applyProjectedValidationWeight(item, item:getContainer(), targetContainer)
                end
                return WheelbarrowB42limit._original_DraggedItems_update(self)
            end)
        end

        return WheelbarrowB42limit._original_DraggedItems_update(self)
    end
end

if javaTransferItems and not WheelbarrowB42limit._patchedJavaTransferItems then
    WheelbarrowB42limit._patchedJavaTransferItems = true
    WheelbarrowB42limit._original_javaTransferItems = WheelbarrowB42limit._original_javaTransferItems or javaTransferItems

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
            return withItemSnapshot(item, function()
                WheelbarrowLeverage.applyProjectedValidationWeight(item, actualSrcContainer, actualDestContainer)
                return WheelbarrowB42limit._original_javaTransferItems(character, item, srcContainer, destContainer)
            end)
        end

        return WheelbarrowB42limit._original_javaTransferItems(character, item, srcContainer, destContainer)
    end
end

if ISTransferAction and ISTransferAction.transferItem and not WheelbarrowB42limit._patchedTransferItem then
    WheelbarrowB42limit._patchedTransferItem = true
    WheelbarrowB42limit._original_ISTransferAction_transferItem = WheelbarrowB42limit._original_ISTransferAction_transferItem or ISTransferAction.transferItem

    function ISTransferAction:transferItem(character, item, srcContainer, destContainer, dropSquare)
        if item == nil or srcContainer == nil or destContainer == nil then
            return WheelbarrowB42limit._original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end

        local srcIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(srcContainer)
        local destIsWheelbarrow = WheelbarrowLeverage.isWheelbarrowContainer(destContainer)
        if not srcIsWheelbarrow and not destIsWheelbarrow then
            return WheelbarrowB42limit._original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end

        local snapshot = WheelbarrowLeverage.snapshot(item)
        local baseWeight = WheelbarrowLeverage.getBaseWeight(item)
        local ok, transferredItem = pcall(function()
            WheelbarrowLeverage.applyProjectedValidationWeight(item, srcContainer, destContainer)
            return WheelbarrowB42limit._original_ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
        end)

        if not ok then
            WheelbarrowLeverage.restoreSnapshot(item, snapshot)
            error(transferredItem)
        end

        local resolvedItem = transferredItem or item
        local transferSucceeded = resolvedItem ~= nil and resolvedItem.getContainer ~= nil and resolvedItem:getContainer() == destContainer

        if transferSucceeded then
            if destIsWheelbarrow and not srcIsWheelbarrow then
                WheelbarrowLeverage.markAdjusted(resolvedItem, baseWeight)
                WheelbarrowLogger.info("Applied leverage to " .. tostring(resolvedItem:getType()) .. " entering wheelbarrow")
            elseif srcIsWheelbarrow and not destIsWheelbarrow then
                WheelbarrowLeverage.clearAdjusted(resolvedItem)
                WheelbarrowLogger.info("Restored weight for " .. tostring(resolvedItem:getType()) .. " leaving wheelbarrow")
            else
                WheelbarrowLeverage.restoreSnapshot(item, snapshot)
            end
        else
            WheelbarrowLeverage.restoreSnapshot(item, snapshot)
            WheelbarrowLogger.warn("Transfer involving wheelbarrow did not resolve; restored snapshot for " .. tostring(item:getType()))
        end

        return transferredItem
    end
end
