function Notify(tekst, type,source)
    TriggerClientEvent('esx:showNotification', source, tekst, type)
end