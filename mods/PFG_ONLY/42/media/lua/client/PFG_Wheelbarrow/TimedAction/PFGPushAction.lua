if PFGMenu then return end
require "TimedActions/ISBaseTimedAction"

PFGPushAction = ISBaseTimedAction:derive("PFGPushAction")

function PFGPushAction.isValid(args)
	
	for i,v in ipairs(PFGMenu.typesTable) do
		if args["character"]:getInventory():contains(tostring(v)) then
			return false
		end
	end
	return true
end

function PFGPushAction:waitToStart()
	return false
end

function PFGPushAction:update()

end

function PFGPushAction:start()
	
end

function PFGPushAction:stop()
	ISBaseTimedAction.stop(self);
end

function PFGPushAction:perform()
	
	local inventoryItem = self.item:getItem()
	if self.item:getSquare() then 
		self.item:getSquare():transmitRemoveItemFromSquare(self.item)
	end
	self.item:removeFromWorld()
	self.item:removeFromSquare()
	self.item:setSquare(nil)
	inventoryItem:setWorldItem(nil)
	inventoryItem:setJobDelta(0.0)
	self.inventory:setDrawDirty(true)
	self.inventory:AddItem(inventoryItem)
	PFGPushAction.equipWeapon(inventoryItem,false,true,self.character:getPlayerNum())

	ISBaseTimedAction.perform(self)
end

-- Function that equip the selected weapon
PFGPushAction.equipWeapon = function(weapon, primary, twoHands, player)
	local playerObj = getSpecificPlayer(player)
	-- Drop corpse or generator
	if isForceDropHeavyItem(playerObj:getPrimaryHandItem()) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50));
	end
	-- if weapon isn't in main inventory, put it there first.
	-- FIX BUG cant retrive when store in vehicle truck
	--ISInventoryPaneContextMenu.transferIfNeeded(playerObj, weapon)
	-- Then equip it.
	ISTimedActionQueue.add(ISEquipWeaponAction:new(playerObj, weapon, 50, primary, twoHands));
end

function PFGPushAction:new( item, player)

	local o = {}
	setmetatable( o, self)
	self.__index = self
	o.maxTime = 50
	o.character = player
	o.inventory = player:getInventory()
	o.item = item
	o.stopOnWalk = false
	o.stopOnRun = false
	
	return o
end