-- Gestion des téléporteurs
-- Permettant un accés rapide à des zones sans grande difficultée

-- Dessine le marker sur le sol
function DrawTeleportersMarker()
    for k,pos in pairs(Config.teleporters.all_positions) do
        DrawMarker(
            Config.teleporters.marker,
            pos.marker.x,
            pos.marker.y,
            pos.marker.z,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            Config.teleporters.scale,
            Config.teleporters.scale,
            Config.teleporters.scale,
            Config.teleporters.rgba_marker[1],
            Config.teleporters.rgba_marker[2],
            Config.teleporters.rgba_marker[3],
            Config.teleporters.rgba_marker[4],
            false,
            true,
            2,
            nil,
            nil,
            false
        )
    end
end

-- Si le joueur entre dans la zone d'un marker
function IsPlayerInTeleporterMarker() 
    for k,pos in pairs(Config.teleporters.all_positions) do
        local marker_loc = vector3(pos.marker.x, pos.marker.y, pos.marker.z)
        local player_loc = GetEntityCoords(PlayerPedId(), false)
        if Vdist2(marker_loc, player_loc) < (Config.teleporters.scale * 1.2) then
            return true
        end
    end

    return false
end

-- Vérifie si l'action est valide ou pas (et le dessine)
function IsEnterTeleportersAction()
    ESX.ShowHelpNotification(Config.teleporters.message)
    if IsControlJustPressed(0, Config.teleporters.control) then
        return true
    end

    return false
end

-- Récupére l'objet du téléporteur utilisé
function GetTeleporter()
    for k,pos in pairs(Config.teleporters.all_positions) do
        local marker_loc = vector3(pos.marker.x, pos.marker.y, pos.marker.z)
        local player_loc = GetEntityCoords(PlayerPedId(), false)
        if Vdist2(marker_loc, player_loc) < (Config.teleporters.scale * 1.2) then
            return pos
        end
    end

    return nil
end

-- Boucle de rendu du téléporteur
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        
		-- Je dessine les points d'intêret des mécano
        DrawTeleportersMarker()
	end
end)

-- Boucle principal de logique du téléporteur
Citizen.CreateThread(function()
    -- Boucle principal
    while true do
        -- Gére le métier de contrôleur aérien
        Citizen.Wait(1)

        -- Vérifie s'il est sur un des points pour la téléportation
        if IsPlayerInTeleporterMarker() then

            -- Vérifie s'il essaye d'entrer dans la tour
            if IsEnterTeleportersAction() then
                local tp = GetTeleporter()
                if tp ~= nil then
                    local to = Config.teleporters.all_positions[tp.to]
                    if to ~= nil then
                        DoScreenFadeOut(1)
                        SetPedCoordsKeepVehicle(PlayerPedId(), to.position.x, to.position.y, to.position.z)
                        PlaceObjectOnGroundProperly(PlayerPedId())
                        Wait(600);
                        DoScreenFadeIn(250)

                        ESX.ShowNotification("Vous avez utilisé l'ascenseur")
                    end
                end
            end
        end
    end
end)