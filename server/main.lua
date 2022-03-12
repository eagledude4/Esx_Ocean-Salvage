ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_oceansalvage:GiveItem')
AddEventHandler('esx_oceansalvage:GiveItem', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	local randomChance = math.random(0, 100)
	if randomChance == 1 then
		local xItem = xPlayer.getInventoryItem('spanish_gold')
		if xItem.limit ~= -1 and (xItem.count + 1) > xItem.limit then
			TriggerClientEvent('esx:showNotification', source, "Inventory is Full")
		else
			xPlayer.addInventoryItem('spanish_gold', 1)
			TriggerClientEvent('esx:showNotification', _source, _U('salvage_collected'))
		end
	else
		local xItem = xPlayer.getInventoryItem('contrat')
		if xItem.limit ~= -1 and (xItem.count + 1) > xItem.limit then
			TriggerClientEvent('esx:showNotification', source, "Inventory is Full")
		else
			xPlayer.addInventoryItem('contrat', 1)
			TriggerClientEvent('esx:showNotification', _source, _U('salvage_collected'))
		end
	end
end)

RegisterServerEvent('esx_oceansalvage:GiveOxygenMask')
AddEventHandler('esx_oceansalvage:GiveOxygenMask', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	local xItem = xPlayer.getInventoryItem('oxygen_mask')
	if xItem.limit ~= -1 and (xItem.count + 1) > xItem.limit then
		TriggerClientEvent('esx:showNotification', source, "Inventory is Full")
	else
		xPlayer.addInventoryItem('oxygen_mask', 1)
	end
end)

RegisterServerEvent('esx_oceansalvage:sellSalvage')
AddEventHandler('esx_oceansalvage:sellSalvage', function(itemName, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.Itemsprice[itemName]
    local xItem = xPlayer.getInventoryItem(itemName)


    if xItem.count < amount then
        TriggerClientEvent('esx:showNotification', source, _U('not_enough'))
        return
    end

    price = ESX.Math.Round(price * amount)

    if Config.GiveBlack then
        xPlayer.addAccountMoney('black_money', price)
    else
        xPlayer.addMoney(price)
    end

    xPlayer.removeInventoryItem(xItem.name, amount)

    TriggerClientEvent('esx:showNotification', source, _U('sold', amount, xItem.label, ESX.Math.GroupDigits(price)))
end)
