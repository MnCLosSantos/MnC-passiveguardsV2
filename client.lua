local zoneVehicles = {}
local reportedKills = {}
local driverOutsideSince = {}
local fleeingDrivers = {}

local Zones = {
    {
        name = "Ballas Turf",
        points = {
            vector2(168.34, -2055.45),
            vector2(-419.56, -1878.54),
            vector2(175.83, -1577.52),
            vector2(431.22, -1772.84),
        },
        gangPedGroup = GetHashKey("AMBIENT_GANG_BALLAS"),
        ownerGang = "ballas"
    },
    {
        name = "Families Turf",
        points = {
            vector2(-178.76, -1769.37),
            vector2(87.4, -1441.99),
            vector2(-68.88, -1351.91),
            vector2(-319.2, -1642.4),
        },
        gangPedGroup = GetHashKey("AMBIENT_GANG_FAMILY"),
        ownerGang = "families"
    }
}

local function GetPedModelFromGroup(group)
    if group == GetHashKey("AMBIENT_GANG_BALLAS") then
        return `g_m_y_ballaeast_01`
    elseif group == GetHashKey("AMBIENT_GANG_FAMILY") then
        return `g_m_y_famfor_01`
    end
    return `g_m_y_mexgang_01`
end

local function SpawnZoneVehicles()
    for zoneIndex, zone in ipairs(Zones) do
        if zoneVehicles[zoneIndex] then
            for _, data in ipairs(zoneVehicles[zoneIndex]) do
                if DoesEntityExist(data.vehicle) then DeleteEntity(data.vehicle) end
                for _, ped in ipairs(data.peds) do
                    if DoesEntityExist(ped) then DeleteEntity(ped) end
                end
            end
        end

        zoneVehicles[zoneIndex] = {}

        local gangModel = GetPedModelFromGroup(zone.gangPedGroup)
        local vehicleModels = {}

        if zone.ownerGang == "ballas" then
            vehicleModels = { `cavalcade3`, `baller7`, `rebla`, `sultan2` }
        elseif zone.ownerGang == "families" then
            vehicleModels = { `iwagen`, `faction`, `cypher`, `euros` }
        else
            vehicleModels = { `surge`, `seminole`, `patriot`, `bjxl` }
        end

        local fixedSpawns = {}

if zone.ownerGang == "ballas" then
    fixedSpawns = {
        vector4(-16.79, -1803.34, 27.04, 138.79),
        vector4(85.4, -1882.76, 23.02, 318.81),
        vector4(166.75, -1750.11, 29.03, 50.14),
        vector4(-190.29, -1803.04, 29.84, 300.07),
        vector4(156.74, -1810.79, 28.55, 50.52),
        vector4(105.99, -1738.08, 28.93, 227.15),
        vector4(229.05, -1881.07, 26.06, 227.03),
        vector4(71.73, -1919.66, 21.1, 48.23),
        vector4(106.29, -1817.83, 26.54, 236.87),
        vector4(-303.39, -1843.4, 25.29, 259.35),
		vector4(355.46, -1800.85, 28.81, 49.62),
		vector4(236.65, -1940.16, 23.48, 56.96),
		vector4(190.01, -1991.33, 18.51, 318.15),
		vector4(89.3, -2026.19, 18.12, 124.07),
		vector4(-125.74, -1938.74, 23.27, 43.67),
    }
elseif zone.ownerGang == "families" then
    fixedSpawns = {
        vector4(-158.51, -1702.84, 30.87, 46.77),
        vector4(-177.2, -1606.7, 33.68, 340.82),
        vector4(19.85, -1461.83, 30.4, 65.99),
        vector4(100.6, -1546.32, 29.22, 229.68),
        vector4(92.04, -1489.37, 29.14, 319.19),
        vector4(181.54, -1424.04, 29.19, 243.25),
        vector4(224.15, -1519.99, 29.14, 218.84),
        vector4(122.17, -1323.3, 29.36, 118.42),
        vector4(-24.51, -1355.06, 29.15, 87.75),
        vector4(-289.01, -1377.01, 31.18, 180.43),
		vector4(-97.56, -1586.26, 31.38, 318.14),
		vector4(-151.13, -1465.36, 33.19, 140.01),
		vector4(-91.27, -1469.94, 33.0, 228.92),
		vector4(-91.32, -1273.31, 29.15, 359.35),
		vector4(-240.89, -1301.11, 31.3, 89.88)
    }
end


        local patrolPoints = {}
        for _, spawn in ipairs(fixedSpawns) do
            table.insert(patrolPoints, vector3(spawn.x, spawn.y, spawn.z))
        end

        for i, spawn in ipairs(fixedSpawns) do
            local vehicleModel = vehicleModels[((i - 1) % #vehicleModels) + 1]

            RequestModel(vehicleModel)
            RequestModel(gangModel)
            while not HasModelLoaded(vehicleModel) or not HasModelLoaded(gangModel) do Wait(50) end

            local veh = CreateVehicle(vehicleModel, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
            SetEntityAsMissionEntity(veh, true, true)
            SetVehicleDoorsLocked(veh, 1)
            SetVehicleNeedsToBeHotwired(veh, false)
            SetVehicleEngineOn(veh, true, true, false)

            if zone.ownerGang == "ballas" then
                SetVehicleColours(veh, 145, 145)
            elseif zone.ownerGang == "families" then
                SetVehicleColours(veh, 49, 49)
            else
                SetVehicleColours(veh, 111, 111)
            end

            local peds = {}
            for seat = -1, 0 do
                local ped = CreatePedInsideVehicle(veh, 4, gangModel, seat, true, false)
                SetEntityAsMissionEntity(ped, true, true)
                SetPedRelationshipGroupHash(ped, zone.gangPedGroup)
                GiveWeaponToPed(ped, `WEAPON_PISTOL`, 100, false, true)
                SetPedArmour(ped, 50)
                SetPedCanRagdollFromPlayerImpact(ped, false)
                table.insert(peds, ped)
            end

            zoneVehicles[zoneIndex][#zoneVehicles[zoneIndex] + 1] = {
                vehicle = veh,
                peds = peds,
                passengerSpawned = false,
                zoneIndex = zoneIndex,
                patrolThreadRunning = false
            }
        end
    end
end

RegisterNetEvent("mncpassiveguards:client:SpawnZoneVehicles", function()
    SpawnZoneVehicles()
end)

RegisterNetEvent("mncpassiveguards:client:RemoveZoneVehicles", function()
    for zoneIndex, vehiclesData in pairs(zoneVehicles) do
        for _, data in ipairs(vehiclesData) do
            if DoesEntityExist(data.vehicle) then
                DeleteEntity(data.vehicle)
            end
            for _, ped in ipairs(data.peds) do
                if DoesEntityExist(ped) then
                    DeleteEntity(ped)
                end
            end
        end
        zoneVehicles[zoneIndex] = nil
    end
end)

local lastDamageTimes = {}
local vehiclePatrolling = {}
local activeShooters = {}

local function StartPatrol(data)
    if data.patrolThreadRunning then return end
    data.patrolThreadRunning = true
    local veh = data.vehicle
    local peds = data.peds
    local zoneIndex = data.zoneIndex
    local driver = peds[1]

    local patrolPoints = {}
    for _, v in ipairs(Zones[zoneIndex].points) do
        table.insert(patrolPoints, vector3(v.x, v.y, 30.0))
    end

    CreateThread(function()
        local lastIndex = nil
        while data.patrolThreadRunning and DoesEntityExist(driver) and not IsEntityDead(driver) and DoesEntityExist(veh) and not IsEntityDead(veh) do
            local nextIndex
            repeat
                nextIndex = math.random(1, #patrolPoints)
            until nextIndex ~= lastIndex
            lastIndex = nextIndex

            local wp = patrolPoints[nextIndex]
            TaskVehicleDriveToCoordLongrange(driver, veh, wp.x, wp.y, wp.z, 17.0, 786603, 10.0)

            local start = GetGameTimer()
            while GetGameTimer() - start < 15000 do
                if #(GetEntityCoords(veh) - wp) < 8.0 or not data.patrolThreadRunning then break end
                Wait(500)
            end

            Wait(1000)
        end
    end)
end

local function MakePedFlee(ped, fromPos)
    if not DoesEntityExist(ped) or IsPedDeadOrDying(ped) then return end
    ClearPedTasksImmediately(ped)
    local px, py, pz = table.unpack(fromPos)
    local angle = math.random() * 2 * math.pi
    local radius = 50.0
    local destX = px + radius * math.cos(angle)
    local destY = py + radius * math.sin(angle)
    local found, groundZ = GetGroundZFor_3dCoord(destX, destY, pz + 50.0, false)
    local destZ = found and groundZ or pz
    TaskSmartFleeCoord(ped, px, py, destZ, 150.0, -1, false)
end

CreateThread(function()
    local wasDead = false
    while true do
        Wait(200)
        local playerPed = PlayerPedId()
        local isDead = IsEntityDead(playerPed)

        if isDead and not wasDead then
            wasDead = true
            local deathPos = GetEntityCoords(playerPed)
            for zoneIndex, vehiclesData in pairs(zoneVehicles) do
                for _, data in ipairs(vehiclesData) do
                    local veh = data.vehicle
                    local peds = data.peds
                    if DoesEntityExist(veh) and not IsEntityDead(veh) then
                        for i = 2, #peds do -- Skip driver (index 1)
                            local passenger = peds[i]
                            if DoesEntityExist(passenger) and not IsPedDeadOrDying(passenger) and not IsPedInVehicle(passenger, veh, false) then
                                MakePedFlee(passenger, deathPos)
                            end
                        end
                    end
                end
            end
        elseif not isDead then
            wasDead = false
        end
    end
end)

CreateThread(function()
    while true do
        Wait(100)

        for zoneIndex, vehiclesData in pairs(zoneVehicles) do
            for _, data in ipairs(vehiclesData) do
                local veh = data.vehicle
                local peds = data.peds

                local driver = peds[1]
                local passengers = {}

                if not DoesEntityExist(veh) or IsEntityDead(veh) or not driver or not DoesEntityExist(driver) then goto continue end

                for i = 2, #peds do
                    if DoesEntityExist(peds[i]) and not IsEntityDead(peds[i]) then
                        table.insert(passengers, peds[i])
                    end
                end

                local vehCoords = GetEntityCoords(veh)

                local shooter = nil
                for _, ped in ipairs(peds) do
                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        local playerPed = PlayerPedId()
                        if HasEntityBeenDamagedByEntity(ped, playerPed, true) or (IsPedShooting(playerPed) and #(GetEntityCoords(playerPed) - vehCoords) <= 50.0) then
                            shooter = playerPed
                            break
                        end
                    end
                    if shooter then break end
                end

                if shooter then
                    if not activeShooters[veh] or GetGameTimer() - (lastDamageTimes[veh] or 0) > 2000 then
                        activeShooters[veh] = shooter
                        lastDamageTimes[veh] = GetGameTimer()

                        for _, passenger in ipairs(passengers) do
                            if DoesEntityExist(driver) and not IsEntityDead(driver) then
                                ClearPedTasks(passenger)
                                GiveWeaponToPed(passenger, `WEAPON_PISTOL`, 200, false, true)
                                TaskDriveBy(passenger, shooter, 0, 0.0, 0.0, 0.0, 100.0, false)
                            else
                                if IsPedInAnyVehicle(passenger, false) then
                                    TaskLeaveVehicle(passenger, veh, 256)
                                    Wait(300)
                                end
                                ClearPedTasksImmediately(passenger)
                                TaskEnterVehicle(passenger, veh, -1, -1, 2.0, 1, 0)
                                Wait(1500)
                                GiveWeaponToPed(passenger, `WEAPON_MICROSMG`, 200, false, true)
                                TaskCombatPed(passenger, shooter, 0, 16)
                                SetPedKeepTask(passenger, true)
                            end
                        end

                        local allDead = true
                        for _, passenger in ipairs(passengers) do
                            if DoesEntityExist(passenger) and not IsEntityDead(passenger) then
                                allDead = false
                                break
                            end
                        end

                        if allDead then
                            if IsPedInAnyVehicle(driver, false) then
                                TaskLeaveVehicle(driver, veh, 256)
                                Wait(300)
                            end
                            ClearPedTasksImmediately(driver)
                            GiveWeaponToPed(driver, `WEAPON_PISTOL`, 200, false, true)
                            TaskCombatPed(driver, shooter, 0, 16)
                            SetPedKeepTask(driver, true)
                        end

                        data.patrolThreadRunning = false
                    end
                end

                if activeShooters[veh] then
                    local shooter = activeShooters[veh]
                    local playerPed = PlayerPedId()

                    local shouldReset = false

                    if shooter == playerPed and IsEntityDead(playerPed) then
                        shouldReset = true
                        for _, ped in ipairs(peds) do
                            if DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedInVehicle(ped, veh, false) then
                                MakePedFlee(ped, vehCoords)
                            end
                        end
                    elseif not DoesEntityExist(shooter) or IsEntityDead(shooter) or #(GetEntityCoords(shooter) - vehCoords) > 50.0 then
                        shouldReset = true
                    end

                    if shouldReset then
                        activeShooters[veh] = nil

                        for _, ped in ipairs(passengers) do
                            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                                ClearPedTasksImmediately(ped)
                                if not IsPedInVehicle(ped, veh, false) then
                                    TaskEnterVehicle(ped, veh, -1, 0, 2.0, 1, 0)
                                end
                            end
                        end

                        if DoesEntityExist(driver) and not IsEntityDead(driver) then
                            ClearPedTasksImmediately(driver)
                        end
                    end
                end

                -- NEW: If the driver just got a kill, make them get back in vehicle and resume patrol
                if DoesEntityExist(driver) and not IsEntityDead(driver) and not data.driverGotKillHandled then
                    for _, ped in ipairs(peds) do
                        if DoesEntityExist(ped) and IsEntityDead(ped) and not reportedKills[ped] then
                            local killer = GetPedSourceOfDeath(ped)
                            if killer == driver then
                                reportedKills[ped] = true

                                data.driverGotKillHandled = true

                                -- Clear tasks and make driver enter vehicle and start patrol
                                ClearPedTasks(driver)
                                if not IsPedInVehicle(driver, veh, false) then
                                    TaskEnterVehicle(driver, veh, -1, -1, 2.0, 1, 0)
                                    Wait(1000)
                                end

                                data.patrolThreadRunning = false
                                StartPatrol(data)

                                break
                            end
                        end
                    end
                end

                if IsEntityDead(driver) then
                    local takeoverDone = false
                    for i = 2, #peds do
                        local passenger = peds[i]
                        if DoesEntityExist(passenger) and not IsEntityDead(passenger) and not IsPedInAnyVehicle(passenger, false) then
                            if not takeoverDone then
                                takeoverDone = true
                                ClearPedTasks(passenger)
                                TaskEnterVehicle(passenger, veh, -1, -1, 2.0, 1, 0)
                                Wait(60000)
                                table.remove(peds, i)
                                table.insert(peds, 1, passenger)
                                data.peds = peds
                                if not data.passengerSpawned then
                                    local gangModel = GetPedModelFromGroup(Zones[zoneIndex].gangPedGroup)
                                    RequestModel(gangModel)
                                    while not HasModelLoaded(gangModel) do Wait(50) end
                                    local newPassenger = CreatePedInsideVehicle(veh, 4, gangModel, 0, true, false)
                                    SetEntityAsMissionEntity(newPassenger, true, true)
                                    SetPedRelationshipGroupHash(newPassenger, Zones[zoneIndex].gangPedGroup)
                                    GiveWeaponToPed(newPassenger, `WEAPON_PISTOL`, 100, false, true)
                                    SetPedArmour(newPassenger, 50)
                                    SetPedCanRagdollFromPlayerImpact(newPassenger, false)
                                    table.insert(peds, newPassenger)
                                    data.passengerSpawned = true
                                end
                            else
                                ClearPedTasks(passenger)
                                TaskEnterVehicle(passenger, veh, -1, 0, 2.0, 1, 0)
                            end
                        end
                    end

                    if not takeoverDone and not data.driverRespawnPending then
                        data.driverRespawnPending = true
                        CreateThread(function()
                            Wait(60000)
                            if IsEntityDead(driver) and DoesEntityExist(veh) and not IsEntityDead(veh) then
                                local gangModel = GetPedModelFromGroup(Zones[zoneIndex].gangPedGroup)
                                RequestModel(gangModel)
                                while not HasModelLoaded(gangModel) do Wait(50) end

                                local occupant = GetPedInVehicleSeat(veh, -1)
                                if DoesEntityExist(occupant) and IsEntityDead(occupant) then
                                    TaskLeaveVehicle(occupant, veh, 256)
                                    Wait(500)
                                    DeleteEntity(occupant)
                                end

                                local newDriver = CreatePedInsideVehicle(veh, 4, gangModel, -1, true, false)
                                SetEntityAsMissionEntity(newDriver, true, true)
                                SetPedRelationshipGroupHash(newDriver, Zones[zoneIndex].gangPedGroup)
                                GiveWeaponToPed(newDriver, `WEAPON_PISTOL`, 100, false, true)
                                SetPedArmour(newDriver, 50)
                                SetPedCanRagdollFromPlayerImpact(newDriver, false)

                                if not data.passengerSpawned then
                                    local newPassenger = CreatePedInsideVehicle(veh, 4, gangModel, 0, true, false)
                                    SetEntityAsMissionEntity(newPassenger, true, true)
                                    SetPedRelationshipGroupHash(newPassenger, Zones[zoneIndex].gangPedGroup)
                                    GiveWeaponToPed(newPassenger, `WEAPON_PISTOL`, 100, false, true)
                                    SetPedArmour(newPassenger, 50)
                                    SetPedCanRagdollFromPlayerImpact(newPassenger, false)
                                    table.insert(peds, newPassenger)
                                    data.passengerSpawned = true
                                end

                                for i, ped in ipairs(data.peds) do
                                    if ped == driver then
                                        table.remove(data.peds, i)
                                        break
                                    end
                                end
                                table.insert(peds, 1, newDriver)

                                for i = 2, #peds do
                                    local passenger = peds[i]
                                    if DoesEntityExist(passenger) and not IsPedDeadOrDying(passenger) and not IsPedInVehicle(passenger, veh, false) then
                                        MakePedFlee(passenger, GetEntityCoords(veh))
                                    end
                                end

                                StartPatrol(data)
                            end
                            data.driverRespawnPending = false
                        end)
                    end
                end

                for i = 2, #peds do
                    local passenger = peds[i]
                    if DoesEntityExist(passenger) and IsEntityDead(passenger) and not data.passengerRespawnPending then
                        data.passengerRespawnPending = true
                        CreateThread(function()
                            Wait(60000)
                            if DoesEntityExist(veh) and not IsEntityDead(veh) then
                                local gangModel = GetPedModelFromGroup(Zones[zoneIndex].gangPedGroup)
                                RequestModel(gangModel)
                                while not HasModelLoaded(gangModel) do Wait(50) end

                                for j, ped in ipairs(data.peds) do
                                    if ped == passenger then
                                        table.remove(data.peds, j)
                                        DeleteEntity(passenger)
                                        break
                                    end
                                end

                                local newPassenger = CreatePedInsideVehicle(veh, 4, gangModel, 0, true, false)
                                SetEntityAsMissionEntity(newPassenger, true, true)
                                SetPedRelationshipGroupHash(newPassenger, Zones[zoneIndex].gangPedGroup)
                                GiveWeaponToPed(newPassenger, `WEAPON_PISTOL`, 100, false, true)
                                SetPedArmour(newPassenger, 50)
                                SetPedCanRagdollFromPlayerImpact(newPassenger, false)
                                table.insert(peds, newPassenger)
                            end
                            data.passengerRespawnPending = false
                        end)
                    end
                end

                local allBackIn = true
                for _, ped in ipairs(peds) do
                    if not IsPedInVehicle(ped, veh, false) or IsEntityDead(ped) then
                        allBackIn = false
                        break
                    end
                end

                if allBackIn and not data.patrolThreadRunning then
                    StartPatrol(data)
                end

                for _, ped in ipairs(peds) do
                    if DoesEntityExist(ped) and IsEntityDead(ped) and not reportedKills[ped] then
                        reportedKills[ped] = true
                        local killer = GetPedSourceOfDeath(ped)
                        if killer == PlayerPedId() and IsPedAPlayer(killer) then
                            TriggerServerEvent('mnc:rewardForPedKill')
                            TriggerServerEvent('mnc:registerZoneKill')
                        end
                    end
                end

-- Make driver flee if they're outside vehicle for more than 5 seconds and not attacking
if DoesEntityExist(driver) and not IsEntityDead(driver) and not IsPedInVehicle(driver, veh, false) then
    if not IsPedInCombat(driver, 0) then
        if not driverOutsideSince[driver] then
            driverOutsideSince[driver] = GetGameTimer()
        elseif GetGameTimer() - driverOutsideSince[driver] > 5000 and not fleeingDrivers[driver] then
            ClearPedTasksImmediately(driver)
            TaskSmartFleeCoord(driver, GetEntityCoords(driver), 150.0, -1, false, false)
            SetPedKeepTask(driver, true)
            driverOutsideSince[driver] = nil
            fleeingDrivers[driver] = {
                data = data,
                veh = veh,
                zoneIndex = zoneIndex
            }
        end
    else
        driverOutsideSince[driver] = nil
    end
else
    driverOutsideSince[driver] = nil
end

                ::continue::
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(3000)

        for ped, info in pairs(fleeingDrivers) do
            if DoesEntityExist(ped) and not IsEntityDead(ped) and info and DoesEntityExist(info.veh) and not IsEntityDead(info.veh) then
                local shooter = activeShooters[info.veh]

                -- Threat is gone if shooter is dead or too far or doesn't exist
                local threatGone = false
                if not shooter or not DoesEntityExist(shooter) or IsEntityDead(shooter) or #(GetEntityCoords(shooter) - GetEntityCoords(ped)) > 60.0 then
                    threatGone = true
                end

                if threatGone then
                    ClearPedTasksImmediately(ped)
                    TaskGoToEntity(ped, info.veh, -1, 5.0, 2.0, 1073741824, 0)
                    Wait(3000)

                    if DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false) then
                        TaskEnterVehicle(ped, info.veh, -1, -1, 2.0, 1, 0)
                        Wait(3000)
                        if IsPedInVehicle(ped, info.veh, false) then
                            info.data.patrolThreadRunning = false
                            StartPatrol(info.data)
                            fleeingDrivers[ped] = nil
                        end
                    end
                end
            else
                fleeingDrivers[ped] = nil -- cleanup if ped or vehicle is gone
            end
        end
    end
end)


function GetNearbyPeds(ped, radius)
    local peds = {}
    local coords = GetEntityCoords(ped)
    local handle, found = FindFirstPed()
    local success
    repeat
        if found ~= ped and DoesEntityExist(found) and not IsEntityDead(found) then
            if #(GetEntityCoords(found) - coords) <= radius then
                table.insert(peds, found)
            end
        end
        success, found = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return peds
end

CreateThread(function()
    Wait(5000)
    SpawnZoneVehicles()
end)
