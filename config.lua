Config = {}

-- Paramètre de debug (Mettre à true lors de l'utilisation réel)
Config.inProduction = false

-- Temps de repos du script quand le métier ne match pas (resource friendly)
Config.sleepForJob = 1000 -- en ms

-- Gestion des accidents aérien
Config.accidents = {
    -- Revérification de la chance en ms
    time_min = 15000, -- en ms
    time_max = 100000, -- en ms

    -- Probabilité que l'accident arrive
    chance = 1 -- en % (sur 100)
}

-- Gestion des armes aérienne
Config.weapons = {
    startMissile = 1, -- Nombre de missile par défaut dans une entitée
    maxAmmo = 4, -- Nombre de missile maximum autorisé
    notAllowed = { -- Arme non autorisée par défaut
        `VEHICLE_WEAPON_TANK`,
        `VEHICLE_WEAPON_SPACE_ROCKET`,
        `VEHICLE_WEAPON_PLANE_ROCKET`,
        `VEHICLE_WEAPON_PLAYER_LASER`,
        `VEHICLE_WEAPON_PLAYER_BULLET`,
        `VEHICLE_WEAPON_PLAYER_BUZZARD`,
        `VEHICLE_WEAPON_PLAYER_HUNTER`,
        `VEHICLE_WEAPON_PLAYER_LAZER`,
        `VEHICLE_WEAPON_ENEMY_LASER`
    }
}

-- Gestion des téléporteurs
Config.teleporters = {
    all_positions = { -- Position des téléporteurs (Assenceurs, etc ..), utile pour fluidifier
        { -- Assenceur de la tour de contrôle (Bas)
            marker = {
                x = -2360.68,
                y = 3249.47,
                z = 32.005
            },
            position = {
                x = -2360.68,
                y = 3249.47,
                z = 32.81             
            },
            to = 2
        },
        { -- Assenceur de la tour de contrôle (Haut)
            marker = {
                x = -2360.68,
                y = 3249.47,
                z = 92.005 
            },
            position = {
                x = -2360.68,
                y = 3249.47,
                z = 92.90                
            },
            to = 1
        }
    },
    marker = 23,
    scale = 1.0,
    rgba_marker = { 0, 10, 200, 155},
    control = 46,
    message = "Appuyer sur [E] pour utiliser l'assenceur"
}

-- Gestion de la caméra des pilotes
Config.camera = {
    fovMin = 10.0, -- FOV Min (Zoom maximum)
    fovMax = 80.0, -- FOV Max (Zoom minimum)
    zoomSpeed = 2.0, -- Vitesse du zoom de la caméra
    allowNeeded = true, -- Un job spécifique est-il nécessaire pour utiliser la caméra ?
    allowedCameraJobs = { -- Si true, qu'elle sont les jobs autorisé ?
        "lspd",
        "pilot",
        "towercontrol",
        "airmecanic",
        "sheriff"
    },
    enterCameraMessage = "Appuyer sur [F] pour voir une caméra",
    quitCameraMessage = "Appuyer sur [F] pour quitter la caméra",
    marker = 23,
    scale = 1.0,
    rgba_marker = { 120, 0, 0, 155},
    cameraZones = { -- Défini les zones de marqueur pour la caméra
        { -- Hangar, Aéroport millitaire
            x = -2353.474,
            y = 3257.768,
            z = 92.903
        }
    }
}

-- Gestion du contrôleur aérien
Config.towercontrol = {
    enabled = true, -- La tour de contrôle est elle active ?
    airport_radars = { -- Permet la localisation à raz du sol dans les zones renforcée (aéroport)
        { -- Aéroport LS
            x = -1187.648,
            y = -2678.50,
            z = 13.94,
            d = 800
        },
        { -- Aéroport désert
            x = 1363.108,
            y = 3127.55,
            z = 41.056,
            d = 400
        },
        { -- Base militaire 
            x = -2129.913,
            y = 3127.529,
            z = 32.810,
            d = 800
        }
    },
    allowedTowerJobs = {
        "towercontrol"
    },
    isKMH = true,
    minAlt = 150, -- Altitude minimum avant détection radar (hors des zone renforcée)
    update_every = 500, -- Mise à jour en ms des données de vol sur la carte
    all_positions = { -- Position de tout les markers pour accéder à l'interface du radar
        {
            x = -980.396,
            y = -2634.1606,
            z = 13.05
        },
        {
            x = -2362.874,
            y = 3247.108,
            z = 92.001
        },
        {
            x = -2360.387,
            y = 3249.863,
            z = 101.450
        },
        {
            x = -985.018,
            y = -2641.883,
            z = 13.98
        }
    },
    marker = 23,
    scale = 1.0,
    rgba_marker = { 120, 0, 0, 155},
    control = 46,
    message = "Appuyer sur [E] pour ouvrir le radar"
}

-- Gestion des pilotes
Config.pilot = {
    jobname = "pilot"
}

-- Gestion du Job "Mécano"
Config.mechanic = {
    enabled = true, -- Les mécanos sont ils activé ?
    jobname = "airmecanic",
    control = 46,
    repairFillMessage = "Appuyer sur [E] pour réparer/recharger l'avion",
    tugMessage = "Appuyer sur [E] pour treuiller l'avion",
    untugMessage = "Appuyer sur [E] pour déposer l'avion",
    showHelpMarkers = true, -- Définie si les markers d'aide doivent être dessiner
    marker = 23,
    scale = 10.0,
    rgba_marker = { 120, 0, 0, 155},
    tugDistance = 13, -- Distance à la quelle ont peut déplacer l'avion avec le véhicule de maintenance
    menuDistance = 5, -- Distance avec l'avion pour l'affichage du mene
    repairOutside = false, -- La réparation peut-elle être faite hors zone ?
    repairZones = { -- Défini les zones de réparation possible (centre) avec la distance
        { -- Hangar, Aéroport millitaire
            x = -1822.979,
            y = 2972.344,
            z = 32.809,
            d = 40
        },
        { -- Hangar, Aéroport millitaire
            x = -2138.325,
            y = 3258.585,
            z = 32.708,
            d = 40
        },
        { -- Hangar principal, LS Airport
            x = -977.009,
            y = -2996.923,
            z = 14.444,
            d = 40
        },
        { -- Hangar, LS Airport
            x = -1275.198,
            y = -3388.203,
            z = 14.444,
            d = 40
        },
        { -- Hangar Pegasus, LS Airport
            x = -1652.965,
            y = -3144.905,
            z = 13.992,
            d = 40
        },
        { -- Piste hélico, LS Airport
            x = -1112.396,
            y = -2884.149,
            z = 13.946,
            d = 10
        },
        { -- Hangar, Desert Airport
            x = 1732.514,
            y = 3305.654,
            z = 41.223,
            d = 10
        },
        { -- Hangar, Grapeseed
            x = 2134.685,
            y = 4781.942,
            z = 40.970,
            d = 5
        }
    },
    fillAmmoOutside = false, -- Le rechargement d'arme peut-elle être faite hors zone ?
    fillAmmoZones = { -- Défini les zones de rechargement d'arme possible (centre) avec la distance
        { -- Hangar, Aéroport millitaire
            x = -1822.979,
            y = 2972.344,
            z = 32.809,
            d = 40
        },
        { -- Hangar, Aéroport millitaire
            x = -2138.325,
            y = 3258.585,
            z = 32.708,
            d = 40
        },
        { -- Zone avion découvert, Aéroport millitaire
            x = -2016.463,
            y = 2942.677,
            z = 32.707,
            d = 10
        },
        { -- Zone avion découvert, Aéroport millitaire
            x = -2144.421,
            y = 3019.765,
            z = 32.725,
            d = 10
        },
    },
    fillAmmoPlanes = { -- Liste des avions dont le mécano peut modifier la valeur des missiles
        `lazer`,
        `buzzard`
    },
    animationDict = "mini@biotech@blowtorch_str", -- Animation de réparation (Dictionnaire)
    animation = "blowtorch_cutting_centre" -- Animation de réparation (Nom de l'objet)
}

-- Gestion des caisses de largage
Config.dropbox = {
    enabled = true, -- Les dropboxs sont elle activé ?
    captureTime = 5000, -- Temps pour la capture d'une caisse de largage
    input = 46, -- Touche à utiliser pour les caisse de largage
    minAlt = 0, -- Altitude minimum pour le déploiement de la dropbox
    allowedPlanes = { -- Liste les avions ayant l'autorisation de posséder une caisse
        `cuban800`,
        `duster`,
        `titan`,
        `velum2`,
        `velum`,
        `microlight`,
        `lazer`
    },
    animationDict = "amb@world_human_gardener_plant@female@idle_a", -- Animation de capture de la caisse (Dictionnaire)
    animation = "idle_a_female" -- Animation de capture de la caisse (Nom de l'objet)
}
