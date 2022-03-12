local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
PlayerData                    = {}
local HasAlreadyEnteredMarker = false
local LastZone = nil
local CurrentAction = nil
local CurrentActionMsg = ''
local CurrentActionData = {}
local onDuty = false
local BlipCloakRoom = nil
local BlipVehicle = nil
local BlipVehicleDeleter = nil
local Blips = {}
local salvageBlips = {}
local OnJob = false
local Done = false

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end

  while ESX.GetPlayerData() == nil do
    Citizen.Wait(10)
  end
  PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
	refreshBlips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
	onDuty = false
	--CreateBlip()
  refreshBlips()
end)

function SelectPool()
	local index = GetRandomIntInRange(1, #Config.Pool)

	for k,v in pairs(Config.Zones) do
		if v.Pos.x == Config.Pool[index].x and v.Pos.y == Config.Pool[index].y and v.Pos.z == Config.Pool[index].z then
			return k
		end
	end
end

function StartNPCJob()
	NPCTargetPool = SelectPool()
	local zone = Config.Zones[NPCTargetPool]

	Blips['NPCTargetPool'] = AddBlipForCoord(zone.Pos.x, zone.Pos.y, zone.Pos.z)
	SetBlipRoute(Blips['NPCTargetPool'], true)
	ESX.ShowNotification(_U('GPS_info'))
	Done = true
	TriggerServerEvent('esx_oceansalvage:GiveOxygenMask')
end

function StopNPCJob(cancel)
	if Blips['NPCTargetPool'] ~= nil then
		RemoveBlip(Blips['NPCTargetPool'])
		Blips['NPCTargetPool'] = nil
	end

	OnJob = false

	if cancel then
		ESX.ShowNotification(_U('cancel_mission'))
	else
		TriggerServerEvent('esx_oceansalvage:GiveItem')
		StartNPCJob()
		Done = true
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if NPCTargetPool ~= nil then
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			local zone = Config.Zones[NPCTargetPool]

      if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < 200 then
        DrawMarker(Config.MarkerType, zone.Pos.x, zone.Pos.y, zone.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, 255, 255, 0, 100, false, true, 2, false, false, false, false)

        if GetDistanceBetweenCoords(coords, zone.Pos.x, zone.Pos.y, zone.Pos.z, true) < 3 then
  				ESX.ShowHelpNotification(_U('pickup'))

  				if IsControlJustReleased(1, Keys["E"]) and PlayerData.job ~= nil then
  					TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
  					Citizen.Wait(17000)
  					StopNPCJob()
  					Citizen.Wait(3000)
  					ClearPedTasksImmediately(playerPed)
  					Done = false
  				end
  			end
      end
		end
	end
end)

function CloakRoomMenu()

	local elements = {}

	if onDuty then
		table.insert(elements, {label = _U('end_service'), value = 'citizen_wear'})
	else
		table.insert(elements, {label = _U('take_service'), value = 'job_wear'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('locker_title'),
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'citizen_wear' then

			onDuty = false
      refreshBlips()
			--CreateBlip()
			menu.close()
			ESX.ShowNotification(_U('end_service_notif'))

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)

		elseif data.current.value == 'job_wear' then

			onDuty = true
      refreshBlips()
			--CreateBlip()
			menu.close()
			ESX.ShowNotification(_U('take_service_notif'))
			ESX.ShowNotification(_U('start_job'))
			setUniform(data.current.value)

		end

		CurrentAction     = 'cloakroom_menu'
		CurrentActionMsg  = Config.Zones.Cloakroom.hint
		CurrentActionData = {}
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'cloakroom_menu'
		CurrentActionMsg  = Config.Zones.Cloakroom.hint
		CurrentActionData = {}
	end)

end

function VehicleMenu()

	local elements = {
		{label = Config.Vehicles.Truck.Label, value = Config.Vehicles.Truck}
	}

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'spawn_vehicle', {
		title    = _U('Vehicle_Menu_Title'),
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)

		menu.close()
		local playerPed = PlayerPedId()
		local plateNum = math.random(1000, 9999)
		local platePrefix = Config.PlatePrefix

		ESX.Game.SpawnVehicle(data.current.value.Hash, Config.Zones.VehicleSpawnPoint.Pos, Config.Zones.VehicleSpawnPoint.Heading, function(vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			exports["LegacyFuel"]:SetFuel(vehicle, 100)
			TriggerServerEvent('esx_vehiclelock:registerVehicleOwner', vehicle)
		end)

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'vehiclespawn_menu'
		CurrentActionMsg  = Config.Zones.VehicleSpawner.hint
		CurrentActionData = {}
	end)

end

AddEventHandler('esx_oceansalvage:hasEnteredMarker', function(zone)
	if zone == 'Cloakroom' then
		CurrentAction     = 'cloakroom_menu'
		CurrentActionMsg  = Config.Zones.Cloakroom.hint
		CurrentActionData = {}
	elseif zone == 'VehicleSpawner' then
		CurrentAction     = 'vehiclespawn_menu'
		CurrentActionMsg  = Config.Zones.VehicleSpawner.hint
		CurrentActionData = {}
	elseif zone == 'VehicleDeleter' then -- broken
		local playerPed = PlayerPedId()
		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed, false)

			if GetPedInVehicleSeat(vehicle, -1) == playerPed then
				CurrentAction     = 'delete_vehicle'
				CurrentActionMsg  = Config.Zones.VehicleDeleter.hint
				CurrentActionData = {}
			end
		end
	end
end)

AddEventHandler('esx_oceansalvage:hasExitedMarker', function(zone)
	CurrentAction = nil
	ESX.UI.Menu.CloseAll()
end)

--[[function CreateBlip()
	if PlayerData.job ~= nil and PlayerData.job.name == Config.JobName then

		if BlipCloakRoom == nil then

			BlipCloakRoom = AddBlipForCoord(Config.Zones.Cloakroom.Pos.x, Config.Zones.Cloakroom.Pos.y, Config.Zones.Cloakroom.Pos.z)
			SetBlipSprite(BlipCloakRoom, Config.Zones.Cloakroom.BlipSprite)
			SetBlipColour(BlipCloakRoom, Config.Zones.Cloakroom.BlipColor)
			SetBlipAsShortRange(BlipCloakRoom, true)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(Config.Zones.Cloakroom.BlipName)
			EndTextCommandSetBlipName(BlipCloakRoom)

		end
	else

		if BlipCloakRoom ~= nil then
			RemoveBlip(BlipCloakRoom)
			BlipCloakRoom = nil
		end

	end

	if PlayerData.job ~= nil and PlayerData.job.name == Config.JobName and onDuty then

		BlipVehicle = AddBlipForCoord(Config.Zones.VehicleSpawner.Pos.x, Config.Zones.VehicleSpawner.Pos.y, Config.Zones.VehicleSpawner.Pos.z)
		SetBlipSprite(BlipVehicle, Config.Zones.VehicleSpawner.BlipSprite)
		SetBlipColour(BlipVehicle, Config.Zones.VehicleSpawner.BlipColor)
		SetBlipAsShortRange(BlipVehicle, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(Config.Zones.VehicleSpawner.BlipName)
		EndTextCommandSetBlipName(BlipVehicle)

		BlipVehicleDeleter = AddBlipForCoord(Config.Zones.VehicleDeleter.Pos.x, Config.Zones.VehicleDeleter.Pos.y, Config.Zones.VehicleDeleter.Pos.z)
		SetBlipSprite(BlipVehicleDeleter, Config.Zones.VehicleDeleter.BlipSprite)
		SetBlipColour(BlipVehicleDeleter, Config.Zones.VehicleDeleter.BlipColor)
		SetBlipAsShortRange(BlipVehicleDeleter, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(Config.Zones.VehicleDeleter.BlipName)
		EndTextCommandSetBlipName(BlipVehicleDeleter)
	else

		if BlipVehicle ~= nil then
			RemoveBlip(BlipVehicle)
			BlipVehicle = nil
		end

		if BlipVehicleDeleter ~= nil then
			RemoveBlip(BlipVehicleDeleter)
			BlipVehicleDeleter = nil
		end
	end
end]]

-- CREATE BLIPS
Citizen.CreateThread(function()
  local BlipCloakRoom = AddBlipForCoord(Config.Zones.Cloakroom.Pos.x, Config.Zones.Cloakroom.Pos.y, Config.Zones.Cloakroom.Pos.z)
  SetBlipSprite(BlipCloakRoom, Config.Zones.Cloakroom.BlipSprite)
  SetBlipColour(BlipCloakRoom, Config.Zones.Cloakroom.BlipColor)
  SetBlipAsShortRange(BlipCloakRoom, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(Config.Zones.Cloakroom.BlipName)
  EndTextCommandSetBlipName(BlipCloakRoom)
end)

function drawBlip(coords, icon, text, shortRange)

  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

  SetBlipSprite (blip, icon)
  SetBlipDisplay(blip, 4)
  SetBlipScale  (blip, 0.9)
  SetBlipColour (blip, 5)
  SetBlipAsShortRange(blip, shortRange)

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(text)
  EndTextCommandSetBlipName(blip)
  table.insert(salvageBlips, blip)

end

function refreshBlips()
	deleteBlips()

	if PlayerData.job.name ~= nil and PlayerData.job.name == Config.JobName then
		drawBlip(Config.Zones.Cloakroom.Pos, 366, "Locker Room", false)
		if onDuty then
			drawBlip(Config.Zones.VehicleSpawner.Pos, 315, "Vehicle Spawner", true)
		end
	end
end

function deleteBlips()
  if salvageBlips[1] ~= nil then
    for i = 1, #salvageBlips, 1 do
      RemoveBlip(salvageBlips[i])
      salvageBlips[i] = nil
    end
  end
end


Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if PlayerData.job ~= nil then
			local coords = GetEntityCoords(PlayerPedId())

			if PlayerData.job.name == Config.JobName then
				if onDuty then

					for k,v in pairs(Config.Zones) do
						if v ~= Config.Zones.Cloakroom then
							if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
								DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
							end
						end
					end

				end

				local Cloakroom = Config.Zones.Cloakroom
				if(Cloakroom.Type ~= -1 and GetDistanceBetweenCoords(coords, Cloakroom.Pos.x, Cloakroom.Pos.y, Cloakroom.Pos.z, true) < Config.DrawDistance) then
					DrawMarker(Cloakroom.Type, Cloakroom.Pos.x, Cloakroom.Pos.y, Cloakroom.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Cloakroom.Size.x, Cloakroom.Size.y, Cloakroom.Size.z, Cloakroom.Color.r, Cloakroom.Color.g, Cloakroom.Color.b, 100, false, true, 2, false, false, false, false)
				end
			else
				Citizen.Wait(500)
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		if PlayerData.job ~= nil then
			local coords      = GetEntityCoords(PlayerPedId())
			local isInMarker  = false
			local currentZone = nil

			if PlayerData.job.name == Config.JobName then
        local Cloakroom = Config.Zones.Cloakroom
        if(GetDistanceBetweenCoords(coords, Cloakroom.Pos.x, Cloakroom.Pos.y, Cloakroom.Pos.z, true) <= Cloakroom.Size.x) then
          isInMarker  = true
          currentZone = "Cloakroom"
        end

        if onDuty then
					for k,v in pairs(Config.Zones) do
						if v ~= Config.Zones.Cloakroom then
							if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) <= v.Size.x) then
								isInMarker  = true
								currentZone = k
							end
						end
					end

          local VehicleDeleter = Config.Zones.VehicleDeleter
  				if(GetDistanceBetweenCoords(coords, VehicleDeleter.Pos.x, VehicleDeleter.Pos.y, VehicleDeleter.Pos.z, true) <= VehicleDeleter.Size.x) then
  					isInMarker  = true
  					currentZone = "VehicleDeleter"
  				end
        end
			end

			if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
				HasAlreadyEnteredMarker = true
				LastZone                = currentZone
				TriggerEvent('esx_oceansalvage:hasEnteredMarker', currentZone)
			end
			if not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_oceansalvage:hasExitedMarker', LastZone)
			end
		end
	end
end)

-- Action après la demande d'accés
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		if CurrentAction ~= nil then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if (IsControlJustReleased(1, Keys["E"]) or IsControlJustReleased(2, Keys["RIGHT"])) and PlayerData.job ~= nil then
				local playerPed = PlayerPedId()

				if PlayerData.job.name == Config.JobName then
					if CurrentAction == 'cloakroom_menu' then

						if IsPedInAnyVehicle(playerPed, false) then
							ESX.ShowNotification(_U('in_vehicle'))
						else
							CloakRoomMenu()
						end

					elseif CurrentAction == 'vehiclespawn_menu' then

						if IsPedInAnyVehicle(playerPed, false) then
							ESX.ShowNotification(_U('in_vehicle'))
						else
							VehicleMenu()
						end

					elseif CurrentAction == 'delete_vehicle' then

						local playerPed = PlayerPedId()
						local vehicle = GetVehiclePedIsIn(playerPed, false)
						if IsPedInAnyVehicle(playerPed, false) and IsVehicleModel(GetVehiclePedIsIn(playerPed, false), GetHashKey("dinghy")) then
							DeleteVehicle(vehicle)
						end

					end

					CurrentAction = nil
				end
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if IsControlJustReleased(1, Keys["F6"]) and PlayerData.job ~= nil and PlayerData.job.name == Config.JobName then

			if Onjob then
				StopNPCJob(true)
				RemoveBlip(Blips['NPCTargetPool'])
				Onjob = false
			else
				local playerPed = PlayerPedId()

				if IsPedInAnyVehicle(playerPed, false) and IsVehicleModel(GetVehiclePedIsIn(playerPed, false), GetHashKey("dinghy")) then
					StartNPCJob()
					Onjob = true
				else
					ESX.ShowNotification(_U('not_good_veh'))
				end
			end
		end
	end
end)

function setUniform(job)
	TriggerEvent('skinchanger:getSkin', function(skin)

		if skin.sex == 0 then
			if Config.Uniforms[job].male ~= nil then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].male)
			else
				ESX.ShowNotification(_U('locker_nooutfit'))
			end
		else
			if Config.Uniforms[job].female ~= nil then
				TriggerEvent('skinchanger:loadClothes', skin, Config.Uniforms[job].female)
			else
				ESX.ShowNotification(_U('locker_nooutfit'))
			end
		end

	end)
end

function OpenShop()
	ESX.UI.Menu.CloseAll()
	local elements = {}

	for k, v in pairs(ESX.GetPlayerData().inventory) do
		local price = Config.Itemsprice[v.name]

		if price and v.count > 0 then
			table.insert(elements, {
				label = ('%s - <span style="color:green;">%s</span>'):format(v.label, _U('item', ESX.Math.GroupDigits(price))),
				name = v.name,
				price = price,

				-- menu properties
				type = 'slider',
				value = 1,
				min = 1,
				max = v.count
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sell_salvage', {
		title    = _U('shop_title'),
		align    = 'right',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent('esx_oceansalvage:sellSalvage', data.current.name, data.current.value)
    menu.close()
	end, function(data, menu)
		menu.close()
	end)
end


AddEventHandler('onResourceStop', function(resource)
  local menuOpen = ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'jewel_trader')
  if menuOpen then
    ESX.UI.Menu.CloseAll()
  end
end)


-- Create Blips
Citizen.CreateThread(function()
	local SellSalvage = AddBlipForCoord(Config.Blips.Shop.coords.x, Config.Blips.Shop.coords.y, Config.Blips.Shop.coords.z)
	SetBlipSprite(SellSalvage, Config.Blips.Shop.sprite)
	SetBlipScale(SellSalvage, 0.8)
	SetBlipAsShortRange(SellSalvage, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(Config.Blips.Shop.name)
	EndTextCommandSetBlipName(SellSalvage)
end)

-- Create NPC
Citizen.CreateThread(function()
  if Config.NPCEnable == true then
		RequestModel(Config.NPCHash)
		while not HasModelLoaded(Config.NPCHash) do
			Wait(1)
		end

	--PROVIDER
		jewel_buyer = CreatePed(1, Config.NPCHash, Config.NPCShop.x, Config.NPCShop.y, Config.NPCShop.z, Config.NPCShop.h, false, true)
		SetBlockingOfNonTemporaryEvents(jewel_buyer, true)
		SetPedDiesWhenInjured(jewel_buyer, false)
		SetPedCanPlayAmbientAnims(jewel_buyer, true)
		SetPedCanRagdollFromPlayerImpact(jewel_buyer, false)
		SetEntityInvincible(jewel_buyer, true)
		FreezeEntityPosition(jewel_buyer, true)
		TaskStartScenarioInPlace(jewel_buyer, "WORLD_HUMAN_SMOKING", 0, true);
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.Blips.Shop.coords, true) < 3.0 then
			local menuOpen = ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'jewel_trader')
      if not menuOpen then
				ESX.ShowHelpNotification(_U('shop_prompt'))

				if IsControlJustReleased(0, 38) then
					wasOpen = true
					OpenShop()
				end
			else
				Citizen.Wait(500)
			end
		else
			if wasOpen then
				wasOpen = false
				ESX.UI.Menu.CloseAll()
			end

			Citizen.Wait(500)
		end
	end
end)
