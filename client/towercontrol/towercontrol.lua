-- Gestion de la tour de contrôle (Général)
local isjobok = false

-- Commande de Debug de la tour de controle
RegisterCommand("tc", function()
    if Config.inProduction == false then
        ShowTowerControlUI(true)
    end
end)

-- Boucle de rendu de la tour de contrôle
Citizen.CreateThread(function()
    while Config.towercontrol.enabled do
        Citizen.Wait(0)

        -- Si le joueur est bien un contrôleur aérien, alors ont affiche ses points de jobs
        if isjobok or not Config.inProduction then
            DrawTowerMarker()
        end
    end
end)

-- Boucle principal de logique de la tour de contrôle
Citizen.CreateThread(function()
    -- Récupére les informations du joueur
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()

    -- Boucle principal
    while Config.towercontrol.enabled do
        -- Petit trick pour avoir une sorte de "continue"
        repeat
            -- Vérifie si le joueur fait partie d'un jobs autorisé            
            local found = false
            for k,job in pairs(Config.towercontrol.allowedTowerJobs) do
                if IsPlayerJobOK(job) then
                    found = true
                end
            end

            -- Je définie la variable (isjobok), j'attend 100ms si le jobs ne match pas pour économiser des resources
            isjobok = found
            if found == false then
                Citizen.Wait(100)
            end

            -- Gére le métier de contrôleur aérien
            Citizen.Wait(1)
            if not isjobok and Config.inProduction then
                Citizen.Wait(Config.sleepForJob)
                -- Le fameux "continue" ...
                do break end
            end

            -- Si le joueur est bien un contrôleur aérien, alors ont affiche ses points de jobs
            if isjobok or not Config.inProduction then
                
                -- Vérifie s'il est sur un des points pour le contrôle aérien
                if IsPlayerInTowerMarker() then

                    -- Vérifie s'il essaye d'entrer dans la tour
                    if IsEnterTowerAction() then

                        -- Affiche l'UI de contrôle
                        ShowTowerControlUI(true)
                    end
                end
            end
        until false
    end
end)