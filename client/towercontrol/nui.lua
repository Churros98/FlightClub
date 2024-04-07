-- Gestion de la tour de contrôle (Interface graphique)

isNUIDisplay = false

-- Callback : Quitte le menu (rend le contrôle)
RegisterNUICallback("exit", function(data)
    ShowTowerControlUI(false)
end)

-- Callback : Téléporte le joueur
RegisterNUICallback("teleport", function(data)
    StartPlayerTeleport(PlayerId(), data.x, data.y, 17.0, 0.0, false, true, true)
    
    while IsPlayerTeleportActive() do
      Citizen.Wait(0)
    end
end)

-- Boucle de logique : Requêtes des positions au serveur
Citizen.CreateThread(function()
    while true do
        -- Ont attend X secondes avant d'actualiser les données
        Citizen.Wait(Config.towercontrol.update_every)

        -- Si le HUD est bien visible, alors je demande les données au serveur
        if isNUIDisplay == true then
            TriggerServerEvent('FlightClub:GetPlanes')
        end
    end
end)

-- Reçois la liste des coordonnées du serveur, et la transmet à l'UI
RegisterNetEvent('FlightClub:SendPlanes')
AddEventHandler('FlightClub:SendPlanes', function(planes)
    -- Ont définie l'altitude ici (Impossible de le faire via le serveur)
    for key,value in pairs(planes) do
        local entity = NetworkGetEntityFromNetworkId(planes[key]['netid'])
        if entity == nil then
            planes[key] = nil
        else
            local altitude = planes[key]['alt']

            -- Ont vérifie si l'avion est dans une zone de contrôle renforcé
            local zoneRadar = false
            for k,pos in pairs(Config.towercontrol.airport_radars) do
                local center = vector3(pos.x, pos.y, pos.z)
                local plane_coords = planes[key]['coords']
                if Vdist(vector3(center.x, center.y, 13) , vector3(plane_coords.x, plane_coords.y, 13)) < pos.d then
                    zoneRadar = true
                end
            end

            -- Si n'est pas dans une zone renforcée mais que son altitude et supérieur au minimum, je l'affiche
            if zoneRadar == false and altitude < Config.towercontrol.minAlt then
                planes[key] = nil
            end
        end
    end

    -- Ont envoi les données à l'UI
    SendNUIMessage({
        type = "updateplanes",
        planes = planes
    })
end)

-- Affiche ou cache l'interface de la tour de controle
function ShowTowerControlUI(isShow)
    SetNuiFocus(isShow, isShow)
    SendNUIMessage({
        type = "ui",
        display = isShow
    })
    isNUIDisplay = isShow
end

-- Désactive les contrôle lorsque nous entront dans le menu
Citizen.CreateThread(function()
    while isNUIDisplay do
        Citizen.Wait(0)
        DisableControlAction(0, 1, display) -- LookLeftRight
        DisableControlAction(0, 2, display) -- LookUpDown
        DisableControlAction(0, 142, display) -- MeleeAttackAlternate
        DisableControlAction(0, 18, display) -- Enter
        DisableControlAction(0, 322, display) -- ESC
        DisableControlAction(0, 106, display) -- VehicleMouseControlOverride
    end
end)