local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add("respawnpassive", "Respawn passive gang patrol vehicles", {}, false, function(source)
    TriggerClientEvent("mncpassiveguards:client:SpawnZoneVehicles", -1)
    
    -- Notify all players that patrols have been respawned
    TriggerClientEvent('ox_lib:notify', -1, {
        type = 'success',
        title = 'MnC',
        description = 'Passive patrol vehicles have been respawned by an admin.',
        position = 'top'
    })
end, "admin")

QBCore.Commands.Add("removepassive", "Remove all passive gang patrol vehicles and peds", {}, false, function(source)
    TriggerClientEvent("mncpassiveguards:client:RemoveZoneVehicles", -1)
    
    -- Notify all players that patrols have been removed
    TriggerClientEvent('ox_lib:notify', -1, {
        type = 'error',
        title = 'MnC',
        description = 'Passive patrol vehicles have been removed by an admin.',
        position = 'top'
    })
end, "admin")

-- Kill event from qb-core to detect ped deaths caused by players or other peds
-- We will listen for killed event, detect if killer is a patrol passenger, and notify client to make them flee
-- This requires your qb-core kill event, adapt if needed

AddEventHandler('qb-core:server:entityKilled', function(killedEntity, killerEntity)
    -- Check if killerEntity is a passenger ped from patrol
    if not killedEntity or not killerEntity then return end
    if GetEntityType(killedEntity) ~= 1 then return end -- 1 = Ped, skip if not ped
    
    -- Trigger client event to check if killer ped should flee (passenger kill flee logic)
    TriggerClientEvent('mncpassiveguards:client:PassengerKilledPed', -1, NetworkGetNetworkIdFromEntity(killerEntity))
end)
