fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JR.DEV'
description 'Professional Battlepass System for ESX'
version '2.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/**/*'
}

dependencies {
    'es_extended',
    'ox_inventory'
}

provide 'jr_battlepassv2'