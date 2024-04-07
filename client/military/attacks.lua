-- Gestion des missiles et des armes des avions / hélicos

-- Défini sur un joueur est bien pilote dans un véhicule volant
function IsPlayerInPlane()
    -- Si le joueur est bien le conducteur du véhicule
    if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId(), false), -1) == PlayerPedId() then
        local vecType = GetVehicleClass(GetVehiclePedIsIn(PlayerPedId(), false))
        if vecType == 15 then
            return true
        elseif vecType == 16 then
            return true
        else
            return false
        end
    end

    return false
end

-- Vérifie si l'arme est un missile
function verifyWeapon(weapon)
    if weapon == `VEHICLE_WEAPON_PLANE_ROCKET` then return true
    elseif weapon == `VEHICLE_WEAPON_SPACE_ROCKET` then return true
    elseif weapon == `WEAPON_VEHICLE_ROCKET` then return true
    elseif weapon == `VEHICLE_WEAPON_PLANE_ROCKET` then return true
    elseif weapon == `WEAPON_PASSENGER_ROCKET` then return true
    elseif weapon == `WEAPON_AIRSTRIKE_ROCKET` then return true
    end

    return false
end

-- Variables
local isFirstMounting = false
local MissileAmmo = Config.weapons.startMissile

function ReloadMissileAmmo(count)
    MissileAmmo = count
end

function UpdateAttackPlane()
    -- Si le joueur est bien pilote de l'avion
    if IsPlayerInPlane() then
        local plane = GetVehiclePedIsIn(PlayerPedId(), false)
        local planeid = NetworkGetNetworkIdFromEntity(plane)
        local iscurrentweapon, currentWeaponHash = GetCurrentPedVehicleWeapon(PlayerPedId())

        -- Je demande au serveur de me retourner le nombre de missile restant dans l'avion actuel et je bloque les armes configurer
        if isFirstMounting == false then
            if (iscurrentweapon) then -- Si l'avion et capable de tirer, alors je fait comme d'habitude
                TriggerServerEvent('FlightClub:GetPlaneAmmo', planeid)
            else -- Sinon, je défini -1 pour ne pas avoir à recharger
                TriggerServerEvent('FlightClub:SetPlaneAmmo', planeid, -1)
            end

            for i, k in ipairs(Config.weapons.notAllowed) do
                DisableVehicleWeapon(true, k, plane, PlayerPedId())
            end

            isFirstMounting = true
        end

        -- S'il n'y a plus de missile, alors j'interdit le tir (Avion et hélico). Sinon j'autorise
        if MissileAmmo == 0 then
            DisableVehicleWeapon(true, `VEHICLE_WEAPON_PLANE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(true, `VEHICLE_WEAPON_SPACE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(true, `WEAPON_VEHICLE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(true, `WEAPON_PASSENGER_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(true, `WEAPON_AIRSTRIKE_ROCKET`, plane, PlayerPedId())
        else
            DisableVehicleWeapon(false, `VEHICLE_WEAPON_PLANE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(false, `VEHICLE_WEAPON_SPACE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(false, `WEAPON_VEHICLE_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(false, `WEAPON_PASSENGER_ROCKET`, plane, PlayerPedId())
            DisableVehicleWeapon(false, `WEAPON_AIRSTRIKE_ROCKET`, plane, PlayerPedId())
        end

        -- Vérifie si le joueur tire bien une rocket
        if IsPedShooting(PlayerPedId()) and verifyWeapon(currentWeaponHash) then
            MissileAmmo = MissileAmmo - 1
            TriggerServerEvent('FlightClub:SetPlaneAmmo', planeid, MissileAmmo)
        end
    else
        isFirstMounting = false
    end
end

-- Reçois le nombre de munition pour l'avion actuelle
RegisterNetEvent('FlightClub:SetPlaneAmmo')
AddEventHandler('FlightClub:SetPlaneAmmo', function(ammo)
    MissileAmmo = ammo
end)

-- Reçois une demande de mise à jour de la part du serveur
RegisterNetEvent('FlightClub:UpdatePlaneAmmo')
AddEventHandler('FlightClub:UpdatePlaneAmmo', function()
    isFirstMounting = false
end)

-- Boucle principal de logique de la conduite de tir
Citizen.CreateThread(function()
    -- Boucle principal
    while true do
        Citizen.Wait(1)
        UpdateAttackPlane()
    end
end)