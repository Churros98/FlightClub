-- Gestion du métier de mécanicien aéronautique

-- Gestion des mécanicien
local MenuMeca = RageUI.CreateMenu("Mécanicien", "Gestion de l'avion");
MenuMeca.EnableMouse = true;

local plane = nil;
local rope = {};
local canDetach = false;
local tugPlane = nil;
local missile = { 0 };
local missileCount = 0;
local justOpen = false;

-- Vérifie si le joueur peut réparer
function canRepair(vehicle, distance)
	local model = GetEntityModel(vehicle)

	if vehicle ~= nil and GetEntityHealth(vehicle) ~= 0 and (distance == nil or distance < Config.mechanic.menuDistance) then
		if IsThisModelAPlane(model) or IsThisModelAHeli(model) then
			-- Si ont peut réparer à l'intérieur, alors aucun problème
			if Config.mechanic.repairOutside then
				return true
			end

			-- Sinon, je vérifie si le véhicule et dans une des zones d'intêret
			for k,pos in pairs(Config.mechanic.repairZones) do
				local center = vector3(pos.x, pos.y, pos.z)
				local plane_coords = GetEntityCoords(vehicle)
				if Vdist(vector3(center.x, center.y, 13) , vector3(plane_coords.x, plane_coords.y, 13)) < pos.d then
					return true
				end
			end
		end	
	end

	return false
end

-- Vérifie si le modele est autorisé
function canModelFillAmmo(vehicle)
	for k, modelname in ipairs(Config.mechanic.fillAmmoPlanes) do
		local requested_model = modelname
		local plane_model = GetEntityModel(vehicle)
		if requested_model == plane_model then
			return true
		end
	end

	return false
end

-- Vérifie si le joueur peut recharger
function canFillAmmo(vehicle, distance)
	local model = GetEntityModel(vehicle)

	if vehicle ~= nil and GetEntityHealth(vehicle) ~= 0 and (distance == nil or distance < Config.mechanic.menuDistance) then
		if IsThisModelAPlane(model) or IsThisModelAHeli(model) then
			-- Si l'avion en question est autoriser
			if canModelFillAmmo(vehicle) == false then
				return false
			end

			-- Si ont peut réparer à l'intérieur, alors aucun problème
			if Config.mechanic.fillAmmoOutside then
				return true
			end

			-- Sinon, je vérifie si le véhicule et dans une des zones d'intêret
			for k,pos in pairs(Config.mechanic.fillAmmoZones) do
				local center = vector3(pos.x, pos.y, pos.z)
				local plane_coords = GetEntityCoords(vehicle)
				if Vdist(vector3(center.x, center.y, 13) , vector3(plane_coords.x, plane_coords.y, 13)) < pos.d then
					return true
				end
			end
		end
	end

	return false
end

-- Vérifie si le joueur peut treuiller un avion
function canTug(vehicle, distance)
	local model = GetEntityModel(vehicle)

	if vehicle ~= nil and GetEntityHealth(vehicle) ~= 0 and (distance == nil or distance < Config.mechanic.tugDistance) then
		-- Si c'est un avion qui posséde le bon squelette
		if IsThisModelAPlane(model) and  GetEntityBoneIndexByName(vehicle, "gear_f") ~= -1 then
			-- Je récupére le véhicule actuel du joueur
			local vecPlayer = GetVehiclePedIsIn(GetPlayerPed(-1), false)

			-- Si nous somme dans le chariot de déplacement
			if IsVehicleModel(vecPlayer, `airtug`) then
				return true
			end
		end	
	end

	return false
end

-- Dessine les markers un par un (avec la bonne position au sol)
function DrawMecaMarker(pos)
	local boolean,groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false);

	DrawMarker(
		Config.mechanic.marker,
		pos.x,
		pos.y,
		groundZ,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		Config.mechanic.scale,
		Config.mechanic.scale,
		Config.mechanic.scale,
		Config.mechanic.rgba_marker[1],
		Config.mechanic.rgba_marker[2],
		Config.mechanic.rgba_marker[3],
		Config.mechanic.rgba_marker[4],
		false,
		true,
		2,
		nil,
		nil,
		false
	)
end

-- Dessine les markers du mécanicien
function DrawMecaMarkers()
	-- Si ont affiche aucune aide, alors je passe cette fonction
	if Config.mechanic.showHelpMarkers == false then return end

	-- Dessine les markers de la zone de réparation
	if Config.mechanic.repairOutside == false then
		for k,pos in pairs(Config.mechanic.repairZones) do
			DrawMecaMarker(pos)
		end
	end

	-- Dessine les markers de la zone de rechargement de munition
	if Config.mechanic.fillAmmoOutside == false then
		for k,pos in pairs(Config.mechanic.fillAmmoZones) do
			DrawMecaMarker(pos)
		end
	end
end

-- Répare les pannes relative au accidents
function fixPanne(plane)
	if IsThisModelAHeli(GetEntityModel(plane)) then
		SetHelicopterRollPitchYawMult(plane, 1.0)
	else
		-- Selon les accidents
	end
end

function RageUI.PoolMenus:MecaAir()
	MenuMeca:IsVisible(function(Items)
		-- Mets à jour les données
		if RageUI.Visible(MenuMeca) and justOpen == false then
			if plane ~= nil and DoesEntityExist(plane) and DoesVehicleHaveWeapons(plane) then
				TriggerServerEvent('FlightClub:GetPlaneAmmo', NetworkGetNetworkIdFromEntity(plane))
			end
			justOpen = true
		end

		-- Rend à l'écran
		if canRepair(plane, nil) then
			Items:AddSeparator("Gestion de l'avion")
			Items:AddButton("Réparer", "Réparer l'avion.", { IsDisabled = false }, function(onSelected)
				if (onSelected) then
					if plane ~= nil and DoesEntityExist(plane) then
						RequestAnimDict(Config.dropbox.animationDict)
						while (not HasAnimDictLoaded(Config.dropbox.animationDict)) do Citizen.Wait(0) end

						
						fixPanne(plane)
						SetVehicleFixed(plane)
						ESX.ShowNotification("L'avion a été réparé")
					end
				end
			end)
		end

		if canFillAmmo(plane, nil) then
			Items:AddSeparator("Gestion des munitions")
			Items:AddList("Missile", missile, missileCount + 1, nil, { IsDisabled = false }, function(Index, onSelected, onListChange)
				if (onListChange) then
					if DoesEntityExist(plane) then
						missileCount = Index - 1
						local planeid = NetworkGetNetworkIdFromEntity(plane)
						TriggerServerEvent('FlightClub:SetPlaneAmmo', planeid, missileCount)
					end
				end
			end)
		end
	end, function(Panels)
		Panels:Grid(GridX, GridY, "Top", "Bottom", "Left", "Right", function(X, Y, CharacterX, CharacterY)
			GridX = X;
			GridY = Y;
		end, 1)
	end)
end


-- Détache la corde
RegisterNetEvent('FlightClub:DeleteRope')
AddEventHandler('FlightClub:DeleteRope', function(PlaneNetID)
	print('delete rope')
	if rope[PlaneNetID] ~= nil then
		DeleteRope(rope[PlaneNetID])
		rope[PlaneNetID] = nil
	end
end)


-- Attache la corde
RegisterNetEvent('FlightClub:SetRope')
AddEventHandler('FlightClub:SetRope', function(PlaneNetID, PlayerNetID)
	print('set rope')

	local plane = NetworkGetEntityFromNetworkId(PlaneNetID)
	local player = NetworkGetEntityFromNetworkId(PlayerNetID)

	print(plane)
	print(player)

	if plane ~= 0 and player ~= 0 then
		-- Attache la roue d'un avion sur le véhicule pour le déplacer
		RopeLoadTextures()
		local pCoords = GetEntityCoords(player)
		rope[PlaneNetID] = AddRope(pCoords, 0.0, 0.0, 0.0, 15.0, 2, 10.0, 1.0, 0, 0, 0, 0, 0, 0, 0)
		local boneIndex = GetEntityBoneIndexByName(plane, "gear_f")
		local ropeCoords = GetWorldPositionOfEntityBone(plane,boneIndex)
		AttachRopeToEntity(rope[PlaneNetID], plane, ropeCoords, 1)
		AttachEntitiesToRope(rope[PlaneNetID],plane,player,ropeCoords,pCoords,100)
	end
end)

-- Execution du code à l'utilisation de la touche
Keys.Register("E", "E", "MecaAir", function()
	-- Si c'est pas activé, ont tue directement le thread
	if Config.mechanic.enabled == false then return end
	
	if plane ~= nil and canDetach  then
		local PlaneNetID = NetworkGetNetworkIdFromEntity(plane)

		-- Envoi un orde de détachement
		TriggerServerEvent('FlightClub:DetachRope', PlaneNetID)
		canDetach = false
	else
		if plane ~= nil and DoesEntityExist(plane) then
			-- Si nous somme dans le chariot de déplacement, alors ont fait l'action qui va bien
			if canTug(plane, nil) then
				local PlayerNetID = NetworkGetNetworkIdFromEntity(GetPlayerPed(-1))
				local PlaneNetID = NetworkGetNetworkIdFromEntity(plane)

				-- Envoi un orde de d'attachement
				TriggerServerEvent('FlightClub:AttachRope', PlaneNetID, PlayerNetID)
				canDetach = true
				-- Sinon, nous somme dans la configuration de réparation / rechargement
			elseif canRepair(plane, nil) or canFillAmmo(plane, nil) then
				RageUI.Visible(MenuMeca, not RageUI.Visible(MenuMeca))
			end
		end
	end
end)

-- Boucle de rendu du mécano
Citizen.CreateThread(function()
	-- Si c'est pas activé, ont tue directement le thread
	if Config.mechanic.enabled == false then return end

    while true do
        Citizen.Wait(1)
		
		-- Si le joueur est bien un mécanicien
		if IsPlayerJobOK(Config.mechanic.jobname) or not Config.inProduction then
			-- Je dessine les points d'intêret des mécano
			DrawMecaMarkers()
		end
	end
end)

-- Boucle principal de logique du mécano
Citizen.CreateThread(function()
	-- Si c'est pas activé, ont tue directement le thread
	if Config.mechanic.enabled == false then return end

    -- Récupére les informations du joueur
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
	
	for i=0, Config.weapons.maxAmmo do
		missile[i+1] = i
	end

    -- Boucle principal
    while true do
        -- Gére le métier de mécanicien
        Citizen.Wait(5)

        -- Si le joueur est bien un mécanicien
        if IsPlayerJobOK(Config.mechanic.jobname) or not Config.inProduction then

			-- Je récupére l'entité la plus proche (en évitant le véhicule utilisé)
			local vehicle, distance = GetClosestEntity("vehicle", GetVehiclePedIsIn(GetPlayerPed(-1)))

			if canDetach == false then
				if canTug(vehicle, distance) then
					ESX.ShowHelpNotification(Config.mechanic.tugMessage)
					plane = vehicle
				elseif canRepair(vehicle, distance) or canFillAmmo(vehicle, distance) then
					ESX.ShowHelpNotification(Config.mechanic.repairFillMessage)
					plane = vehicle
				else
					plane = nil
				end
			else
				ESX.ShowHelpNotification(Config.mechanic.untugMessage)
				-- Je récupére le véhicule actuel du joueur
				local vecPlayer = GetVehiclePedIsIn(GetPlayerPed(-1), false)

				-- Si nous ne somme plus dans le véhicule de transport, alors je détache la corde
				if IsVehicleModel(vecPlayer, GetHashKey('airtug')) == false then
					local PlaneNetID = NetworkGetNetworkIdFromEntity(plane)

					-- Envoi un orde de détachement
					TriggerServerEvent('FlightClub:DetachRope', PlaneNetID)
					canDetach = false
				end
			end

			-- Ont vérifie constament l'état du menu
			if not RageUI.Visible(MenuMeca) and justOpen == true then
				justOpen = false
			end

			-- Si il n'y a plus d'avion, alors que le menu et toujours visible, je ferme tous
			if plane == nil and RageUI.Visible(MenuMeca) then
				RageUI.CloseAll()
			end
		end
    end
end)

-- Reçois le nombre de munition pour l'avion actuelle
RegisterNetEvent('FlightClub:SetPlaneAmmo')
AddEventHandler('FlightClub:SetPlaneAmmo', function(ammo)
    missileCount = ammo
end)