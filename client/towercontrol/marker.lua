-- Gestion de la tour de contrôle (Marker)

-- Dessine le marker sur le sol
function DrawTowerMarker()
    for k,pos in pairs(Config.towercontrol.all_positions) do
        local boolean,groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false);

        DrawMarker(
            Config.towercontrol.marker,
            pos.x,
            pos.y,
            groundZ,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            0.0,
            Config.towercontrol.scale,
            Config.towercontrol.scale,
            Config.towercontrol.scale,
            Config.towercontrol.rgba_marker[1],
            Config.towercontrol.rgba_marker[2],
            Config.towercontrol.rgba_marker[3],
            Config.towercontrol.rgba_marker[4],
            false,
            true,
            2,
            nil,
            nil,
            false
        )
    end
end

-- Si le joueurs entre dans la zone d'un marker
function IsPlayerInTowerMarker() 
    for k,pos in pairs(Config.towercontrol.all_positions) do
        local marker_loc = vector3(pos.x, pos.y, pos.z)
        local player_loc = GetEntityCoords(PlayerPedId(), false)
        if Vdist2(marker_loc, player_loc) < (Config.towercontrol.scale * 1.2) then
            return true
        end
    end

    return false
end

-- Vérifie si l'action est valide ou pas (et le dessine)
function IsEnterTowerAction()
    ESX.ShowHelpNotification(Config.towercontrol.message)
    if IsControlJustPressed(0, Config.towercontrol.control) then
        return true
    end

    return false
end