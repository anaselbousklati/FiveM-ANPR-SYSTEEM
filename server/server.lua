RegisterServerEvent("anas-anpr:voegplate")
AddEventHandler("anas-anpr:voegplate", function(plate, reden)
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(src)
    if not pol(xPlayer.source) then return end
    MySQL.Async.fetchAll("SELECT owner FROM owned_vehicles WHERE plate = @plate", {
        ["@plate"] = plate
    },function(result)
        if result[1] == nil then
            Notify("Voertuig met dit kenteken is niet bekend", 'error', xPlayer.source)
        else
            MySQL.Async.fetchAll("SELECT plate FROM anpr WHERE plate = @plate", {
                ["@plate"] = plate
            },function(status)
                if status[1] == nil then
                    MySQL.Async.fetchAll("SELECT firstname, lastname FROM users WHERE identifier = @identifier", {["@identifier"] = result[1].owner}, function(namen)
                        MySQL.Async.execute("INSERT INTO anpr (eigenaar, plate, voornaam, achternaam, reden) VALUES(@eigenaar, @plate, @voornaam, @achternaam, @reden)", {
                            ["@eigenaar"] = result[1].owner,
                            ["@plate"] = plate,
                            ["@voornaam"] = namen[1].firstname,
                            ["@achternaam"] = namen[1].lastname,
                            ["@reden"] = reden
                        })
                        Notify("Voertuig in het systeem gezet", 'success', xPlayer.source)
                        exports['JD_logsV3']:createLog({
                            EmbedMessage = "Voertuig in anpr systeem gezet.\nEigenaar: "..namen[1].firstname.." "..namen[1].lastname.."\nKenteken: "..plate.."\nReden: "..reden,
                            player_id = xPlayer.source,
                            channel = "anpr",
                            screenshot = false
                        })
                    end)
                else
                    Notify("Voertuig staat al in het systeem", 'error', xPlayer.source)
                end
            end)
        end
    end)
end)

RegisterServerEvent("anas-anpr:remvplate")
AddEventHandler("anas-anpr:remvplate", function(plate)
    local src = source 
    local xPlayer = ESX.GetPlayerFromId(src)
    if not pol(xPlayer.source) then return end
    MySQL.Async.fetchAll("SELECT plate FROM anpr WHERE plate = @plate", {
        ["@plate"] = plate
    },function(status)
        if status[1] == nil then
            Notify("Voertuig met dit kenteken staat niet in het systeem", 'error', xPlayer.source)
        else
            MySQL.Async.execute("DELETE FROM anpr WHERE plate = @plate", {["@plate"] = plate})
            Notify("Voertuig uit het systeem gehaald", 'success', xPlayer.source)
            exports['JD_logsV3']:createLog({
                EmbedMessage = "Voertuig uit anpr systeem gezet.\nKenteken: "..plate,
                player_id = xPlayer.source,
                channel = "anpr",
                screenshot = false
            })
        end
    end)
end)

ESX.RegisterServerCallback('anas-anpr:checkplate', function(source, cb, plate)
    MySQL.Async.fetchAll("SELECT plate FROM anpr WHERE plate = @plate", {
        ["@plate"] = plate
    },function(status)
        if status[1] == nil then
            cb(false)
        else
            cb(true)
        end
    end)
end)

pol = function(source)
    local job = ESX.GetPlayerFromId(source).job.name
    for k,v in pairs(DRP.Banen) do
		if v == job then
			return true
    	end
	end
	return false
end

ESX.RegisterServerCallback("anas-anpr:server:anprcars", function(source, callback) 
    if pol(source) then
        local data = {}
        MySQL.Async.fetchAll("SELECT * FROM anpr", {}, function(result)  
            for k,v in pairs(result) do 
                table.insert(data, {
                    eigenaar = v.eigenaar,
                    plate = v.plate,
                    voornaam = v.voornaam,
                    achternaam = v.achternaam,
                    reden = v.reden,
                })
            end
            callback(data)
        end)
    end
end)