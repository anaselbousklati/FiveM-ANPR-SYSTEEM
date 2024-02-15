TriggerEvent('chat:addSuggestion', '/anpr', 'anpr systeem', {
	{ name="add/remove", help="Wil je een voertuig toevoegen of verwijderen?" },
})

Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(500)
    end
	ESX.PlayerLoaded = true
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  ESX.PlayerData.job = job
end)

local blips = {}

Citizen.CreateThread(function()    
    while true do
        Citizen.Wait(5000)
        if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
            for k,v in pairs(DRP.ANPRCameras) do
                if not blips[k] then
                    blips[k] = AddBlipForCoord(v.x, v.y, v.z)
                    SetBlipSprite(blips[k], DRP.Blips.Sprite)
                    SetBlipScale(blips[k], DRP.Blips.Grootte)
                    SetBlipColour(blips[k], DRP.Blips.Kleur)
                    SetBlipDisplay(blips[k], 4)
                    SetBlipAsShortRange(blips[k], true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString(DRP.Blips.Tekst)
                    EndTextCommandSetBlipName(blips[k])
                end
            end
        else
            for k,v in pairs(blips) do
                RemoveBlip(v)
                blips[k] = nil
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(6)
        local coords = GetEntityCoords(PlayerPedId(), true)
        slaaplekker = true
        for k,v in pairs(DRP.Markers) do
            local dist = GetDistanceBetweenCoords(coords, v.x, v.y, v.z, true)
            if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
                if dist < 4 then
                    slaaplekker = false
                    DrawMarker(20, vector3(v.x, v.y, v.z), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.3, 0.3, 0.2, DRP.MarkerRGB.r, DRP.MarkerRGB.g, DRP.MarkerRGB.b, 100, false, true, 2, true, false, false, false)
                    if dist < 1.5 then
                        DrawScriptText(vector3(v.x, v.y, v.z + 0.2), v.tekst)
                        if IsControlJustReleased(0,38) then
                            TriggerEvent(v.fnc)
                        end
                    end
                end
            end
        end
        if slaaplekker then
            Wait(900)
        end
    end
end)

RegisterCommand("anpr", function(source, args, rawCommand)
    if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
        if args[1] == "add" then
            local input = lib.inputDialog('Geef alle informatie op om een voertuig toe te voegen aan het anpr systeem', {'Kenteken', 'Reden'})
            if not input then ESX.ShowNotification('Je hebt geen informatie opgegeven!', 'error') return end
            TriggerServerEvent("anas-anpr:voegplate", input[1], input[2])
        elseif args[1] == "remove" then
            local input = lib.inputDialog('Geef alle informatie op om een voertuig uit het anpr systeem te halen', {'Kenteken'})
            if not input then ESX.ShowNotification('Je hebt geen informatie opgegeven!', 'error') return end
            TriggerServerEvent("anas-anpr:remvplate", input[1])
        end
    end
end)

local wachttijd = 500

Citizen.CreateThread(function()
    while true do
        Wait(wachttijd)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(PlayerPedId(), true)
        slaaplekker = true
        if IsPedInAnyVehicle(ped, true) then
            local voertuig = GetVehiclePedIsIn(ped)
            local vcoords = GetEntityCoords(voertuig)
            local plate = ESX.Game.GetVehicleProperties(voertuig).plate
            local snelheid = GetEntitySpeed(voertuig)
            local snelh = snelheid * 3.6
            local fsnelh = string.format("%.2f", snelh)
            for k,v in pairs(DRP.ANPRCameras) do
                local dist = GetDistanceBetweenCoords(vcoords, v.x, v.y, v.z, true)
                if dist < 150 then
                    slaaplekker = false
                    wachttijd = 50
                    if dist < 20 then
                        ESX.TriggerServerCallback('anas-anpr:checkplate', function(hit)
                            if hit then
                                if not sent then
                                    slaaplekker = false
                                    local daap = PlayerPedId()
                                    local coords = GetEntityCoords(PlayerPedId())
                                    exports["drp-meldingen"]:SendDispatch("ANPR HIT! | Snelheid: "..math.floor( fsnelh ).."KM/U", "10-26", 162, {"police"})
                                    sent = true
                                    Wait(10000)
                                    sent = false
                                end
                            else
                                
                            end
                        end, plate)
                    end
                end
            end
        end
        if slaaplekker then
            Wait(3000)
        end
    end
end)

RegisterNetEvent("anas-anpr:computer")
AddEventHandler("anas-anpr:computer", function()
    local duur = math.random(2000, 8000)
    ESX.TriggerServerCallback("anas-anpr:server:anprcars", function(data)
        local inv = {}
        for k,v in pairs(data) do 
            local data = {
                kenteken = v.plate,
                reden = v.reden,
                identifier = v.eigenaar,
                voornaam = v.voornaam,
                achternaam = v.achternaam
            }

            table.insert(inv, {
                title = "Eigenaar: " .. v.voornaam .. " " .. v.achternaam .. "\nKenteken: ".. v.plate,
                description = "Klik om meer informatie weer te geven.",
                icon = 'car',
                arrow = true,
                onSelect = function()
                    openData(data)
                end
            })
        end

        lib.registerContext({
            id = 'anprcars',
            title = 'ANPR Voertuigen',
            options = inv
          })

        if lib.progressActive() then ESX.ShowNotification('Je bent al met iets bezig!', 'error') return end
        
        if lib.progressCircle({
            label = 'Data verkrijgen ANPR...',
            duration = duur,
            position = 'bottom',
            useWhileDead = false,
            allowRagdoll = false,
            allowCuffed = false,
            allowFalling = false, 
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
            },
            anim = {
                dict = 'mp_prison_break',
                clip = 'hack_loop'
            },
        }) then lib.showContext('anprcars') end
    end)
end)

function openData(info)
    local data = {
        {
            ['title'] = 'Naam: '..info.voornaam.." "..info.achternaam,
            ['icon'] = 'signature'
        },
        {
            ['title'] = 'Kenteken: '..info.kenteken,
            ['icon'] = 'circle-info'
        },
        {
            ['title'] = 'Reden: '..info.reden,
            ['icon'] = 'circle-question'
        },
        {
            ['title'] = 'Voertuig uit systeem verwijderen',
            ['arrow'] = true,
            ['serverEvent'] = 'anas-anpr:remvplate',
            ['args'] = info.kenteken,
            ['icon'] = 'delete-left'
        },
    }
    lib.registerContext({
        id = 'anprcarsdata',
        title = 'ANPR Voertuig informatie',
        menu = 'anprcars',
        options = data
      })
     
      lib.showContext('anprcarsdata')
end

function DrawScriptText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords["x"], coords["y"], coords["z"])

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = string.len(text) / 370

    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 65)
end