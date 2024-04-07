-- Gestion du catapultage de caisses
-- Basée sur le code de Vechro (https://github.com/Vechro/cratedrop)

local boxHash = GetHashKey('prop_box_ammo03a_set2')
local parachuteHash = GetHashKey('p_parachute1_mp_s')
local fumigeneHash = GetHashKey('weapon_flare')

local boxObj = nil
local parachuteObj = nil

-- Variable pour les menus
local MenuDrop = RageUI.CreateMenu("Caisse de largage", "Gestion de la caisse")
MenuDrop.EnableMouse = true
local justOpen = false

-- Variable de gestion des inventaires
local dropboxContent = nil
local playerContent = nil
local updateTable = nil

-- Variable pour l'avion
local isFirstDropboxMounting = false
local isDropboxExist = false
local isDropboxExistOutside = false
local isDropboxInProximity = false
local isDropboxCompatible = false
local isLowAlt = false
local pressTimer = 0
local boxCheck = 0
local planeCheck = 0
local capturePerc = 0
local boxLoc = nil

-- Variable pour les animations en réseau
local animPlayers = {}

-- Commande de Debug : Fait apparaitre une dropbox
RegisterCommand("dummybox", function()
    if Config.inProduction == false then
        Dropbox(-1337)
    end
end)

-- Permet de récupérer une Quantité par le joueur
function InputQty()
    DisplayOnscreenKeyboard(1, "Quantité", "", "", "", "", "", 30)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        local result = tonumber(GetOnscreenKeyboardResult())
        if result == nil then result = 0 end
        return result
    end

    return 0
end

-- Permet de tenir les comptes dans le tableau des mises à jour
function TableUpdate(name, count)
    if updateTable == nil then updateTable = {} end

    local done = false
    for uname, ucount in pairs(updateTable) do
        if uname == name then
            updateTable[uname] = updateTable[uname] + count
            if updateTable[uname] <= 0 then
                updateTable[uname] = nil
            end
            done = true
        end
    end

    if done == false then
        updateTable[name] = count
        done = true
    end

    return done
end

-- Permet de give un item dans l'inventaire "Caisse"
function GiveItemToDropbox(name, count)
    if dropboxContent == nil then return false end
    local done = false

    for dname, dcount in pairs(dropboxContent) do
        if dname == name then
            dropboxContent[dname] = dcount + count
            done = true
        end
    end

    if done == false then
        dropboxContent[name] = count
        done = true        
    end

    return done
end

-- Permet de supprimé un item dans l'inventaire "Caisse"
function RemoveItemFromDropbox(name, count)
    if dropboxContent == nil then return false end
    local done = false

    for dname, dcount in pairs(dropboxContent) do
        if dname == name then
            if dcount >= count then
                dropboxContent[dname] = dcount - count
                if dropboxContent[dname] <= 0 then
                    dropboxContent[dname] = nil
                end

                done = true
            end
        end
    end

    return done
end

-- Permet de give un item dans l'inventaire "Joueur"
function GiveItemToPlayer(name, count)
    if playerContent == nil then return false end
    local done = false

    for item, c in pairs(playerContent) do
        if name == item then
            playerContent[name] = c + count
            done = true
        end
    end

    if done == false then
        playerContent[name] = count
    end

    TableUpdate(name, count)
    return done
end

-- Permet de supprimé un item dans l'inventaire "Joueur"
function RemoveItemFromPlayer(name, count)
    if playerContent == nil then return false end
    local done = false

    for item, c in pairs(playerContent) do
        if name == item then
            if c >= count then
                playerContent[name] = c - count
                if playerContent[name] <= 0 then
                    playerContent[name] = nil
                end

                done = true
                TableUpdate(name, count * -1)
            end
        end
    end

    return done
end

-- Permet la synchronisation de l'inventaire du joueur avec le serveur
function SynchInventory(IsInPlane, EntID)
    if updateTable ~= nil then
        TriggerServerEvent("FlightClub:SynchInventory", IsInPlane, EntID, updateTable)
    end

    dropboxContent = nil
    playerContent = nil
    updateTable = nil
end

-- Menu de gestion du drop
function RageUI.PoolMenus:DropAir()
	MenuDrop:IsVisible(function(Items)
		-- Rend à l'écran
        Items:AddSeparator("→ Caisse ←")
        
        local caisse_count = 0
        for name, count in pairs(dropboxContent) do
            if name ~= nil then
                Items:AddButton(name, "Appuyer pour déplacer", { RightLabel = tostring(count), IsDisabled = false }, function(onSelected)
                    if (onSelected) then
                        -- Je demande le nombre
                        local qty = InputQty()

                        -- J'essaye de retirer le nombre d'item dans la caisse
                        if (RemoveItemFromDropbox(name, qty)) then
                            -- Si j'ai réussi, alors je les ajoute
                            GiveItemToPlayer(name, qty)
                        end
                    end
                end)
            end

            caisse_count = caisse_count + 1
        end

        if caisse_count == 0 then
            Items:AddButton("Aucun item", "Aucun item", { IsDisabled = true }, function(onSelected)
            end)
        end

        Items:AddSeparator("→ Inventaire ←")
        
        local inv_count = 0
        for item, count in pairs(playerContent) do
            if item ~= nil and count ~= nil then
                Items:AddButton(item, "Appuyer pour déplacer", { RightLabel = tostring(count), IsDisabled = false }, function(onSelected)
                    if (onSelected) then
                        -- Je demande le nombre
                        local qty = InputQty()

                        -- J'essaye de retirer le nombre d'item du joueur
                        if (RemoveItemFromPlayer(item, qty)) then
                            -- Si j'ai réussi, alors je les ajoute à la caisse
                            GiveItemToDropbox(item, qty)
                        end
                    end
                end)
            end

            inv_count = inv_count + 1
        end

        if inv_count == 0 then
            Items:AddButton("Aucun item", "Aucun item", { IsDisabled = true }, function(onSelected)
            end)
        end

	end, function(Panels)
		Panels:Grid(GridX, GridY, "Top", "Bottom", "Left", "Right", function(X, Y, CharacterX, CharacterY)
			GridX = X;
			GridY = Y;
		end, 1)
	end)
end

-- Reçois la réponse du contenue de la dropbox dans l'avion
RegisterNetEvent('FlightClub:ShowDropboxInventoryInPlane')
AddEventHandler('FlightClub:ShowDropboxInventoryInPlane', function(dropContent, pContent)
    print('ShowDropboxInventoryInPlane')
    dropboxContent = dropContent
    playerContent = pContent
    RageUI.Visible(MenuDrop, not RageUI.Visible(MenuDrop))
end)

-- Reçois la réponse pour la dropbox
RegisterNetEvent('FlightClub:IsDropboxExistInPlane')
AddEventHandler('FlightClub:IsDropboxExistInPlane', function(result, inplane)
    if inplane then
        isDropboxExist = result
    else
        isDropboxExistOutside = result
    end
end)

-- La caisse est disponible (après la mise en place de la caisse dans l'avion)
RegisterNetEvent('FlightClub:DropboxAvailable')
AddEventHandler('FlightClub:DropboxAvailable', function()
    print('DropboxAvailable')
    isDropboxExist = true
end)

-- La caisse est bien compatible
RegisterNetEvent('FlightClub:DropboxCompatible')
AddEventHandler('FlightClub:DropboxCompatible', function()
    print('DropboxCompatible')
    isDropboxCompatible = true
end)

-- Un joueur est en train de capturer une caisse
RegisterNetEvent('FlightClub:DropboxInCapture')
AddEventHandler('FlightClub:DropboxInCapture', function(playerID)
    print('DropboxInCapture')
    local player = NetworkGetEntityFromNetworkId(playerID)
    if player ~= nil then
        print("anim")
        RequestAnimDict(Config.dropbox.animationDict)
        while (not HasAnimDictLoaded(Config.dropbox.animationDict)) do Citizen.Wait(0) end
        TaskPlayAnim(player, Config.dropbox.animationDict, Config.dropbox.animation, 1.0, -1.0, 5000, 0, 1, true, true, true)
    end
end)


-- Un joueur arrête de capturer une caisse
RegisterNetEvent('FlightClub:DropboxStopCapture')
AddEventHandler('FlightClub:DropboxStopCapture', function(playerID)
    print('DropboxStopCapture')
    local player = NetworkGetEntityFromNetworkId(playerID)
    if player ~= nil then
        StopAnimTask(player, Config.dropbox.animationDict, Config.dropbox.animation, 0)
    end
end)

-- Déploie une Dropbox
function Dropbox(PlaneID)
    -- Ont créer un thread par caisse
    Citizen.CreateThread(function()
        -- Ont viens charger la caisse
        if not HasModelLoaded(boxHash) then
            RequestModel(boxHash)

            while not HasModelLoaded(boxHash) do
                Citizen.Wait(1)
            end
        end

        -- Ont viens charger le parachute
        if not HasModelLoaded(parachuteHash) then
            RequestModel(parachuteHash)

            while not HasModelLoaded(parachuteHash) do
                Citizen.Wait(1)
            end
        end

        -- Ont viens charger le fumigène
        RequestWeaponAsset(fumigeneHash)
        while not HasWeaponAssetLoaded(fumigeneHash) do
            Wait(0)
        end

        -- Ont récupére les coordonnées actuelle et ont descend de 5 vers le bas
        local current_loc = GetEntityCoords(GetPlayerPed(-1)) + vector3(0, 0, -5)

        -- Si nous somme en mode debug, juste à coté du joueur
        if PlaneID == -1337 then
            current_loc = GetEntityCoords(GetPlayerPed(-1)) + vector3(0, 5, 10)
        end

        -- Fait apparaitre la caisse
        boxObj = CreateObject(boxHash, current_loc, true, true, true)
        print(boxObj)
        SetEntityLodDist(boxObj, 1000)
        ActivatePhysics(boxObj)
        SetDamping(boxObj, 2, 0.1)
        SetEntityVelocity(boxObj, 0.0, 0.0, -0.2)
        SetEntityDynamic(boxObj, true)

        -- J'envois l'information que la caisse est maintenant dans la nature
        local BoxID = NetworkGetNetworkIdFromEntity(boxObj)
        TriggerServerEvent("FlightClub:DropboxInNature", PlaneID, BoxID)

        -- Fait apparaitre le parachute
        parachuteObj = CreateObject(parachuteHash, current_loc, true, true, true)
        print(parachuteObj)
        SetEntityLodDist(parachuteObj, 1000)
        ActivatePhysics(parachuteObj)
        SetDamping(parachuteObj, 2, 0.1)
        SetEntityVelocity(parachuteObj, 0.0, 0.0, -0.2)
        SetEntityDynamic(parachuteObj, true)

        -- Ont attache la caisse et le parachute
        AttachEntityToEntity(parachuteObj, boxObj, 0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        -- Ont modifie le comportement des entitées pour tomber
        FreezeEntityPosition(parachuteObj, false)
        FreezeEntityPosition(boxObj, false)

        -- Lorsqu'ont atteint le niveau du sol, ont continue le script
        while GetEntityVelocity(boxObj).z ~= 0 do
            Wait(0)
        end

        -- Ont fait apparaitre le fumigène sur la caisse
        local boxObjCoords = vector3(GetEntityCoords(boxObj))
        ShootSingleBulletBetweenCoords(boxObjCoords, boxObjCoords - vector3(0.0001, 0.0001, 0.0001), 0, false, GetHashKey("weapon_flare"), 0, true, false, -1.0)

        -- Ont détache et supprime le parachute
        DetachEntity(parachuteObj, true, true)
        DeleteEntity(parachuteObj)
        parachuteObj = nil

        -- Ont créer un beep sonore à proximité de la caisse
        soundID = GetSoundId()
        PlaySoundFromEntity(soundID, "Crate_Beeps", boxObj, "MP_CRATE_DROP_SOUNDS", true, 0) -- crate beep sound emitted from the pi

        -- Vérifie que la caisse existe toujours
        while DoesEntityExist(boxObj) do
            Wait(10)
        end

        -- Ont vien supprimé le fumigène et la fumée
        while DoesObjectOfTypeExistAtCoords(parachuteCoords, 10.0, GetHashKey("w_am_flare"), true) do
            Wait(0)
            local prop = GetClosestObjectOfType(parachuteCoords, 10.0, GetHashKey("w_am_flare"), false, false, false)
            RemoveParticleFxFromEntity(prop)
            SetEntityAsMissionEntity(prop, true, true)
            DeleteObject(prop)
        end

        -- Ont stop le beep
        StopSound(soundID)
        ReleaseSoundId(soundID)

        -- Je supprime la caisse
        DeleteEntity(boxObj)

        -- Ont décharge le fumigène, le parachute et la caisse
        SetModelAsNoLongerNeeded(parachuteHash)
        SetModelAsNoLongerNeeded(boxHash)
        RemoveWeaponAsset(fumigeneHash)
    end)
end

-- Gére la capture des dropbox
function CaptureDropbox()
    -- Si le joueur est dans un véhicule, pas besoin de vérifier
    if GetVehiclePedIsIn(PlayerPedId(), false) > 0 then
        return
    end

    -- Ont récupére l'objet le plus proche
    local object, distance = GetClosestEntity("object", nil)

    -- Si un joueur est bien à coté d'une box
    if object ~= nil and GetEntityModel(object) == boxHash then
        local boxid = NetworkGetNetworkIdFromEntity(object)

        -- Je demande au serveur si la box est bien référencée
        if boxCheck ~= boxid then
            isDropboxCompatible = false
            TriggerServerEvent("FlightClub:IsDropboxCompatible", boxid)
            boxCheck = boxid
        end

        -- Si ont reçois une confirmation
        if isDropboxCompatible then
            Wait(0)
            boxLoc = GetEntityCoords(object, false)
            local player_loc = GetEntityCoords(PlayerPedId(), false)
            if Vdist2(boxLoc, player_loc) < 10 then
                if IsControlPressed(0, Config.dropbox.input) then
                    if pressTimer == 0 then
                        pressTimer = GetGameTimer()

                        -- Récupére les joueurs à proximité et leurs indique que je suis en train de ramassé la caisse
                        local animPlayers = GetClosestPlayers(10.0)
                        TriggerServerEvent("FlightClub:DropboxInCapture", NetworkGetNetworkIdFromEntity(PlayerPedId()), animPlayers)
                    end

                    local timeleft = (GetGameTimer() - pressTimer)
                    
                    if timeleft > 0 then
                        capturePerc = (100*timeleft)/Config.dropbox.captureTime
                    end

                    if  timeleft > Config.dropbox.captureTime then
                        TriggerServerEvent("FlightClub:DropboxOpen", boxid)
                        TriggerServerEvent("FlightClub:DropboxStopCapture", NetworkGetNetworkIdFromEntity(PlayerPedId()), animPlayers)
                        DeleteEntity(object)
                        isDropboxInProximity = false
                        pressTimer = 0
                        capturePerc = 0
                    end
                else
                    if pressTimer > 0 then
                        local animPlayers = GetClosestPlayers(10.0)
                        TriggerServerEvent("FlightClub:DropboxStopCapture", NetworkGetNetworkIdFromEntity(PlayerPedId()), animPlayers)
                    end

                    pressTimer = 0
                    capturePerc = 0
                end

                isDropboxInProximity = true
            else
                pressTimer = 0                
                capturePerc = 0
                isDropboxInProximity = false
            end
        end
    else
        isDropboxInProximity = false
    end
end

-- Gére le déploiement d'une caisse dans la nature (Largage)
function PlaneDropbox()
    -- Si le joueur est bien pilote de l'avion
    if IsPlayerInPlane() then
        local plane = GetVehiclePedIsIn(PlayerPedId(), false)
        local planeid = NetworkGetNetworkIdFromEntity(plane)

        -- Je demande au serveur de me retourner s'il y a une dropbox ou pas dans l'avion
        if isFirstDropboxMounting == false then
            isDropboxExist = false
            TriggerServerEvent('FlightClub:IsDropboxExistInPlane', planeCheck, true)
            isFirstDropboxMounting = true
        end

        if isDropboxExist then
            -- Je vérifie que nous avons bien la bonne altitude
            local alt = GetEntityHeightAboveGround(plane)
            if alt > Config.dropbox.minAlt then
                isLowAlt = false
            else
                isLowAlt = true
            end

            if IsControlJustReleased(0,  Config.dropbox.input) and isLowAlt == false then
                Dropbox(planeid)
                isDropboxExist = false
            end
        end
    else
        isDropboxExist = false
        isFirstDropboxMounting = false
    end
end

-- Gére la manipulation de l'inventaire de la dropbox
function InventoryDropbox()
    -- Si le joueur est dans un véhicule, pas besoin de vérifier
    if GetVehiclePedIsIn(PlayerPedId(), false) > 0 then
        -- Si le menu et toujours visible, je ferme tous
        if RageUI.Visible(MenuDrop) then
            RageUI.CloseAll()
            SynchInventory(true, planeCheck)
        end
        
        -- Je réinitialise l'avion dans le cas ou ont serait justement dedans
        isDropboxExistOutside = false
        planeCheck = 0
        return
    end

    -- Ont récupére l'objet le plus proche
    local vech, distance = GetClosestEntity("vehicle", nil)

    -- Si le véhicle est bien un avion à petite distance
    if vech ~= nil and IsThisModelAPlane(GetEntityModel(vech)) and distance < 10 then        
        local planeid = NetworkGetNetworkIdFromEntity(vech)

        -- Si l'avion n'a pas déjà été vérifier, alors je demande au serveur si une caisse existe à l'intérieur
        if planeCheck ~= planeid then
            isDropboxExistOutside = false
            TriggerServerEvent('FlightClub:IsDropboxExistInPlane', planeid, false)
            planeCheck = planeid
        end

        -- Si une caisse existe, alors je prépare la logique
        if isDropboxExistOutside then
            -- Je mets à jour l'inventaire à la fermeture du menu
            if RageUI.Visible(MenuDrop) == false and dropboxContent ~= nil then
                SynchInventory(true, planeCheck)
            end
        end
    else
        -- Si le menu et toujours visible, je ferme tous
        if RageUI.Visible(MenuDrop) then
            RageUI.CloseAll()
            SynchInventory(true, planeCheck)
        end

        -- Je réinitialise l'avion lorsqu'on quitte la zone
        isDropboxExistOutside = false
        planeCheck = 0
    end
end

-- Boucle principal de logique du largage de caisse
Citizen.CreateThread(function()
    -- Boucle principal
    while Config.dropbox.enabled do
        Citizen.Wait(100)
        PlaneDropbox()
        InventoryDropbox()
        CaptureDropbox()
    end
end)

function drawProgressBar(x, y, width, height, colour, percent)
    local w = width * (percent/100)
    local xW = (width/2) - ((width/2) * (percent/100))

    DrawRect(x, y, width, height, 255, 255, 255, 255)
    DrawRect(x - xW, y, w, height, colour[1], colour[2], colour[3], colour[4])
end

-- Boucle principal de logique d'affichage du largage de caisse
Citizen.CreateThread(function()
    -- Boucle principal
    while Config.dropbox.enabled do
        Citizen.Wait(1)

        if capturePerc > 0 then
            local retval, screenX, screenY = GetScreenCoordFromWorldCoord(boxLoc.x, boxLoc.y, boxLoc.z)
            if retval == false then
                screenX, screenY = 0.5, 0.5
            end
            
            drawProgressBar(screenX, screenY, 0.0990, 0.0185, {33, 78, 106, 255}, capturePerc)
        end

        if isDropboxExist then
            if isLowAlt then
                ESX.ShowHelpNotification(tostring(Config.dropbox.minAlt) .. "m d'altitude nécessaire pour le largage")
            else
                ESX.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ pour larger la caisse")
            end
        end

        if isDropboxInProximity then
            ESX.ShowHelpNotification("Maintenez sur ~INPUT_CONTEXT~ pour récupérer la caisse")
        end

        if isDropboxExistOutside then
            ESX.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ pour déposer des objets dans la caisse")
            if IsControlJustPressed(0, Config.dropbox.input) and RageUI.Visible(MenuDrop) == false then
                TriggerServerEvent('FlightClub:ShowDropboxInventoryInPlane', planeCheck)
            end
        end
    end
end)
