-- Commande de Debug (A désactiver en production !)
RegisterCommand("tc", function()
    if Config.inProduction == false then
        TriggerClientEvent('FlightClub:UpdatePlayerData', -1)
    end
end)

-- Reçois la demande de réception des positions, puis la traite
RegisterNetEvent('FlightClub:GetPlanes')
AddEventHandler('FlightClub:GetPlanes', function(data)
    local planes = {}

    -- Ont fait le tours de tous les véhicules en jeu
    for _, entity in pairs(GetAllVehicles()) do

        -- Récupére le type du véhicule
        local vecType = GetVehicleType(entity)

        -- Si c'est bien quelque chose qui vole, ont l'ajoute a notre table
        if vecType == "plane" or vecType == "heli" then
            -- Récupére les données du véhicule
            local coords = GetEntityCoords(entity, false)
            local netid = NetworkGetNetworkIdFromEntity(entity)
            local speed = GetEntitySpeed(entity)
            local plate = GetVehicleNumberPlateText(entity)

            -- Conversion du m/s en KMH ou MPH
            if Config.towercontrol.isKMH then
                speed = speed * 3.6
            else 
                speed = speed * 2.236936
            end

            -- Je récupére la rotation de l'avion
            local rotation = GetEntityRotation(entity)
            local angle = math.floor(rotation.z)
            if rotation.z < 0 then
                angle = angle + 360
            end
            angle = 360 - angle

            -- Défini les données à ajouter dans la table
            local data = {}
            data['netid'] = netid
            data['type'] = vecType
            data['speed'] = speed
            data['coords'] = coords
            data['plate'] = plate
            data['angle'] = angle
            data['alt'] = coords.z

            table.insert(planes, data)
        end
    end

    -- Je réponds à la demande avec notre table (source est une variable globale contenant le player_id du joueur ayant fait la requête)
    TriggerClientEvent('FlightClub:SendPlanes', source, planes)
end)