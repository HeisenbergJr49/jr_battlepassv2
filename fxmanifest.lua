fx_version 'cerulean'
game 'gta5'

author 'JR.DEV'
description 'JR.DEV Battlepass & Daily Reward System - Professional battlepass system with daily/weekly rewards for FiveM ESX'
version '2.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/missions.lua',
    'client/ui.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
    'server/database.lua',
    'server/rewards.lua',
    'server/admin.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/**/*'
}

dependencies {
    'es_extended',
    'mysql-async',
    'ox_inventory'
}

lua54 'yes'