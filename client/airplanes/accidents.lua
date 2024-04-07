-- Gestion des pannes aléatoire sur les avions / hélicos

local panne = -1
local avion = nil
local oneshot = false
local pan = false

RegisterCommand("pan", function()
    if Config.inProduction == false then
        pan = true
        DefinePlaneDamage()
        print("Panne !")
    end
end)

function executePanne()
    if oneshot == false then
        if IsThisModelAHeli(GetEntityModel(avion)) then
            --  J'execute la panne pour les hélicoptère
            if  panne == 1 then SetPlaneEngineHealth(avion, math.random()) oneshot = true -- OK (Mets en feu au moteur)
            elseif  panne == 2 then ControlLandingGear(avion, 3) -- OK (Supprime les roue à l'atterissage
            elseif  panne == 3 then SetHelicopterRollPitchYawMult(avion, 0.01) oneshot = true
            elseif  panne == 4 then SetHeliBladesSpeed(avion, 1.0)
            elseif  panne == 5 then SetHeliMainRotorHealth(avion, 0.0) oneshot = true
            elseif  panne == 6 then SetHeliTailRotorHealth(avion, 0.0) oneshot = true
            end
        else
            --  J'execute la panne pour les avions
            if  panne == 1 then SetPlaneEngineHealth(avion, 0.5) oneshot = true -- OK (Mets en feu sont réacteur)
            elseif  panne == 2 then ControlLandingGear(avion, 3) -- OK (Supprime les roue à l'atterissage)
            end
        end
    end
end

function setPanneType()
    if avion == nil then
        avion = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    oneshot = false

    if IsThisModelAHeli(GetEntityModel(avion)) then
        -- Je choisi une panne au hasard pour les hélicoptére
        panne = math.random(1, 6)
    else
        -- Je choisi une panne au hasard pour les avions
        panne = math.random(1, 2)
    end
end


-- Défini si l'avion doit être endommager (ou pas), quand, et de qu'elle manière
function DefinePlaneDamage()
    -- Si la probabilité fait qu'il doit se produire une panne
    if math.random(1, 100) < Config.accidents.chance or pan == true then
        setPanneType()

        --SetPlaneTurbulenceMultiplier(avion, 0.8)
        --SetVehicleFlightNozzlePositionImmediate(avion, 300)
        --SetVehicleHoverTransformEnabled(avion, false)
        --SetVehicleOutOfControl(avion, false, true) : 
        --DisablePlaneAileron(avion, false, true) : Ne marche pas
        --SetHeliBladesFullSpeed(true) : PAS ESSAYER
        --SetVehicleBrake(avion, true) : NOK
        --SetVehicleCanLeakPetrol(avion, true) : NOK

        --Liste des accidents possible en hélico :
        --IsHeliPartBroken(heli, ?? (bool), ?? (bool), ?? (bool))
        --SetHeliTailRotorHealth(heli, 0 to 1.0f) 
        --SetHeliMainRotorHealth(heli, 0 to 1.0f)
        --SetHeliBladesSpeed(plane, 0 to 1.0f) 
        --SetHeliBladesFullSpeed(plane)

        pan = false
    end
end

function ExecutePlaneDamage()
    if GetVehiclePedIsIn(PlayerPedId(), false) == avion then
        executePanne()
    else
        avion = nil
        oneshot = nil
        panne = -1
    end
end

-- Boucle principal de logique des accidents d'aviation (définition)
Citizen.CreateThread(function()
    -- Boucle principal
    while true do
        Citizen.Wait(math.random(Config.accidents.time_min, Config.accidents.time_max))

        -- Gestion des pannes aérienne
        -- Si le joueur est bien dans l'avion
        if IsPlayerInPlane() then
            -- Je définie (ou pas) des dommages à l'avion qui apparaîtront en vol de manière aléatoire
            DefinePlaneDamage()
        end
    end
end)

-- Boucle principal de logique des accidents d'aviation (execution)
Citizen.CreateThread(function()
    -- Boucle principal
    while true do
        Citizen.Wait(5)
        ExecutePlaneDamage()
    end
end)