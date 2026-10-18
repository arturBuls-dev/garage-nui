fx_version 'cerulean'
game 'gta5'

author 'Arthur.dev'
description 'Vehicle garage NUI with favorites, server-side spawn and key handling'
version '1.0.0'

lua54 'yes'

ui_page 'web/dist/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_script 'client.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'web/dist/cars/*',
}
