local b41_capacity = (PFGMenu and PFGMenu.capacityOverride) or 180;
local original_ISInventoryTransferAction_isValid = ISInventoryTransferAction.isValid
function ISInventoryTransferAction:isValid()
    
    local val = original_ISInventoryTransferAction_isValid(self)
    --b42 30 50 capacity bypass
    local bypassB42Limit = false;
    if self.destContainer ~= nil and self.destContainer.getType and PFGMenu.typesTable[self.destContainer:getType()] then
        bypassB42Limit = (b41_capacity > (self.destContainer:getContentsWeight() + self.item:getWeight()))
        return bypassB42Limit
    end
    --end b42
    return val
end

local original_ISInventoryPane_canPutIn = ISInventoryPane.canPutIn
function ISInventoryPane:canPutIn()
    local bypassB42Limit = false;
    if self.inventory ~= nil and self.inventory.getType and PFGMenu.typesTable[self.inventory:getType()] then
        local items = {}
        items=ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        bypassB42Limit = (b41_capacity > (self.inventory:getContentsWeight() + items[1]:getWeight()))
        -- if bypassB42Limit then
        --     local playerObj = getSpecificPlayer(self.player)
		-- 	ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, items[1], items[1]:getContainer(), self.inventory))
        -- end
        return bypassB42Limit
    end

    local val = original_ISInventoryPane_canPutIn(self)
    return val
end
