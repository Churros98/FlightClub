-- FlightClub by Sweeeper

-- Préparation de ESX
ESX = nil
PlayerData = nil

-- Réceptionne une modification du joueur
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

-- Réceptionne une modification du joueur
RegisterNetEvent('FlightClub:UpdatePlayerData')
AddEventHandler('FlightClub:UpdatePlayerData', function(xPlayer)
	PlayerData = ESX.GetPlayerData()
end)

-- Mets a jour les données du joueur
function UpdatePlayerData()
    PlayerData = ESX.GetPlayerData()
end

-- Retourne si le joueur a le bon job ou pas
function IsPlayerJobOK(name)
    if PlayerData then
        if PlayerData.job.name == name then
            return true
        end
    end

    return false
end

-- Retourne l'entitée la plus proche
-- Crédit: DrAceMisanthrope sur https://forum.cfx.re/
function GetClosestEntity(type, skip)
	local closestEntity = -1
	local closestDistance = -1
	if type then
		local entities = {}
		if type == "ped" or type == 1 then
			entities = GetGamePool("CPed")
		elseif type == "vehicle" or type == 2 then
			entities = GetGamePool("CVehicle")
		elseif type == "object" or type == 3 then
			entities = GetGamePool("CObject")
		end
			
		local coords = GetEntityCoords(PlayerPedId())

		for _, entity in ipairs(entities) do
			local distance = #(coords - GetEntityCoords(entity))
			if distance < closestDistance or closestDistance == -1 then
				if skip == nil or GetEntityModel(entity) ~= GetEntityModel(skip) then
					closestEntity = entity
					closestDistance = distance
				end
			end
		end
	end
	return closestEntity, closestDistance
end

-- Permet de récupérer les joueurs à proximité
function GetClosestPlayers(maxDistance)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local ply = GetPlayerPed(-1)
    local plyCoords = GetEntityCoords(ply, 0)
	local playersZone = {}
    for index,value in ipairs(players) do

        local target = GetPlayerPed(value)
        if(target ~= nil and target ~= ply) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance = GetDistanceBetweenCoords(targetCoords['x'], targetCoords['y'], targetCoords['z'], plyCoords['x'], plyCoords['y'], plyCoords['z'], true)
            if not (closestDistance == -1 or distance > maxDistance) then
				table.insert(players, NetworkGetNetworkIdFromEntity(target))
            end
        end
    end

	table.insert(players, NetworkGetNetworkIdFromEntity(ply))

    return playersZone
end
