Framework = nil

Citizen.CreateThread(function()
    while Framework == nil do
        TriggerEvent('Framework:GetObject', function(obj) Framework = obj end)
        Citizen.Wait(200)
    end
end)

ModdedVehicles = {}
VehicleStatus = {}
ClosestPlate = nil
isLoggedIn = true
PlayerJob = {}

local onDuty = false

function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

Citizen.CreateThread(function()
    while true do
        if isLoggedIn then
            SetClosestPlate()
        end
        Citizen.Wait(1000)
    end
end)

function SetClosestPlate()
    local pos = GetEntityCoords(PlayerPedId(), true)
    local current = nil
    local dist = nil
    for id,_ in pairs(Config.Plates) do
        if current ~= nil then
            if(GetDistanceBetweenCoords(pos, Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z, true) < dist)then
                current = id
                dist = GetDistanceBetweenCoords(pos, Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z, true)
            end
        else
            dist = GetDistanceBetweenCoords(pos, Config.Plates[id].coords.x, Config.Plates[id].coords.y, Config.Plates[id].coords.z, true)
            current = id
        end
    end
    ClosestPlate = current
end

RegisterNetEvent('Framework:Client:OnPlayerLoaded')
AddEventHandler('Framework:Client:OnPlayerLoaded', function()
    Framework.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        if PlayerData.job.onduty then
            if PlayerData.job.name == "mechanic" then
                TriggerServerEvent("Framework:ToggleDuty", true)
            end
        end
    end)
    isLoggedIn = true
    Framework.Functions.TriggerCallback('pepe-vehicletuning:server:GetAttachedVehicle', function(plates)
        for k, v in pairs(plates) do
            Config.Plates[k].AttachedVehicle = v.AttachedVehicle
        end
    end)

    Framework.Functions.TriggerCallback('pepe-vehicletuning:server:GetDrivingDistances', function(retval)
        DrivingDistance = retval
    end)
end)

RegisterNetEvent('Framework:Client:OnJobUpdate')
AddEventHandler('Framework:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = PlayerJob.onduty
end)

RegisterNetEvent('Framework:Client:SetDuty')
AddEventHandler('Framework:Client:SetDuty', function(duty)
    onDuty = duty
end)

Citizen.CreateThread(function()
    local c = Config.Locations["exit"]
    local Blip = AddBlipForCoord(c.x, c.y, c.z)

    SetBlipSprite (Blip, 446)
    SetBlipDisplay(Blip, 4)
    SetBlipScale  (Blip, 0.7)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, 1)
    SetBlipAlpha(Blip, 0.7)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Jones Brothers Mechanic")
    EndTextCommandSetBlipName(Blip)
end)

Citizen.CreateThread(function()
    while true do
        local inRange = false

        if isLoggedIn then
            if PlayerJob.name == "mechanic" then
                local pos = GetEntityCoords(PlayerPedId())
                local StashDistance = GetDistanceBetweenCoords(pos, Config.Locations["stash"].x, Config.Locations["stash"].y, Config.Locations["stash"].z, true)
                local OnDutyDistance = GetDistanceBetweenCoords(pos, Config.Locations["duty"].x, Config.Locations["duty"].y, Config.Locations["duty"].z, true)
                local VehicleDistance = GetDistanceBetweenCoords(pos, Config.Locations["vehicle"].x, Config.Locations["vehicle"].y, Config.Locations["vehicle"].z, true)

                if onDuty then
                    if StashDistance < 20 then
                        inRange = true
                        DrawMarker(2, Config.Locations["stash"].x, Config.Locations["stash"].y, Config.Locations["stash"].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 210, 50, 9, 255, false, false, false, true, false, false, false)

                        if StashDistance < 1 then
                            DrawText3Ds(Config.Locations["stash"].x, Config.Locations["stash"].y, Config.Locations["stash"].z, "[E] Mở")
                            if IsControlJustReleased(0, Keys["E"]) then
                                TriggerEvent("pepe-inventory:client:SetCurrentStash", "mechanicstash")
                                TriggerServerEvent("pepe-inventory:server:OpenInventory", "stash", "mechanicstash", {
                                    maxweight = 4000000,
                                    slots = 500,
                                })
                            end
                        end
                    end
                end

                if onDuty then
                    if VehicleDistance < 20 then
                        inRange = true
                        DrawMarker(2, Config.Locations["vehicle"].x, Config.Locations["vehicle"].y, Config.Locations["vehicle"].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 210, 50, 9, 255, false, false, false, true, false, false, false)
                        if VehicleDistance < 1 then
                            local InVehicle = IsPedInAnyVehicle(PlayerPedId())

                            if InVehicle then
                                DrawText3Ds(Config.Locations["vehicle"].x, Config.Locations["vehicle"].y, Config.Locations["vehicle"].z, '[E] Giấu xe')
                                if IsControlJustPressed(0, Keys["E"]) then
                                    DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                                end
                            else
                                DrawText3Ds(Config.Locations["vehicle"].x, Config.Locations["vehicle"].y, Config.Locations["vehicle"].z, '[E] Lấy xe')
                                if IsControlJustPressed(0, Keys["E"]) then
                                    if IsControlJustPressed(0, Keys["E"]) then
                                        VehicleList()
                                        Menu.hidden = not Menu.hidden
                                    end
                                end
                                Menu.renderGUI()
                            end
                        end
                    end
                end

                if OnDutyDistance < 20 then
                    inRange = true
                    DrawMarker(2, Config.Locations["duty"].x, Config.Locations["duty"].y, Config.Locations["duty"].z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 210, 50, 9, 255, false, false, false, true, false, false, false)

                    if OnDutyDistance < 1 then
                        if onDuty then
                            DrawText3Ds(Config.Locations["duty"].x, Config.Locations["duty"].y, Config.Locations["duty"].z, "[E] Thoát ca làm")
                        else
                            DrawText3Ds(Config.Locations["duty"].x, Config.Locations["duty"].y, Config.Locations["duty"].z, "[E] Vào ca làm")
                        end
                        if IsControlJustReleased(0, Keys["E"]) then
                            TriggerServerEvent("Framework:ToggleDuty")
                        end
                    end
                end

                -- if onDuty then
                --     for k, v in pairs(Config.Plates) do
                --         if v.AttachedVehicle == nil then
                --             local PlateDistance = GetDistanceBetweenCoords(pos, v.coords.x, v.coords.y, v.coords.z)
                --             if PlateDistance < 20 then
                --                 inRange = true
                --                 DrawMarker(2, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 255, 255, 255, 255, 0, 0, 0, 1, 0, 0, 0)
                --                 if PlateDistance < 2 then
                --                     local veh = GetVehiclePedIsIn(PlayerPedId())
                --                     if IsPedInAnyVehicle(PlayerPedId()) then
                --                         if not IsThisModelABicycle(GetEntityModel(veh)) then
                --                             DrawText3Ds(v.coords.x, v.coords.y, v.coords.z + 0.3, "[E] Đặt chiếc xe trên nền tảng")
                --                             if IsControlJustPressed(0, Config.Keys["E"]) then
                --                                 DoScreenFadeOut(150)
                --                                 Wait(150)
                --                                 Config.Plates[ClosestPlate].AttachedVehicle = veh
                --                                 SetEntityCoords(veh, v.coords.x, v.coords.y, v.coords.z)
                --                                 SetEntityHeading(veh, v.coords.h)
                --                                 FreezeEntityPosition(veh, true)
                --                                 Wait(500)
                --                                 DoScreenFadeIn(250)
                --                                 TriggerServerEvent('pepe-vehicletuning:server:SetAttachedVehicle', veh, k)
                --                             end
                --                         else
                --                             Framework.Functions.Notify("Bạn không thể đặt xe đạp trên đĩa!", "error")
                --                         end
                --                     end
                --                 end
                --             end
                --         else
                --             local PlateDistance = GetDistanceBetweenCoords(pos, v.coords.x, v.coords.y, v.coords.z)
                --             if PlateDistance < 3 then
                --                 inRange = true
                --                 DrawText3Ds(v.coords.x, v.coords.y, v.coords.z, "[E] Menu tùy chọn mở")
                --                 if IsControlJustPressed(0, Keys["E"]) then
                --                     OpenMenu()
                --                     Menu.hidden = not Menu.hidden
                --                 end
                --                 Menu.renderGUI()
                --             end
                --         end
                --     end
                -- end

                if not inRange then
                    Citizen.Wait(1500)
                end
            else
                Citizen.Wait(1500)
            end
        else
            Citizen.Wait(1500)
        end

        Citizen.Wait(3)
    end
end)

function niks()
    --print('niks')
end

function OpenMenu()
    ClearMenu()
    Menu.addButton("Tùy chọn", "VehicleOptions", nil)
    Menu.addButton("Đóng menu", "CloseMenu", nil) 
end

function VehicleList()
    ClearMenu()
    for k, v in pairs(Config.Vehicles) do
        Menu.addButton(v, "SpawnListVehicle", k) 
    end
    Menu.addButton("Đóng menu", "CloseMenu", nil) 
end

function SpawnListVehicle(model)
    local coords = {
        x = Config.Locations["vehicle"].x,
        y = Config.Locations["vehicle"].y,
        z = Config.Locations["vehicle"].z,
        h = Config.Locations["vehicle"].h,
    }
    local plate = "AC"..math.random(1111, 9999)
    Framework.Functions.SpawnVehicle(model, function(veh)
        SetVehicleNumberPlateText(veh, "CUSTOMS"..tostring(math.random(1, 9)))
        SetEntityHeading(veh, coords.h)
        exports['pepe-fuel']:SetFuelLevel(Vehicle, GetVehicleNumberPlateText(veh), 100, false)
        Menu.hidden = true
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        exports['pepe-vehiclekeys']:SetVehicleKey(GetVehicleNumberPlateText(veh), true)
        SetVehicleEngineOn(veh, true, true)
    end, coords, true)
end

function VehicleOptions()
    ClearMenu()
    Menu.addButton("Bỏ qua xe", "UnattachVehicle", nil)
    -- Menu.addButton("Check Status", "CheckStatus", nil)
    Menu.addButton("Menu các bộ phận", "PartsMenu", nil)
    Menu.addButton("Đóng menu", "CloseMenu", nil)
end

function PartsMenu()
    ClearMenu()
    local plate = GetVehicleNumberPlateText(Config.Plates[ClosestPlate].AttachedVehicle)
    if VehicleStatus[plate] ~= nil then
        for k, v in pairs(Config.ValuesLabels) do
            if math.ceil(VehicleStatus[plate][k]) ~= Config.MaxStatusValues[k] then
                local percentage = math.ceil(VehicleStatus[plate][k])
                if percentage > 100 then
                    percentage = math.ceil(VehicleStatus[plate][k]) / 10
                end
                Menu.addButton(v..": "..percentage.."%", "PartMenu", k) 
            else
                local percentage = math.ceil(Config.MaxStatusValues[k])
                if percentage > 100 then
                    percentage = math.ceil(Config.MaxStatusValues[k]) / 10
                end
                Menu.addButton(v..": "..percentage.."%", "NoDamage", nil) 
            end
        end
    else
        for k, v in pairs(Config.ValuesLabels) do
            local percentage = math.ceil(Config.MaxStatusValues[k])
            if percentage > 100 then
                percentage = math.ceil(Config.MaxStatusValues[k]) / 10
            end
            Menu.addButton(v..": "..percentage.."%", "NoDamage", nil) 
        end
    end
    Menu.addButton("Quay lại", "VehicleOptions", nil) 
    Menu.addButton("Đóng menu", "CloseMenu", nil) 
end

function CheckStatus()
    local plate = GetVehicleNumberPlateText(Config.Plates[ClosestPlate].AttachedVehicle)
    SendStatusMessage(VehicleStatus[plate])
end

function PartMenu(part)
    ClearMenu()
    Menu.addButton("Sửa chữa ("..Framework.Shared.Items[Config.RepairCostAmount[part].item]["label"].." "..Config.RepairCostAmount[part].costs.."x)", "RepairPart", part)
    Menu.addButton("Quay lại", "VehicleOptions", nil)
    Menu.addButton("Đóng menu", "CloseMenu", nil) 
end

function NoDamage(part)
    ClearMenu()
    Menu.addButton("Không có thiệt hại cho phần này!", "PartsMenu", part)
    Menu.addButton("Quay lại", "VehicleOptions", nil)
    Menu.addButton("Đóng menu", "CloseMenu", nil) 
end

function RepairPart(part)
    local plate = GetVehicleNumberPlateText(Config.Plates[ClosestPlate].AttachedVehicle)
    local PartData = Config.RepairCostAmount[part]

    Framework.Functions.TriggerCallback('pepe-inventory:server:GetStashItems', function(StashItems)
        for k, v in pairs(StashItems) do
            if v.name == PartData.item then
                if v.amount >= PartData.costs then
                    Framework.Functions.Progressbar("repair_part", Config.ValuesLabels[part].." Đang sửa chữa", math.random(5000, 10000), false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function() -- Done
                        if (v.amount - PartData.costs) <= 0 then
                            StashItems[k] = nil
                        else
                            v.amount = (v.amount - PartData.costs)
                        end
                        TriggerEvent('pepe-vehicletuning:client:RepaireeePart', part)
                        TriggerServerEvent('pepe-inventory:server:SaveStashItems', "mechanicstash", StashItems)
                        SetTimeout(250, function()
                            PartsMenu()
                        end)
                    end, function()
                        Framework.Functions.Notify("Sửa chữa bị hủy bỏ..", "error")
                    end)
                    break
                else
                    Framework.Functions.Notify('Không có đủ vật liệu trong kho..', 'error')
                end
                break
        --  else
        --      Framework.Functions.Notify('There are not enough materials in the safe..', 'error')
            end
        end
    end, "mechanicstash")
end

--

RegisterNetEvent('pepe-vehicletuning:client:RepaireeePart')
AddEventHandler('pepe-vehicletuning:client:RepaireeePart', function(part)
    local veh = Config.Plates[ClosestPlate].AttachedVehicle
    local plate = GetVehicleNumberPlateText(veh)
    if part == "engine" then
        SetVehicleEngineHealth(veh, Config.MaxStatusValues[part])
        TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", Config.MaxStatusValues[part])
    elseif part == "body" then
        SetVehicleBodyHealth(veh, Config.MaxStatusValues[part])
        TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", Config.MaxStatusValues[part])
        SetVehicleFixed(veh)
    else
        TriggerServerEvent("vehiclemod:server:updatePart", plate, part, Config.MaxStatusValues[part])
    end
    Framework.Functions.Notify("Các "..Config.ValuesLabels[part].." đã được sửa chữa!", 'success')
end)

function UnattachVehicle()
    local coords = Config.Locations["exit"]
    DoScreenFadeOut(150)
    Wait(150)
    FreezeEntityPosition(Config.Plates[ClosestPlate].AttachedVehicle, false)
    SetEntityCoords(Config.Plates[ClosestPlate].AttachedVehicle, Config.Plates[ClosestPlate].coords.x, Config.Plates[ClosestPlate].coords.y, Config.Plates[ClosestPlate].coords.z)
    SetEntityHeading(Config.Plates[ClosestPlate].AttachedVehicle, Config.Plates[ClosestPlate].coords.h)
    TaskWarpPedIntoVehicle(PlayerPedId(), Config.Plates[ClosestPlate].AttachedVehicle, -1)
    Wait(500)
    DoScreenFadeIn(250)
    Config.Plates[ClosestPlate].AttachedVehicle = nil
    TriggerServerEvent('pepe-vehicletuning:server:SetAttachedVehicle', false, ClosestPlate)
end

RegisterNetEvent('pepe-vehicletuning:client:SetAttachedVehicle')
AddEventHandler('pepe-vehicletuning:client:SetAttachedVehicle', function(veh, key)
    if veh ~= false then
        Config.Plates[key].AttachedVehicle = veh
    else
        Config.Plates[key].AttachedVehicle = nil
    end
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1)
        if (IsPedInAnyVehicle(PlayerPedId(), false)) then
            local veh = GetVehiclePedIsIn(PlayerPedId(),false)
            if ModdedVehicles[tostring(veh)] == nil and not IsThisModelABicycle(GetEntityModel(veh)) then
                --[[local fSteeringLock = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fSteeringLock')
                fSteeringLock = math.ceil((fSteeringLock * 0.6)) + 0.1

                SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSteeringLock', fSteeringLock)
                SetVehicleHandlingField(veh, 'CHandlingData', 'fSteeringLock', fSteeringLock)]]--

                local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')

                if IsThisModelABike(GetEntityModel(veh)) then
                    local fTractionCurveMin = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMin')

                    fTractionCurveMin = fTractionCurveMin * 0.6
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMin', fTractionCurveMin)
                    SetVehicleHandlingField(veh, 'CHandlingData', 'fTractionCurveMin', fTractionCurveMin)   

                    -- local fTractionCurveMax = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax')
                    -- fTractionCurveMax = fTractionCurveMax * 0.6
                    -- SetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionCurveMax', fTractionCurveMax)
                    -- SetVehicleHandlingField(veh, 'CHandlingData', 'fTractionCurveMax', fTractionCurveMax)

                    local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
                    fInitialDriveForce = fInitialDriveForce * 2.4
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce', fInitialDriveForce)

                    local fBrakeForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce')
                    fBrakeForce = fBrakeForce * 1.4
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce', fBrakeForce)
                    
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionReboundDamp', 5.000000)
                    SetVehicleHandlingField(veh, 'CHandlingData', 'fSuspensionReboundDamp', 5.000000)

                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionCompDamp', 5.000000)
                    SetVehicleHandlingField(veh, 'CHandlingData', 'fSuspensionCompDamp', 5.000000)

                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fSuspensionForce', 22.000000)
                    SetVehicleHandlingField(veh, 'CHandlingData', 'fSuspensionForce', 22.000000)

                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fCollisionDamageMult', 2.500000)
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fEngineDamageMult', 0.120000)
                else
                    local fBrakeForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce')
                    fBrakeForce = fBrakeForce * 0.5
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fBrakeForce', fBrakeForce)

                    local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
                    if fInitialDriveForce < 0.289 then
                        fInitialDriveForce = fInitialDriveForce * 1.2
                        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce', fInitialDriveForce)
                    else
                        fInitialDriveForce = fInitialDriveForce * 0.9
                        SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce', fInitialDriveForce)
                    end
                                
                    local fInitialDragCoeff = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDragCoeff')
                    fInitialDragCoeff = fInitialDragCoeff * 0.3
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDragCoeff', fInitialDragCoeff)

                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fEngineDamageMult', 0.100000)
                    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fCollisionDamageMult', 2.900000)

                end
                SetVehicleHandlingFloat(veh, 'CHandlingData', 'fDeformationDamageMult', 1.000000)
                SetVehicleHasBeenOwnedByPlayer(veh,true)
                ModdedVehicles[tostring(veh)] = { 
                    ["fInitialDriveMaxFlatVel"] = fInitialDriveMaxFlatVel, 
                    ["fSteeringLock"] = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fSteeringLock'), 
                    ["fTractionLossMult"] = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fTractionLossMult'), 
                    ["fLowSpeedTractionLossMult"] = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fLowSpeedTractionLossMult') 
                }
            else
                Citizen.Wait(1000)
            end
        else
            Citizen.Wait(2000)
        end
    end
end)
local effectTimer = 0
Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(1000)
        if (IsPedInAnyVehicle(PlayerPedId(), false)) then
            local veh = GetVehiclePedIsIn(PlayerPedId(),false)
            if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                local engineHealth = GetVehicleEngineHealth(veh)
                local bodyHealth = GetVehicleBodyHealth(veh)
                local plate = GetVehicleNumberPlateText(veh)
                if VehicleStatus[plate] == nil then 
                    TriggerServerEvent("vehiclemod:server:setupVehicleStatus", plate, engineHealth, bodyHealth)
                else
                    TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", engineHealth)
                    TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", bodyHealth)
                    effectTimer = effectTimer + 1
                    if effectTimer >= math.random(10, 15) then
                        ApplyEffects(veh)
                        effectTimer = 0
                    end
                end
            else
                effectTimer = 0
                Citizen.Wait(1000)
            end
        else
            effectTimer = 0
            Citizen.Wait(2000)
        end
    end
end)

RegisterNetEvent('vehiclemod:client:setVehicleStatus')
AddEventHandler('vehiclemod:client:setVehicleStatus', function(plate, status)
    VehicleStatus[plate] = status
end)

RegisterNetEvent('vehiclemod:client:getVehicleStatus')
AddEventHandler('vehiclemod:client:getVehicleStatus', function(plate, status)
    if not (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(), true)
        if veh ~= nil and veh ~= 0 then
            local vehpos = GetEntityCoords(veh)
            local pos = GetEntityCoords(PlayerPedId())
            if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, vehpos.x, vehpos.y, vehpos.z, true) < 5.0 then
                if not IsThisModelABicycle(GetEntityModel(veh)) then
                    local plate = GetVehicleNumberPlateText(veh)
                    if VehicleStatus[plate] ~= nil then 
                        SendStatusMessage(VehicleStatus[plate])
                    else
                        Framework.Functions.Notify("Không có trạng thái được biết đến..", "error")
                    end
                else
                    Framework.Functions.Notify("Không phải là một chiếc xe hợp lệ..", "error")
                end
            else
                Framework.Functions.Notify("You are not close enough to the vehicle..", "error")
            end
        else
            Framework.Functions.Notify("You must be in the vehicle first..", "error")
        end
    else
        Framework.Functions.Notify("You must be outside the vehicle..", "error")
    end
end)

RegisterNetEvent('vehiclemod:client:fixEverything')
AddEventHandler('vehiclemod:client:fixEverything', function()
    if (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(),false)
        if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local plate = GetVehicleNumberPlateText(veh)
            TriggerServerEvent("vehiclemod:server:fixEverything", plate)
        else
            Framework.Functions.Notify("Bạn không phải là một người lái xe hoặc trên một chiếc xe đạp..", "error")
        end
    else
        Framework.Functions.Notify("Bạn không ở trong một chiếc xe..", "error")
    end
end)

RegisterNetEvent('vehiclemod:client:setPartLevel')
AddEventHandler('vehiclemod:client:setPartLevel', function(part, level)
    if (IsPedInAnyVehicle(PlayerPedId(), false)) then
        local veh = GetVehiclePedIsIn(PlayerPedId(),false)
        if not IsThisModelABicycle(GetEntityModel(veh)) and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local plate = GetVehicleNumberPlateText(veh)
            if part == "engine" then
                SetVehicleEngineHealth(veh, level)
                TriggerServerEvent("vehiclemod:server:updatePart", plate, "engine", GetVehicleEngineHealth(veh))
            elseif part == "body" then
                SetVehicleBodyHealth(veh, level)
                TriggerServerEvent("vehiclemod:server:updatePart", plate, "body", GetVehicleBodyHealth(veh))
            else
                TriggerServerEvent("vehiclemod:server:updatePart", plate, part, level)
            end
        else
            Framework.Functions.Notify("Bạn không phải là một người lái xe hoặc trên một chiếc xe đạp..", "error")
        end
    else
        Framework.Functions.Notify("Bạn không ở trong một chiếc xe..", "error")
    end
end)
local openingDoor = false

RegisterNetEvent('vehiclemod:client:repairPart')
AddEventHandler('vehiclemod:client:repairPart', function(part, level, needAmount)
    -- if CanReapair() then
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            local veh = GetVehiclePedIsIn(PlayerPedId(), true)
            if veh ~= nil and veh ~= 0 then
                local vehpos = GetEntityCoords(veh)
                local pos = GetEntityCoords(PlayerPedId())
                if GetDistanceBetweenCoords(pos.x, pos.y, pos.z, vehpos.x, vehpos.y, vehpos.z, true) < 5.0 then
                    if not IsThisModelABicycle(GetEntityModel(veh)) then
                        local plate = GetVehicleNumberPlateText(veh)
                        if VehicleStatus[plate] ~= nil and VehicleStatus[plate][part] ~= nil then
                            local lockpickTime = (1000 * level)
                            if part == "body" then
                                lockpickTime = lockpickTime / 10
                            end
                            ScrapAnim(lockpickTime)
                            Framework.Functions.Progressbar("repair_advanced", "Đang sửa chữa..", lockpickTime, false, true, {
                                disableMovement = true,
                                disableCarMovement = true,
                                disableMouse = false,
                                disableCombat = true,
                            }, {
                                animDict = "mp_car_bomb",
                                anim = "car_bomb_mechanic",
                                flags = 16,
                            }, {}, {}, function() -- Done
                                openingDoor = false
                                ClearPedTasks(PlayerPedId())
                                if part == "body" then
                                    SetVehicleBodyHealth(veh, GetVehicleBodyHealth(veh) + level)
                                    SetVehicleFixed(veh)
                                    TriggerServerEvent("vehiclemod:server:updatePart", plate, part, GetVehicleBodyHealth(veh))
                                    TriggerServerEvent("Framework:Server:RemoveItem", Config.RepairCost[part], needAmount)
                                    TriggerEvent("pepe-inventory:client:ItemBox", Framework.Shared.Items[Config.RepairCost[part]], "remove")
                                elseif part ~= "engine" then
                                    TriggerServerEvent("vehiclemod:server:updatePart", plate, part, GetVehicleStatus(plate, part) + level)
                                    TriggerServerEvent("Framework:Server:RemoveItem", Config.RepairCost[part], level)
                                    TriggerEvent("pepe-inventory:client:ItemBox", Framework.Shared.Items[Config.RepairCost[part]], "remove")
                                end
                            end, function() -- Cancel
                                openingDoor = false
                                ClearPedTasks(PlayerPedId())
                                Framework.Functions.Notify("Hủy bỏ..", "error")
                            end)
                        else
                            Framework.Functions.Notify("Không phải là một phần hợp lệ..", "error")
                        end
                    else
                        Framework.Functions.Notify("Không phải là một chiếc xe hợp lệ..", "error")
                    end
                else
                    Framework.Functions.Notify("Bạn không đủ gần với xe..", "error")
                end
            else
                Framework.Functions.Notify("Bạn phải ở trong xe trước..", "error")
            end
        else
            Framework.Functions.Notify("Bạn không ở trong một chiếc xe..", "error")
        end
    -- end
end)

function ScrapAnim(time)
    local time = time / 1000
    loadAnimDict("mp_car_bomb")
    TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic" ,3.0, 3.0, -1, 16, 0, false, false, false)
    openingDoor = true
    Citizen.CreateThread(function()
        while openingDoor do
            TaskPlayAnim(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Citizen.Wait(2000)
            time = time - 2
            if time <= 0 then
                openingDoor = false
                StopAnimTask(PlayerPedId(), "mp_car_bomb", "car_bomb_mechanic", 1.0)
            end
        end
    end)
end

function CanReapair()
    local retval = false
    for k, v in pairs(Config.Businesses) do
        retval = exports['pepe-companies']:IsEmployee(v)
    end
    return retval
end

function ApplyEffects(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if GetVehicleClass(vehicle) ~= 13 and GetVehicleClass(vehicle) ~= 21 and GetVehicleClass(vehicle) ~= 16 and GetVehicleClass(vehicle) ~= 15 and GetVehicleClass(vehicle) ~= 14 then
        if VehicleStatus[plate] ~= nil then 
            local chance = math.random(1, 100)
            if VehicleStatus[plate]["radiator"] <= 80 and (chance >= 1 and chance <= 20) then
                local engineHealth = GetVehicleEngineHealth(vehicle)
                if VehicleStatus[plate]["radiator"] <= 80 and VehicleStatus[plate]["radiator"] >= 60 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(10, 15))
                elseif VehicleStatus[plate]["radiator"] <= 59 and VehicleStatus[plate]["radiator"] >= 40 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(15, 20))
                elseif VehicleStatus[plate]["radiator"] <= 39 and VehicleStatus[plate]["radiator"] >= 20 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(20, 30))
                elseif VehicleStatus[plate]["radiator"] <= 19 and VehicleStatus[plate]["radiator"] >= 6 then
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(30, 40))
                else
                    SetVehicleEngineHealth(vehicle, engineHealth - math.random(40, 50))
                end
            end

            if VehicleStatus[plate]["axle"] <= 80 and (chance >= 21 and chance <= 40) then
                if VehicleStatus[plate]["axle"] <= 80 and VehicleStatus[plate]["axle"] >= 60 then
                    for i=0,360 do					
                        SetVehicleSteeringScale(vehicle,i)
                        Citizen.Wait(5)
                    end
                elseif VehicleStatus[plate]["axle"] <= 59 and VehicleStatus[plate]["axle"] >= 40 then
                    for i=0,360 do	
                        Citizen.Wait(10)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                elseif VehicleStatus[plate]["axle"] <= 39 and VehicleStatus[plate]["axle"] >= 20 then
                    for i=0,360 do
                        Citizen.Wait(15)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                elseif VehicleStatus[plate]["axle"] <= 19 and VehicleStatus[plate]["axle"] >= 6 then
                    for i=0,360 do
                        Citizen.Wait(20)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                else
                    for i=0,360 do
                        Citizen.Wait(25)
                        SetVehicleSteeringScale(vehicle,i)
                    end
                end
            end

            if VehicleStatus[plate]["brakes"] <= 80 and (chance >= 41 and chance <= 60) then
                if VehicleStatus[plate]["brakes"] <= 80 and VehicleStatus[plate]["brakes"] >= 60 then
                    SetVehicleHandbrake(vehicle, true)
                    Citizen.Wait(1000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 59 and VehicleStatus[plate]["brakes"] >= 40 then
                    SetVehicleHandbrake(vehicle, true)
                    Citizen.Wait(3000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 39 and VehicleStatus[plate]["brakes"] >= 20 then
                    SetVehicleHandbrake(vehicle, true)
                    Citizen.Wait(5000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["brakes"] <= 19 and VehicleStatus[plate]["brakes"] >= 6 then
                    SetVehicleHandbrake(vehicle, true)
                    Citizen.Wait(7000)
                    SetVehicleHandbrake(vehicle, false)
                else
                    SetVehicleHandbrake(vehicle, true)
                    Citizen.Wait(9000)
                    SetVehicleHandbrake(vehicle, false)
                end
            end

            if VehicleStatus[plate]["clutch"] <= 80 and (chance >= 61 and chance <= 80) then
                if VehicleStatus[plate]["clutch"] <= 80 and VehicleStatus[plate]["clutch"] >= 60 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Citizen.Wait(50)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Citizen.Wait(5)
                    end
                    Citizen.Wait(500)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 59 and VehicleStatus[plate]["clutch"] >= 40 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Citizen.Wait(100)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Citizen.Wait(5)
                    end
                    Citizen.Wait(750)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 39 and VehicleStatus[plate]["clutch"] >= 20 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Citizen.Wait(150)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Citizen.Wait(5)
                    end
                    Citizen.Wait(1000)
                    SetVehicleHandbrake(vehicle, false)
                elseif VehicleStatus[plate]["clutch"] <= 19 and VehicleStatus[plate]["clutch"] >= 6 then
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Citizen.Wait(200)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Citizen.Wait(5)
                    end
                    Citizen.Wait(1250)
                    SetVehicleHandbrake(vehicle, false)
                else
                    SetVehicleHandbrake(vehicle, true)
                    SetVehicleEngineOn(vehicle,0,0,1)
                    SetVehicleUndriveable(vehicle,true)
                    Citizen.Wait(250)
                    SetVehicleEngineOn(vehicle,1,0,1)
                    SetVehicleUndriveable(vehicle,false)
                    for i=1,360 do
                        SetVehicleSteeringScale(vehicle, i)
                        Citizen.Wait(5)
                    end
                    Citizen.Wait(1500)
                    SetVehicleHandbrake(vehicle, false)
                end
            end

            --[[ if VehicleStatus[plate]["fuel"] <= 80 and (chance >= 81 and chance <= 100) then
                local fuel = exports['LegacyFuel']:GetFuel(vehicle)
                if VehicleStatus[plate]["fuel"] <= 80 and VehicleStatus[plate]["fuel"] >= 60 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 2.0)
                elseif VehicleStatus[plate]["fuel"] <= 59 and VehicleStatus[plate]["fuel"] >= 40 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 4.0)
                elseif VehicleStatus[plate]["fuel"] <= 39 and VehicleStatus[plate]["fuel"] >= 20 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 6.0)
                elseif VehicleStatus[plate]["fuel"] <= 19 and VehicleStatus[plate]["fuel"] >= 6 then
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 8.0)
                else
                    exports['LegacyFuel']:SetFuel(vehicle, fuel - 10.0)
                end
            end ]]
        end
    end
end

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

function GetVehicleStatusList(plate)
    local retval = nil
    if VehicleStatus[plate] ~= nil then 
        retval = VehicleStatus[plate]
    end
    return retval
end

function GetVehicleStatus(plate, part)
    local retval = nil
    if VehicleStatus[plate] ~= nil then 
        retval = VehicleStatus[plate][part]
    end
    return retval
end

function SetVehicleStatus(plate, part, level)
    TriggerServerEvent("vehiclemod:server:updatePart", plate, part, level)
end

function SendStatusMessage(statusList)
    if statusList ~= nil then 
        TriggerEvent('chat:addMessage', {
            template = '<div class="chat-message normal"><div class="chat-message-body"><strong>{0}:</strong><br><br> <strong>'.. Config.ValuesLabels["engine"] ..' (Động cơ):</strong> {1} <br><strong>'.. Config.ValuesLabels["body"] ..' (body):</strong> {2} <br><strong>'.. Config.ValuesLabels["radiator"] ..' (radiator):</strong> {3} <br><strong>'.. Config.ValuesLabels["axle"] ..' (axle):</strong> {4}<br><strong>'.. Config.ValuesLabels["brakes"] ..' (brakes):</strong> {5}<br><strong>'.. Config.ValuesLabels["clutch"] ..' (clutch):</strong> {6}<br><strong>'.. Config.ValuesLabels["fuel"] ..' (fuel):</strong> {7}</div></div>',
            args = {'Tình trạng xe', round(statusList["engine"]) .. "/" .. Config.MaxStatusValues["engine"] .. " ("..Framework.Shared.Items["advancedrepairkit"]["label"]..")", round(statusList["body"]) .. "/" .. Config.MaxStatusValues["body"] .. " ("..Framework.Shared.Items[Config.RepairCost["body"]]["label"]..")", round(statusList["radiator"]) .. "/" .. Config.MaxStatusValues["radiator"] .. ".0 ("..Framework.Shared.Items[Config.RepairCost["radiator"]]["label"]..")", round(statusList["axle"]) .. "/" .. Config.MaxStatusValues["axle"] .. ".0 ("..Framework.Shared.Items[Config.RepairCost["axle"]]["label"]..")", round(statusList["brakes"]) .. "/" .. Config.MaxStatusValues["brakes"] .. ".0 ("..Framework.Shared.Items[Config.RepairCost["brakes"]]["label"]..")", round(statusList["clutch"]) .. "/" .. Config.MaxStatusValues["clutch"] .. ".0 ("..Framework.Shared.Items[Config.RepairCost["clutch"]]["label"]..")", round(statusList["fuel"]) .. "/" .. Config.MaxStatusValues["fuel"] .. ".0 ("..Framework.Shared.Items[Config.RepairCost["fuel"]]["label"]..")"}
        })
    end
end

function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 1) .. "f", num))
end

-- Menu Functions

CloseMenu = function()
    Menu.hidden = true
    currentGarage = nil
    ClearMenu()
end

ClearMenu = function()
	--Menu = {}
	Menu.GUI = {}
	Menu.buttonCount = 0
	Menu.selection = 0
end

function noSpace(str)
    local normalisedString = string.gsub(str, "%s+", "")
    return normalisedString
end