fx_version 'cerulean'

games { 'gta5' }

lua54 'yes'

client_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'client/*.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/*.lua'
}