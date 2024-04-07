-- FlightClub
-- Préparation de ESX
ESX              = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end
