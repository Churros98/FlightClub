// Fonction qui ferme le menu (Envoi d'un signal au script lua)
function closeMenu() {
    fetch(`https://${GetParentResourceName()}/exit`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            ok: true
        })
    }).then(resp => resp.json()).then(resp => console.log(resp));
}

// Traite les messages en provenance du jeu
function messagesEvent(event) {
    var item = event.data;
    if (item !== undefined && item.type == "ui") {
        if (item.display === true) {
            $('#content').show();
        } else {
            $('#content').hide();
        }
    } else if (item !== undefined && item.type == "updateplanes") {
        refreshPlanesBlips(item.planes);
    } else {
        console.log(item);
    }
}

////////////////////////////////////////////
// GESTION DE LA CARTE
// Basée sur le repo : https://github.com/RiceaRaul/gta-v-map-leaflet
// Crédit: RiceaRaul
// Licence: MIT
////////////////////////////////////////////

// Variable qui défini le focus sur un appareil
currentFocusNetId = -1;
refreshingPlanes = false;

// Défini les variables globales de la carte
AvionsGroup = L.layerGroup();

Icons = {
    "Avions" : AvionsGroup,
};

planeIcon = L.icon({
    iconUrl: 'img/radar_player_plane.png',    
    iconSize:     [32, 32],
    iconAnchor:   [16, 16],
    popupAnchor:  [0, 0]
});

heliIcon = L.icon({
    iconUrl: 'img/radar_helicopter.png',    
    iconSize:     [32, 32],
    iconAnchor:   [16, 16],
    popupAnchor:  [0, 0]
});

// Rafraichie les points
function refreshPlanesBlips(planes) {    
    // Ont nettoie tous
    refreshingPlanes = true;
    AvionsGroup.clearLayers();

    // Ont vien replacer les éléments avec les nouvelle coordonnées
    planes.forEach((item, index) => {
        if (item != null) {
            let marker = null;
            let data_html = "<dl><dt>Immatriculation</dt>" + "<dd>" + item.plate + "</dd>" + "<dt>Altitude</dt>" + "<dd>" + item.alt.toFixed(2) + " métres</dd>" + "<dt>Vitesse</dt>" + "<dd>" + item.speed.toFixed(2) + " km/h</dd></dl>";

            if (item.type == "plane") {
                marker = L.marker([item.coords.y, item.coords.x], {icon: planeIcon, rotationAngle: item.angle}).addTo(Icons["Avions"]).bindPopup(data_html);
            } else if (item.type == "heli") {
                marker = L.marker([item.coords.y, item.coords.x], {icon: heliIcon, rotationAngle: item.angle}).addTo(Icons["Avions"]).bindPopup(data_html);
            } else {
                console.log("Unknown type: " + item.type);
            }

            if (marker != null) {
                marker.netid = item.netid;
                if (marker.netid == currentFocusNetId) {
                    marker.openPopup();
                }

                marker.on('click',function(ev) {
                    currentFocusNetId = ev.target.netid;
                    ev.target.openPopup();
                });

                marker.getPopup().on('remove', function() {
                    if (!refreshingPlanes)
                        currentFocusNetId = -1;
                });
            }
        }
    })

    refreshingPlanes = false;
}

// Charge la map
function loadMap() {
    // Ont défini la map
    const center_x = 117.3;
    const center_y = 172.8;
    const scale_x = 0.02072;
    const scale_y = 0.0205;
    
    CUSTOM_CRS = L.extend({}, L.CRS.Simple, {
        projection: L.Projection.LonLat,
        scale: function(zoom) {
    
            return Math.pow(2, zoom);
        },
        zoom: function(sc) {
    
            return Math.log(sc) / 0.6931471805599453;
        },
        distance: function(pos1, pos2) {
            var x_difference = pos2.lng - pos1.lng;
            var y_difference = pos2.lat - pos1.lat;
            return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
        },
        transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y),
        infinite: true
    });
    
    // Ont paramètre les cartes (Serveur externe)
    var SateliteStyle = L.tileLayer('https://anarchiegaming.fr/FiveM/mapStyles/styleSatelite/{z}/{x}/{y}.jpg', {minZoom: 0,maxZoom: 8,noWrap: true,continuousWorld: false,attribution: 'Online map GTA V',id: 'SateliteStyle map',}),
        AtlasStyle	= L.tileLayer('https://anarchiegaming.fr/FiveM/mapStyles/styleAtlas/{z}/{x}/{y}.jpg', {minZoom: 0,maxZoom: 5,noWrap: true,continuousWorld: false,attribution: 'Online map GTA V',id: 'styleAtlas map',}),
        GridStyle	= L.tileLayer('https://anarchiegaming.fr/FiveM/mapStyles/styleGrid/{z}/{x}/{y}.png', {minZoom: 0,maxZoom: 5,noWrap: true,continuousWorld: false,attribution: 'Online map GTA V',id: 'styleGrid map',});

    var map = L.map('map', {
        crs: CUSTOM_CRS,
        minZoom: 1,
        maxZoom: 5,
        Zoom: 5,
        maxNativeZoom: 5,
        preferCanvas: true,
        layers: [SateliteStyle],
        center: [0, 0],
        zoom: 3,
    });
    
    var layersControl = L.control.layers({ "Satelite": SateliteStyle,"Atlas": AtlasStyle,"Grid":GridStyle}, Icons).addTo(map);
    map.addLayer(AvionsGroup);

    // Non utiliser pour le moment
    map.on('click', function (event) {
        var x = event.latlng.lng;
        var y = event.latlng.lat;
    });
}

$(function(){
    // Lors du chargement de la page
    window.onload = function(e) {
        // Je commence à cacher le menu (inutile quand il est pas appelé)
        $('#content').hide();

        // Ont créer l'événement pour dispatche les messages en provenance du jeu
        window.addEventListener('message', (event) => {
            messagesEvent(event);
        });
    };

    // Si ont presse "EXIT", ont quitte le menu dans tous les cas
    document.onkeyup = function (data) {
        if (data.which == 27) {
            closeMenu();
            return
        }
    };

    // Charge la map
    loadMap();
})