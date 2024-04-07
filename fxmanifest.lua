-- FlightClub by Sweeeper
fx_version 'cerulean'
games { 'gta5' }

author 'Sweeeper <sweeeper311@gmail.com>'
description 'FlightClub is a plugin for enchant aircraft capacity, allow more RP situation and fun !'
version '1.0.0'

ui_page "ui/index.html"
files {
    "ui/index.html",
    "ui/css/style.css",
    "ui/js/base.js",
    "ui/js/leaflet.rotatedMarker.js",
    "ui/img/radar_player_plane.png",
    "ui/img/radar_helicopter.png"
}

client_scripts {
    -- RageUI
    'rageui/RageUI.lua',
    'rageui/Menu.lua',
    'rageui/MenuController.lua',
    'rageui/components/*.lua',
    'rageui/elements/*.lua',
    'rageui/items/*.lua',

    -- Général
    'config.lua',
    'client/teleporters.lua',
    'client/airplanes/accidents.lua',
    'client/military/attacks.lua',
    'client/military/camera.lua',
    'client/towercontrol/marker.lua',
    'client/towercontrol/nui.lua',
    'client/towercontrol/towercontrol.lua',
    'client/mecano/mecano.lua',
    'client/drop/dropbox.lua',
    'client/client.lua'
}

server_scripts {
    'config.lua',
    'server/entityiter.lua',
    'server/server.lua',
    'server/airplane.lua',
    'server/towercontrol.lua',
    'server/dropbox.lua',
    'server/mecano.lua'
}