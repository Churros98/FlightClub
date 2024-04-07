-- Ici seront défini les valeurs que je souhaite renvoyer à tous les clients par rapport à un avion
local airplanes_dropbox = {}
local dropbox = {}

--------------------------
-- Debogage
--------------------------

-- Permet d'obtenir la liste des drops en cours
-- Commande de Debug (A désactiver en production !)
RegisterCommand("droplist", function()
    if Config.inProduction == false then
        for k,caisse in pairs(dropbox) do
            print("[NetID] Caisse " .. tostring(k) .. " :")
            for name, count in pairs(caisse) do
                print("Nom: " .. name .. " Qty: " .. tostring(count))
            end
        end
    end
end)

-- Permets d'obtenir la liste des caisses dans un avion en cours
-- Commande de Debug (A désactiver en production !)
RegisterCommand("planedroplist", function()
    if Config.inProduction == false then
        for k,avion in pairs(airplanes_dropbox) do
            print("[NetID] Avion " .. tostring(k) .. " :")
            for name,count in pairs(avion) do
                print("Nom: " .. name .. " Qty: " .. tostring(count))
            end
        end
    end
end)


--------------------------
-- Général
--------------------------

-- Reçois un inventaire modifié de la caisse par le joueur, l'objectif et de vérifier, comparer, appliquer en toute sécurité
RegisterNetEvent('FlightClub:SynchInventory')
AddEventHandler('FlightClub:SynchInventory', function(IsInPlane, EntID, updateTable)
    -- En cas ou ..
    if IsInPlane then
        if airplanes_dropbox[EntID] == nil then
            return
        end
    else
        if dropbox[EntID] == nil then
            return
        end
    end

    -- Je récupére l'objet du joueur
    local xPlayer = ESX.GetPlayerFromId(source)

    -- Je créer un tableau de comparaison avec l'inventaire actuel
    for name,count in pairs(updateTable) do
        -- Va vers le joueur
        if count > 0 then
            if IsInPlane then
                if airplanes_dropbox[EntID][name] >= count then
                    airplanes_dropbox[EntID][name] = airplanes_dropbox[EntID][name] - count
                    
                    if airplanes_dropbox[EntID][name] then
                        airplanes_dropbox[EntID][name] = nil
                    end

                    xPlayer.addInventoryItem(name, count)
                end
            else
                if dropbox[EntID][name] >= count then
                    dropbox[EntID][name] = dropbox[EntID][name] - count

                    if dropbox[EntID][name] then
                        dropbox[EntID][name] = nil
                    end

                    xPlayer.addInventoryItem(name, count)      
                end  
            end
        end
        
        -- Va vers la caisse
        if count < 0 then
            count = count * -1

            if IsInPlane then
                if xPlayer.getInventoryItem(name).count >= count then
                    xPlayer.removeInventoryItem(name, count)
                    if airplanes_dropbox[EntID][name] == nil then
                        airplanes_dropbox[EntID][name] = count
                    else
                        airplanes_dropbox[EntID][name] = airplanes_dropbox[EntID][name] + count
                    end
                end
            else
                if xPlayer.getInventoryItem(name).count >= count then
                    xPlayer.removeInventoryItem(name, count)
                    if dropbox[EntID][name] == nil then
                        dropbox[EntID][name] = count
                    else
                        dropbox[EntID][name] = dropbox[EntID][name] + count
                    end
                end
            end
        end

    end
end)

--------------------------
-- Avion
--------------------------

-- Ajoute une dropbox à un avion
function AddDropboxInPlane(entity)
    local entity = entity
    if not DoesEntityExist(entity) then
        return false
    end

    local entID = NetworkGetNetworkIdFromEntity(entity)
    if GetEntityType(entity) ~= 0 then
        airplanes_dropbox[entID] = {}

        return true
    end

    return false
end

-- Supprime une dropbox à un avion
function DeleteDropboxFromEntity(entity)
    local entity = entity
    if not DoesEntityExist(entity) then
        return
    end

    local entID = NetworkGetNetworkIdFromEntity(entity)
    if GetEntityType(entity) ~= 0 then
        if airplanes_dropbox[entID] ~= nil then
            airplanes_dropbox[entID] = nil
        end
    end
end

-- Supprime une dropbox à un avion (NetId)
function DeleteDropboxInPlane(entID)
    if airplanes_dropbox[entID] ~= nil then
        airplanes_dropbox[entID] = nil
    end
end

-- Une dropbox existe elle ?
function DropboxExistInPlane(entID)
    if airplanes_dropbox[entID] ~= nil then
        return true
    end

    return false
end

-- Transfert la dropbox de l'avion à la nature
function TransfertDropboxToNature(PlaneID, BoxID)
    if airplanes_dropbox[PlaneID] ~= nil then
        dropbox[BoxID] = airplanes_dropbox[PlaneID]
        airplanes_dropbox[PlaneID] = nil
    end
end

-- Retourne le contenue de la dropbox de l'avion (et du joueur)
RegisterNetEvent('FlightClub:ShowDropboxInventoryInPlane')
AddEventHandler('FlightClub:ShowDropboxInventoryInPlane', function(entID)
    -- Je réponds à la demande avec la réponse
    if airplanes_dropbox[entID] ~= nil then
        -- Je récupére l'inventaire du joueur
        local xPlayer = ESX.GetPlayerFromId(source)
        local playerInventory = xPlayer.getInventory(true)

        -- J'envoi l'inventaire de la dropbox et du joueur pour traitement
        TriggerClientEvent('FlightClub:ShowDropboxInventoryInPlane', source, airplanes_dropbox[entID], playerInventory)
    end
end)

-- Vérifie si l'avion est équiper d'une dropbox
RegisterNetEvent('FlightClub:IsDropboxExistInPlane')
AddEventHandler('FlightClub:IsDropboxExistInPlane', function(entID, playerinplane)
    -- Je réponds à la demande avec la réponse
    local inplane = DropboxExistInPlane(entID)
    TriggerClientEvent('FlightClub:IsDropboxExistInPlane', source, inplane, playerinplane)
end)

-- Supprime là dropbox de l'avion
RegisterNetEvent('FlightClub:DeleteDropboxInPlane')
AddEventHandler('FlightClub:DeleteDropboxInPlane', function(entID)
    DeleteDropboxInPlane(entID)
end)

--------------------------
-- Nature
--------------------------

--Supprime la dropbox
function DeleteDropbox(entID)
    if dropbox[entID] ~= nil then
        dropbox[entID] = nil
        return true
    end
end

-- Ajoute une dropbox dans la nature
function AddDropbox(entID, planeID)
    dropbox[entID] = {}
    return true
end

-- Give les objets de la dropbox à un joueur
function GiveDropboxObject(BoxID, PlayerID)
    local xPlayer = ESX.GetPlayerFromId(PlayerID)

    if dropbox[BoxID] ~= nil then
        for name,count in pairs(dropbox[BoxID]) do
            xPlayer.addInventoryItem(name, count)
        end
    end
end

-- La dropbox passe de l'avion à la nature
RegisterNetEvent('FlightClub:DropboxInNature')
AddEventHandler('FlightClub:DropboxInNature', function(PlaneID, BoxID)
    -- Si ont fait apparaître une caisse de debogage, alors j'ajoute de l'eau dedans, sinon je transfert
    if PlaneID ~= -1337 then
        TransfertDropboxToNature(PlaneID, BoxID)
    else
        dropbox[BoxID] = { water = 1 }
    end
end)

-- La dropbox est ouverte par le joueur
RegisterNetEvent('FlightClub:DropboxOpen')
AddEventHandler('FlightClub:DropboxOpen', function(BoxID)
    GiveDropboxObject(BoxID, source)
    DeleteDropbox(BoxID)
end)

-- La dropbox est en capture par un joueur
RegisterNetEvent('FlightClub:DropboxInCapture')
AddEventHandler('FlightClub:DropboxInCapture', function(playerID, closestPlayer)
    print("DropboxInCapture: " .. tostring(playerID))

    -- Je renvoi un fallback au joueur qui capture
    TriggerClientEvent('FlightClub:DropboxInCapture', playerID, playerID)
    
    -- Je renvois une notification à toute les personnes autour du joueur
    for _, BroadcastID in pairs(closestPlayer) do
        TriggerClientEvent('FlightClub:DropboxInCapture', BroadcastID, playerID)
    end
end)

-- La dropbox n'est plus capturé
RegisterNetEvent('FlightClub:DropboxStopCapture')
AddEventHandler('FlightClub:DropboxStopCapture', function(playerID, closestPlayer)
    -- Je renvoi un fallback au joueur qui capture
    TriggerClientEvent('FlightClub:DropboxStopCapture', playerID, playerID)

    -- Je renvois une notification à toute les personnes demander
    for _, BroadcastID in pairs(closestPlayer) do
        TriggerClientEvent('FlightClub:DropboxStopCapture', BroadcastID, playerID)
    end
end)


RegisterNetEvent('FlightClub:IsDropboxCompatible')
AddEventHandler('FlightClub:IsDropboxCompatible', function(BoxID)
    if dropbox[BoxID] ~= nil then
        TriggerClientEvent('FlightClub:DropboxCompatible', source)
    end
end)

-- Si l'entité est détruite, alors je la supprime de la liste
AddEventHandler('entityRemoved', function(entity)
    DeleteDropboxFromEntity(entity)
end)

-- Utilisation d'une dropbox
ESX.RegisterUsableItem('dropbox', function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local veh = GetVehiclePedIsIn(GetPlayerPed(xPlayer.source), false)
    if veh ~= 0 then
        local type = GetVehicleType(veh)
        if type == "plane" then
            local veh_model = GetEntityModel(veh)

            -- Vérifie si le model d'avion est autorisé
            for k,model in pairs(Config.dropbox.allowedPlanes) do
                if veh_model == model then

                    -- Ont vérifie s'il n'y à pas déjà une caisse, si oui, ont abandonne
                    local NetID = NetworkGetNetworkIdFromEntity(veh)
                    if DropboxExistInPlane(NetID) then
                        return
                    end

                    -- Ont supprime la dropbox de l'inventaire
                    xPlayer.removeInventoryItem('dropbox', 1)

                    -- Ont ajoute la dropbox à l'avion
                    AddDropboxInPlane(veh)
                    TriggerClientEvent('FlightClub:DropboxAvailable', xPlayer.source)
                end
            end
        end
    end
end)