-- Обновлённый скрипт KB — сохраняет конфиг прямо в config\crate_log.ini

local samp = require("samp.events")
local imgui = require('imgui')
local encoding = require("encoding")
local inicfg = require("inicfg")
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- Конфиг прямо в папке config
local configName = "crate_log"
local defaultData = {
    log = {
        totalMoney = 0,
        myEarnings = 0,
        myAzCoins = 0,
        showBoxes = true,
        showParticipants = true,
        showTotalMoney = true,
        showEarnings = true,
        showLoot = true
    }
}

local config = inicfg.load(defaultData, configName)
if not doesFileExist("moonloader/config/" .. configName .. ".ini") then
    inicfg.save(config, configName)
end

local prinesli = {}
local lootboxes = {}
local totalMoney = 0
local myEarnings = 0
local myAzCoins = 0
local windowMain = imgui.ImBool(false)
local windowSettings = imgui.ImBool(false)

local displaySettings = {
    showBoxes = imgui.ImBool(true),
    showParticipants = imgui.ImBool(true),
    showTotalMoney = imgui.ImBool(true),
    showEarnings = imgui.ImBool(true),
    showLoot = imgui.ImBool(true)
}

function loadData()
    totalMoney = tonumber(config.log.totalMoney) or 0
    myEarnings = tonumber(config.log.myEarnings) or 0
    myAzCoins = tonumber(config.log.myAzCoins) or 0

    displaySettings.showBoxes.v = config.log.showBoxes ~= false
    displaySettings.showParticipants.v = config.log.showParticipants ~= false
    displaySettings.showTotalMoney.v = config.log.showTotalMoney ~= false
    displaySettings.showEarnings.v = config.log.showEarnings ~= false
    displaySettings.showLoot.v = config.log.showLoot ~= false

    lootboxes = {}
    prinesli = {}
    for k, v in pairs(config.log) do
        if k ~= 'totalMoney' and k ~= 'myEarnings' and k ~= 'myAzCoins' and not k:find('show') then
            if k:find('loot_') then
                lootboxes[k:sub(6)] = tonumber(v)
            else
                prinesli[k] = tonumber(v)
            end
        end
    end
end

function saveData()
    config.log.totalMoney = totalMoney
    config.log.myEarnings = myEarnings
    config.log.myAzCoins = myAzCoins
    config.log.showBoxes = displaySettings.showBoxes.v
    config.log.showParticipants = displaySettings.showParticipants.v
    config.log.showTotalMoney = displaySettings.showTotalMoney.v
    config.log.showEarnings = displaySettings.showEarnings.v
    config.log.showLoot = displaySettings.showLoot.v

    for name, count in pairs(prinesli) do
        config.log[name] = count
    end
    for name, count in pairs(lootboxes) do
        config.log['loot_' .. name] = count
    end

    inicfg.save(config, configName)
end

function samp.onServerMessage(c, m)
    local cleanMessage = m:gsub('{.-}', '')

    local name, money = cleanMessage:match('([^%s]+) пополнил счет организации на %$(%d+) благодаря ящику')
    money = tonumber(money)
    if name and money then
        totalMoney = totalMoney + money
        prinesli[name] = (prinesli[name] or 0) + 1
        saveData()
    end

    local earnings = cleanMessage:match('Вы получили (%d+)%$')
    if earnings then
        myEarnings = myEarnings + tonumber(earnings)
        saveData()
    end

    local az = cleanMessage:match('Вы получили (%d+) AZ Coins')
    if az then
        myAzCoins = myAzCoins + tonumber(az)
        saveData()
    end

    local lootName, count = cleanMessage:match('Вы получили ([^%(]+)%((%d+) шт.%)')
    if lootName and count then
        lootboxes[lootName] = (lootboxes[lootName] or 0) + tonumber(count)
        saveData()
    end

    local singleLoot = cleanMessage:match('Удача! За ящиком лежало еще кое[- ]что: (.+)%.')
    if singleLoot then
        lootboxes[singleLoot] = (lootboxes[singleLoot] or 0) + 1
        saveData()
    end
end

function imgui.OnDrawFrame()
    if windowMain.v then
        local sw, sh = getScreenResolution()

        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)

        imgui.Begin(u8('Лог ящиков'), windowMain,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        local yashiki, col = 0, 0
        for name, count in pairs(prinesli) do
            imgui.Text(u8(string.format('%s принес %d ящик(ов)', name, count)))
            yashiki = yashiki + count
            col = col + 1
        end

        if displaySettings.showBoxes.v then
            imgui.Separator()
            imgui.Text(u8('Общее кол-во ящиков: ' .. yashiki))
        end
        if displaySettings.showParticipants.v then
            imgui.Text(u8('Общее кол-во участников: ' .. col))
        end
        if displaySettings.showTotalMoney.v then
            imgui.Text(u8('Общая сумма денег (организация): $' .. totalMoney))
        end

        if displaySettings.showEarnings.v then
            imgui.Separator()
            imgui.Text(u8('Ваш личный заработок:'))
            imgui.Text(u8('  Гроші: $' .. myEarnings))
            imgui.Text(u8('  АЗ: ' .. myAzCoins .. ' Coins'))
        end

        if displaySettings.showLoot.v then
            imgui.Separator()
            imgui.Text(u8('Выпавшие ларцы:'))
            for name, count in pairs(lootboxes) do
                imgui.Text(u8(string.format('  %s - %d шт.', name, count)))
            end
        end

        imgui.Separator()
        if imgui.Button(u8("Очистить лог"), imgui.ImVec2(280, 30)) then
            prinesli = {}
            lootboxes = {}
            totalMoney = 0
            myEarnings = 0
            myAzCoins = 0
            saveData()
        end

        if imgui.Button(u8("Настройки"), imgui.ImVec2(280, 30)) then
            windowMain.v = false
            windowSettings.v = true
        end

        imgui.End()
    end

    if windowSettings.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(300, 220))

        imgui.Begin(u8("Настройки отображения"), windowSettings, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)

        imgui.Checkbox(u8("Показывать кол-во ящиков"), displaySettings.showBoxes)
        imgui.Checkbox(u8("Показывать участников"), displaySettings.showParticipants)
        imgui.Checkbox(u8("Показывать сумму денег"), displaySettings.showTotalMoney)
        imgui.Checkbox(u8("Показывать заработок"), displaySettings.showEarnings)
        imgui.Checkbox(u8("Показывать ларцы"), displaySettings.showLoot)

        imgui.Separator()
        if imgui.Button(u8("Назад"), imgui.ImVec2(280, 30)) then
            saveData()
            windowSettings.v = false
            windowMain.v = true
        end

        imgui.End()
    end
end

function main()
    loadData()

    while not isSampAvailable() do wait(0) end

    sampAddChatMessage('[Хрюглевское КБ] {03B12C}Скрипт загружен! {ffffff}/kb для включения лога', 0x7614C6)

    sampRegisterChatCommand('kb', function()
        windowMain.v = not windowMain.v
        windowSettings.v = false
    end)

    while true do
        wait(50)
        imgui.Process = windowMain.v or windowSettings.v
        imgui.ShowCursor = false
    end
end