-- Gestion de la télévision des pilotes par du personnels autorisé
-- Basée sur le code "FiveM Heli Cam (Version 1.3 2017-06-12)" par mraes

-- Variables
local MenuCam = RageUI.CreateMenu("Camera", "Camera en ligne");
local showCam = false
local setupCam = false
local cam = nil
local playerIdx = nil
local fov_max = Config.camera.fovMax
local fov_min = Config.camera.fovMin
local fov = (fov_max+fov_min)*0.5
local speed_lr = 3.0 
local speed_ud = 3.0
local zoomspeed = Config.camera.zoomSpeed
local pilots = {}
local isAllowed = false

-- Le joueur est il autorisé a voir les caméra
function IsPlayerCameraAllowed()

    -- S'il n'y a pas besoin de vérification, alors ont skip
    if Config.camera.allowNeeded == true and Config.inProduction then
        isAllowed = false

        -- Vérifie si le joueur fait partie d'un jobs autorisé
        for k,job in pairs(Config.camera.allowedCameraJobs) do
            if IsPlayerJobOK(job) then
                isAllowed = true
            end
        end
    else
        isAllowed = true
    end

    return isAllowed
end

-- Réceptionne la liste des joueurs
RegisterNetEvent('FlightClub:GetPilotsAvailable')
AddEventHandler('FlightClub:GetPilotsAvailable', function(p)
	-- Je sauvegarde la liste
    pilots = p

    -- J'ouvre le menu
    RageUI.Visible(MenuCam, not RageUI.Visible(MenuCam))
end)

-- Menu de sélection des pilotes
function RageUI.PoolMenus:CameraPilot()
	MenuCam:IsVisible(function(Items)

        Items:AddSeparator(#pilots .." pilote(s) en ligne")
        for _, pilot in pairs(pilots) do
            Items:AddButton(pilot.name, pilot.name, { IsDisabled = false }, function(onSelected)
                if (onSelected) then
                    playerIdx = GetPlayerFromServerId(pilot.source)
                    showCam = not showCam
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

-- Execution du code à l'utilisation de la touche
Keys.Register("F", "F", "CameraPilot", function()
    -- Si la caméra est actuellement afficher, alors j'attend pour la fermer
    if showCam == true then
        showCam = false
    end

    incameramarker = IsPlayerInCameraMarker()
    isallow = IsPlayerCameraAllowed()

    -- Si le joueur et dans le marker, qu'il est autoriser a voir et qu'il n'a pas de caméra, alors je demande la liste des pilotes au serveur
    if incameramarker and isallow then
        if showCam == false then
            TriggerServerEvent('FlightClub:GetPilotsAvailable')
        end
    end
end)

-- Cache le HUD (1 frame)
function HideHUDThisFrame()
	--HideHelpTextThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end

-- Prend en charge la rotation via la sourie
function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

-- Prend en charge le zoom via le scroll
function HandleZoom(cam)
	if IsControlJustPressed(0,241) then -- Scrollup
		fov = math.max(fov - zoomspeed, fov_min)
	end
	if IsControlJustPressed(0,242) then
		fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown		
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
end

-- Commande de Debug de la caméra (liste)
RegisterCommand("camlist", function()
    if Config.inProduction == false then
        TriggerServerEvent('FlightClub:GetPilotsAvailable')
    end
end)

-- Boucle de rendu de la caméra
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
		
        local isPlayerAllowed = IsPlayerCameraAllowed()

		-- Si le joueur est bien un mécanicien
		if isPlayerAllowed then
			-- Je dessine les points d'intêret des mécano
			DrawCameraMarkers()
        else
            -- J'attend avant de revérifier pour moins consommé de resource
            Citizen.Wait(Config.sleepForJob)
		end
	end
end)

-- Mise à jour de la caméra
function UpdatePlaneCamera()
    while showCam and playerIdx do
        if not setupCam then
            SetTimecycleModifier("heliGunCam")
            SetTimecycleModifierStrength(0.3)
        
            local scaleform = RequestScaleformMovie("HELI_CAM")
            while not HasScaleformMovieLoaded(scaleform) do
                Citizen.Wait(10)
            end
        
            cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)

            local currentPos = NetworkGetPlayerCoords(playerIdx)
            SetCamCoord(cam, currentPos.x, currentPos.y, currentPos.z)
            Wait(100)

            local plane = GetPlayerPed(playerIdx)

            AttachCamToEntity(cam, plane, 0.0,0.0,-1.5, true)
            SetCamRot(cam, 0.0,0.0,GetEntityHeading(plane))
            SetCamFov(cam, fov)
            RenderScriptCams(true, false, 0, 1, 0)
            --PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
            --PushScaleformMovieFunctionParameterInt(1)
            --PopScaleformMovieFunctionVoid()

            DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

            PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
            PopScaleformMovieFunctionVoid()
            
            PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
            PushScaleformMovieFunctionParameterInt(200)
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
            PushScaleformMovieFunctionParameterInt(0)
            Button(GetControlInstructionalButton(2, 191, true))
            ButtonMessage("Quitter la caméra")
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(80)
            PopScaleformMovieFunctionVoid()

            setupCam = true
        end

        local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
        CheckInputRotation(cam, zoomvalue)

        HandleZoom(cam)
        HideHUDThisFrame()

        PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
        PushScaleformMovieFunctionParameterFloat(GetEntityCoords(heli).z)
        PushScaleformMovieFunctionParameterFloat(zoomvalue)
        PushScaleformMovieFunctionParameterFloat(GetCamRot(cam, 2).z)
        PopScaleformMovieFunctionVoid()
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        Citizen.Wait(1)
    end

    RenderScriptCams(false, false, 0, 1, 0)
	SetScaleformMovieAsNoLongerNeeded(scaleform)
    ClearTimecycleModifier()
    DestroyCam(cam, false)
    
    setupCam = false
    showCam = false
end


-- Dessine les markers un par un (avec la bonne position au sol)
function DrawCameraMarker(pos)
	local boolean,groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z, false);

	DrawMarker(
		Config.camera.marker,
		pos.x,
		pos.y,
		groundZ,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		Config.camera.scale,
		Config.camera.scale,
		Config.camera.scale,
		Config.camera.rgba_marker[1],
		Config.camera.rgba_marker[2],
		Config.camera.rgba_marker[3],
		Config.camera.rgba_marker[4],
		false,
		true,
		2,
		nil,
		nil,
		false
	)
end

-- Dessine les markers des caméra
function DrawCameraMarkers()
	-- Dessine les markers de la zone des caméras
    for k,pos in pairs(Config.camera.cameraZones) do
        DrawCameraMarker(pos)
    end
end

-- Si le joueurs entre dans la zone d'un marker
function IsPlayerInCameraMarker() 
    for k,pos in pairs(Config.camera.cameraZones) do
        local marker_loc = vector3(pos.x, pos.y, pos.z)
        local player_loc = GetEntityCoords(PlayerPedId(), false)
        if Vdist2(marker_loc, player_loc) < (Config.camera.scale * 1.2) then
            return true
        end
    end

    return false
end

-- Boucle de rendu pour les caméra
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)

		-- Si le joueur est bien autoriser
        if IsPlayerCameraAllowed() then
            -- Je dessine les points d'intêret pour les caméras
            DrawCameraMarkers()

            -- Je dessine les fenêtre d'aide
            if IsPlayerInCameraMarker() and showCam == false  then
                ESX.ShowHelpNotification(Config.camera.enterCameraMessage)
            elseif showCam == true then
                if RageUI.Visible(MenuCam) then 
                    RageUI.CloseAll()
                end

                ESX.ShowHelpNotification(Config.camera.quitCameraMessage)
            end
        end
	end
end)

-- Boucle principal pour la télévision
Citizen.CreateThread(function()
    -- Boucle principal
    while true do
        Citizen.Wait(1)
        UpdatePlaneCamera()
    end
end)