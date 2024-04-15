fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54        'yes'

files {
    'config/client.lua',
    'config/server.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua'
}
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

