require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISUnequipAction"

PFGMenu ={};
PFGMenu.typesTable = {
	["HCWoodenwheelbarrow"]=true
}

PFGMenu.dropItemSafely = function(playerObj, item)
	if not playerObj or not item or item:isFavorite() then
		return
	end

	local srcContainer = item:getContainer()
	local floorContainer = ISInventoryPage.GetFloorContainer(playerObj:getPlayerNum())
	if not srcContainer or not floorContainer then
		return
	end

	if playerObj:isHandItem(item) then
		ISTimedActionQueue.add(ISUnequipAction:new(playerObj, item, 1))
	end

	ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, srcContainer, floorContainer))
end

PFGMenu.dropCart = function(worldobjects,items,player)
	local playerObj = getSpecificPlayer(player)
	items = ISInventoryPane.getActualItems(items or {})
	for _, item in ipairs(items) do
		PFGMenu.dropItemSafely(playerObj, item)
	end
end

PFGMenu.addWorldContext = function(player, context, worldobjects, test)	
	local pzPlayer = getSpecificPlayer(player)
	-- fast drop
	local current_weapon = pzPlayer:getPrimaryHandItem()
	if current_weapon~=nil and PFGMenu.typesTable[current_weapon:getType()] then
		context:addOption("Drop " .. current_weapon:getDisplayName(),worldobjects,PFGMenu.dropCart,{current_weapon},player)
		return
	end
	
	local origSq= worldobjects[1]:getSquare();
	local items = {}
	if instanceof(origSq, "IsoGridSquare") then
		items = PFGMenu.getItems(origSq)
		items = appendTables(items, PFGMenu.getItems(origSq:getN()))
		items = appendTables(items, PFGMenu.getItems(origSq:getS()))
		items = appendTables(items, PFGMenu.getItems(origSq:getW()))
		items = appendTables(items, PFGMenu.getItems(origSq:getE()))
	else
		return
	end

	local carts = {}
	local cartCount = 0
	local closestCart = nil
	local closestCartDistance = 1000
	for i,v in ipairs(items) do
		if instanceof(v, "IsoWorldInventoryObject") then
			 if instanceof (v:getItem(),"InventoryContainer") then
				local curr_type = v:getItem():getItemContainer():getType()
				if PFGMenu.typesTable[curr_type] then				
					table.insert(carts,v)
					cartCount = cartCount + 1
				end
			end
		end
	end
	if cartCount > 0 then
		for i,v in ipairs(carts)do
			local distance = PFGMenu.getDistance2D(v:getWorldPosX(),v:getWorldPosY(),pzPlayer:getSquare():getX(),pzPlayer:getSquare():getY())
			if distance < closestCartDistance then 
				closestCart = v
				closestCartDistance = distance
			end
		end
		local label = "Push " .. closestCart:getItem():getDisplayName()
		local selectOption = context:addOption(label,worldobjects,PFGMenu.equipCart,player,closestCart)
	end
end

--EDIT CAPACITY MENU
--PFGMenu.onEditBagChange = function (target, box)
--	if box.options[box.selected] ~= nil then	
--		local newCapacity = tonumber(box.options[box.selected])
--		target:setCapacity(newCapacity)
--		scriptItem = ScriptManager.instance:getItem("Wheelbarrow.HCWoodenwheelbarrow")
--		scriptItem:DoParam("Capacity = "..newCapacity)
--	end
--end
--
--function PFGMenu:onEditBagClick(button, player, item, box)
--    local playerNum = player:getPlayerNum()
--    if button.internal == "OK" then        
--		PFGMenu.onEditBagChange(item,box)
--    end
--    if JoypadState.players[playerNum+1] then
--        setJoypadFocus(playerNum, getPlayerInventory(playerNum))
--    end
--end
--
--function PFGMenu:onJoypadDown(button, joypadData) --controller support
--	if button == Joypad.AButton then	
--		self.selected = self.popup.selected	
--		PFGMenu.onEditBagChange(self.target,self)
--		self.parent:close()
--        setJoypadFocus(joypadData.player, getPlayerInventory(joypadData.player))
--	elseif button == Joypad.BButton then
--		self.parent:close()	
--        setJoypadFocus(joypadData.player, getPlayerInventory(joypadData.player))
--	end
--end

--PFGMenu.onEditBag = function(bag, player)
--	local options = {
--		"70",
--		"80",
--		"90",
--		"100",
--		"120",
--		"140",
--		"180",
--		"200"
--	}
--	
--	local combowidth = 50
--	local comboentry = ISComboBox:new(150, 0, combowidth, 18, bag, PFGMenu.onEditBagChange, comboentry);
--    local modal = ISTextBox:new(0, 0, 280, 180, "new capacity", bag:getName(), nil, PFGMenu.onEditBagClick, player, getSpecificPlayer(player), bag, comboentry);
--    modal:initialise();
--    modal:addToUIManager();
--	comboentry:initialise()
--	for i,v in pairs(options) do
--		comboentry:addOption(options[i])
--	end
--	--keep current capacity
--	comboentry:select(bag:getCapacity())
--	
--	--replace default text entry
--	comboentry:setX((modal.width/2) - (combowidth/2))
--	comboentry:setY(modal.entry:getY())
--	
--	comboentry:setJoypadFocused(true)--controller support
--	comboentry.onJoypadDown = PFGMenu.onJoypadDown
--	
--	modal:addChild(comboentry)
--	modal:removeChild(modal.entry)
--	
--	modal:removeChild(modal.yes)
--	
--    if JoypadState.players[player+1] then
--		comboentry:forceClick(true)--controller support
--        setJoypadFocus(player, comboentry)
--    end
--end
--EDIT CAPACITY

PFGMenu.addInventoryContext = function(player,context,inventoryObjects)
	local pzPlayer = getSpecificPlayer(player)
	local playerInventory = pzPlayer:getInventory()

	
	-- work on lateral containers hotbar slots
	local cart = inventoryObjects and inventoryObjects[1]
	local selectedType = cart ~= nil and cart.getType and cart:getType()
	local isCartOnProximitySlot = PFGMenu.typesTable[selectedType]

	if isCartOnProximitySlot then
		local items = ISInventoryPane.getActualItems(inventoryObjects)
		if playerInventory:contains(items[1]) then return end
		context:addOption("Push Selected", items[1], PFGMenu.pushCart, player, items[1])
		return
	end
	
				
	local items = inventoryObjects
	for i,v in pairs(items) do
		if v.cat == "Container" then
			--context:addOption("edit capacity", v.items[i], PFGMenu.onEditBag,player) --edit capacity
			--dont show push inside player inventory
			if playerInventory:contains(v.items[i]) then return end
				
			if i and v and v.items and v.items[i] and v.items[i].getItemContainer then              
                local itemClicked = v.items[i]:getItemContainer()
                
                local curr_type = itemClicked:getType()
				if PFGMenu.typesTable[curr_type] then
					local selectOption = context:addOption("Push " .. itemClicked:getDisplayName() ,v.items,PFGMenu.pushCart,player,v.items[i],v)
				end
            end
		end
	end
	
end

PFGMenu.pushCart = function(worldobjects,player,item,container)
	local pzPlayer = getSpecificPlayer(player)
	--if on floor
	local item_world = item:getWorldItem()

	if item_world then
		PFGMenu.equipCart(worldobjects,player,item_world)	
	else
		--if inside trunk FIX BUG CANT GET BACK FROM TRUNK IF TOO HEAVY
		ISTimedActionQueue.add(ISEquipHeavyItem:new(pzPlayer, item, 50))
	end
	
	
end

PFGMenu.equipCart = function(worldobjects,player,item)
	local pzPlayer = getSpecificPlayer(player)
	local sqP = pzPlayer:getSquare()
	local sqC = item:getSquare()
	local sqCx = sqC:getX()
	local sqCy = sqC:getY()

	pzPlayer:faceLocation(sqCx,sqCy)

	ISTimedActionQueue.add(PFGPushAction:new(item,pzPlayer))

	local d = PFGMenu.getDistance2D(sqP:getX(),sqP:getY(), sqCx,sqCy)
	if d > 1.5 then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(pzPlayer, item:getSquare()))
	end
end

PFGMenu.getItems = function(square)
	local items ={}
	local squares ={}
	if instanceof(square, "IsoGridSquare") == false then return items end
	table.insert(squares,square)
	table.insert(squares,square:getN())
	table.insert(squares,square:getS())
	table.insert(squares,square:getE())
	table.insert(squares,square:getW())
	for si,s in ipairs(squares) do
		for ii,i in ipairs(s:getLuaTileObjectList()) do
			table.insert(items,i)
		end
	end
	return items
end

PFGMenu.getDistance2D = function(_x1, _y1, _x2, _y2)
	return math.sqrt(math.abs(_x2 - _x1)^2 + math.abs(_y2 - _y1)^2);
end

function appendTables(t1, t2)
    for _, value in ipairs(t2) do
        table.insert(t1, value)
    end
	return t1
end

Events.OnFillWorldObjectContextMenu.Add(PFGMenu.addWorldContext)
Events.OnPreFillInventoryObjectContextMenu.Add(PFGMenu.addInventoryContext)
