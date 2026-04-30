fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'Opie Winters'
description 'Astro NPC Scrap'
version '1.1.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/bridge.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

escrow_ignore {
    'config.lua',
    'shared/bridge.lua',
    'client/main.lua',
    'server/main.lua',
    'README.md',
    'sql/items.sql',
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependencies {
    'qb-core',
    'qb-menu'
}
