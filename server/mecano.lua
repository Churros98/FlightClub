-- Reçois une demande de broadcast pour le détachement
RegisterNetEvent('FlightClub:DetachRope')
AddEventHandler('FlightClub:DetachRope', function(PlaneNetID)
    -- Je broadcast
    TriggerClientEvent('FlightClub:DeleteRope', -1, PlaneNetID)
end)

-- Reçois une demande de broadcast pour l'attachement
RegisterNetEvent('FlightClub:AttachRope')
AddEventHandler('FlightClub:AttachRope', function(PlaneNetID, PlayerNetID)
    -- Je broadcast
    TriggerClientEvent('FlightClub:SetRope', -1, PlaneNetID, PlayerNetID)
end)