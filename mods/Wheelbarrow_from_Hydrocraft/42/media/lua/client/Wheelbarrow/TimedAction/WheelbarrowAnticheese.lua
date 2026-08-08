-- -- Gravy contrib (wastelandRP) (kinda buggy in some tests, but if it works in mp its fine, maybe generate visual buggs)
-- require "TimedActions/PFGPushAction"

-- local our_type = "Wheelbarrow.HCWoodenwheelbarrow"
-- local inv_type = "InventoryContainer"
-- local isMP = (isClient() or isServer());

-- local original_ISUnequipAction_perform = ISUnequipAction.perform
-- function ISUnequipAction:perform()
--     if isMP and instanceof(self.item,inv_type) and self.item:getFullType() == our_type and self.item.getInventory and not self.item:getInventory():isEmpty() then
        -- ISTimedActionQueue.addAfter(self, ISDropItemAction:new(self.character, self.item, 1)) --only on b41
        -- local player = self.character:getPlayerNum()
        -- PFGMenu.dropCart(nil,self.item,player)
--     end
--     original_ISUnequipAction_perform(self)
-- end

-- local original_ISInventoryTransferAction_isValid = ISInventoryTransferAction.isValid
-- function ISInventoryTransferAction:isValid()
--     local val = original_ISInventoryTransferAction_isValid(self)
--     if not val then return false end
--     if isMP and self.item and instanceof(self.item,inv_type) and self.destContainer and self.item:getFullType() == our_type and self.item.getInventory and not self.item:getInventory():isEmpty() and not self.destContainer:getType()=="floor" then
--         return false
--     end
--     return val
-- end

-- local original_ISGrabItemAction_isValid = ISGrabItemAction.isValid
-- function ISGrabItemAction:isValid()
--     local val = original_ISGrabItemAction_isValid(self)
--     if not val then return false end
--     local loc_item = self.item
--     if instanceof(loc_item,"IsoWorldInventoryObject") and loc_item.getItem then
--         loc_item = loc_item:getItem()
--     end
--     if isMP and loc_item and instanceof(loc_item,inv_type) and loc_item:getFullType() == our_type and loc_item.getInventory and not loc_item:getInventory():isEmpty() then
--         return false
--     end
--     return val
-- end

-- function PFGPushAction:isValid()
-- 	for i,v in ipairs(PFGMenu.typesTable) do
-- 		if self.character:getInventory():contains(tostring(v)) then
-- 			return false
-- 		end
-- 	end
--     if isMP then
--         if not self.sq then return false end

--         local objects = self.sq:getWorldObjects()
--         for i=0, objects:size()-1 do
--             local object = objects:get(i)
--             if object == self.item then
--                 return true
--             end
--         end

--         return false
--     else 
--         return true
--     end
-- end

-- local original_PFGPushAction_new = PFGPushAction.new
-- function PFGPushAction:new( item, player)
--     local o = original_PFGPushAction_new(self, item, player)
--     o.sq = item:getSquare()
--     return o
-- end

-- local original_isForceDropHeavyItem = isForceDropHeavyItem
-- function isForceDropHeavyItem(item)
--     return isMP and original_isForceDropHeavyItem(item) or (item ~= nil and item:getFullType() == our_type and item.getInventory and not item:getInventory():isEmpty())
-- end