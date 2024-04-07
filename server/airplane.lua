-- Centralise les données utile comme le nombre de munition d'une entitée, ou les pilotes disponible en ligne
-- Répond au demande d'un client

-- Ici seront défini les valeurs que je souhaite renvoyer à tous les clients par rapport à un avion
local airplanes = {}

--------------------------
-- Debug
--------------------------

-- Permet d'obtenir la liste des avions et leurs munition
-- Commande de Debug (A désactiver en production !)
RegisterCommand("planeammo", function()
    if Config.inProduction == false then
        for k,airplane in pairs(airplanes) do
            print("[NetID] Avion " .. tostring(k) .. " : " .. tostring(airplane["ammo"]))
        end
    end
end)

-- Si l'entité est détruite, alors je la supprime de la liste
AddEventHandler('entityRemoved', function(entity)
    local entity = entity
    if not DoesEntityExist(entity) then
        return
    end

    local entID = NetworkGetNetworkIdFromEntity(entity)
    if GetEntityType(entity) ~= 0 then
        if airplanes[entID] ~= nil then
            table.remove(airplanes, indexOf(airplanes[entID]))
            print("Supprimé.")
        end
    end
end)

-- Reçois une demande d'information des munition sur l'avion
RegisterNetEvent('FlightClub:GetPlaneAmmo')
AddEventHandler('FlightClub:GetPlaneAmmo', function(planeid)
    local info = airplanes[planeid]
    local ammo = 0
    if info ~= nil then
        ammo = info['ammo']
    else
        ammo = Config.weapons.startMissile
    end

    -- Je réponds à la demande avec le nombre de munition
    TriggerClientEvent('FlightClub:SetPlaneAmmo', source, ammo)
end)

-- Reçois une demande de modification des munitions sur l'avion
RegisterNetEvent('FlightClub:SetPlaneAmmo')
AddEventHandler('FlightClub:SetPlaneAmmo', function(planeid, ammo)
    -- J'enregistre les données
    -- ATTENTION : Risque d'une attaque DoS ?!
    local info = airplanes[planeid]
    if info ~= nil then
        airplanes[planeid]['ammo'] = ammo
    else
        airplanes[planeid] = {}
        airplanes[planeid]['ammo'] = ammo
    end

    -- Ont envoi une notification à tous les joueurs indiquant qu'un avion à été modifié
    -- Le client concerné sera détecté et demandera de mettre à jour le nombre de missile
    TriggerClientEvent('FlightClub:UpdatePlaneAmmo', -1)
end)

-- Reçois une demande de liste de pilote disponible et l'envoi
RegisterNetEvent('FlightClub:GetPilotsAvailable')
AddEventHandler('FlightClub:GetPilotsAvailable', function()
    -- Je cherche des pilotes connecté et en vol
    local pilots = {}
    local xPlayers = ESX.GetPlayers()
    
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        
        if xPlayer ~= nil and ((xPlayer.job ~= nil and xPlayer.job.name == Config.pilot.jobname) or not Config.inProduction) then
            local veh = GetVehiclePedIsIn(GetPlayerPed(xPlayer.source), false)
            if veh ~= 0 then
                local type = GetVehicleType(veh)
                if type == "plane" or type == "heli" then
                    table.insert(pilots, xPlayer)
                end
            end
        end
    end

    -- Je réponds à la demande avec la liste des avions
    TriggerClientEvent('FlightClub:GetPilotsAvailable', source, pilots)
end)