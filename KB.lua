-- ���������� ������ KB � ��������� ������ ����� � config\crate_log.ini

local samp = require("samp.events")
local imgui = require('imgui')
local encoding = require("encoding")
local inicfg = require("inicfg")
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ������ ����� � ����� config
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

    local name, money = cleanMessage:match('([^%s]+) �������� ���� ����������� �� %$(%d+) ��������� �����')
    money = tonumber(money)
    if name and money then
        totalMoney = totalMoney + money
        prinesli[name] = (prinesli[name] or 0) + 1
        saveData()
    end

    local earnings = cleanMessage:match('�� �������� (%d+)%$')
    if earnings then
        myEarnings = myEarnings + tonumber(earnings)
        saveData()
    end

    local az = cleanMessage:match('�� �������� (%d+) AZ Coins')
    if az then
        myAzCoins = myAzCoins + tonumber(az)
        saveData()
    end

    local lootName, count = cleanMessage:match('�� �������� ([^%(]+)%((%d+) ��.%)')
    if lootName and count then
        lootboxes[lootName] = (lootboxes[lootName] or 0) + tonumber(count)
        saveData()
    end

    local singleLoot = cleanMessage:match('�����! �� ������ ������ ��� ���[- ]���: (.+)%.')
    if singleLoot then
        lootboxes[singleLoot] = (lootboxes[singleLoot] or 0) + 1
        saveData()
    end
end

function imgui.OnDrawFrame()
    if windowMain.v then
        local sw, sh = getScreenResolution()

        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)

        imgui.Begin(u8('��� ������'), windowMain,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        local yashiki, col = 0, 0
        for name, count in pairs(prinesli) do
            imgui.Text(u8(string.format('%s ������ %d ����(��)', name, count)))
            yashiki = yashiki + count
            col = col + 1
        end

        if displaySettings.showBoxes.v then
            imgui.Separator()
            imgui.Text(u8('����� ���-�� ������: ' .. yashiki))
        end
        if displaySettings.showParticipants.v then
            imgui.Text(u8('����� ���-�� ����������: ' .. col))
        end
        if displaySettings.showTotalMoney.v then
            imgui.Text(u8('����� ����� ����� (�����������): $' .. totalMoney))
        end

        if displaySettings.showEarnings.v then
            imgui.Separator()
            imgui.Text(u8('��� ������ ���������:'))
            imgui.Text(u8('  �����: $' .. myEarnings))
            imgui.Text(u8('  ��: ' .. myAzCoins .. ' Coins'))
        end

        if displaySettings.showLoot.v then
            imgui.Separator()
            imgui.Text(u8('�������� �����:'))
            for name, count in pairs(lootboxes) do
                imgui.Text(u8(string.format('  %s - %d ��.', name, count)))
            end
        end

        imgui.Separator()
        if imgui.Button(u8("�������� ���"), imgui.ImVec2(280, 30)) then
            prinesli = {}
            lootboxes = {}
            totalMoney = 0
            myEarnings = 0
            myAzCoins = 0
            saveData()
        end

        if imgui.Button(u8("���������"), imgui.ImVec2(280, 30)) then
            windowMain.v = false
            windowSettings.v = true
        end

        imgui.End()
    end

    if windowSettings.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(300, 220))

        imgui.Begin(u8("��������� �����������"), windowSettings, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove + imgui.WindowFlags.NoTitleBar)

        imgui.Checkbox(u8("���������� ���-�� ������"), displaySettings.showBoxes)
        imgui.Checkbox(u8("���������� ����������"), displaySettings.showParticipants)
        imgui.Checkbox(u8("���������� ����� �����"), displaySettings.showTotalMoney)
        imgui.Checkbox(u8("���������� ���������"), displaySettings.showEarnings)
        imgui.Checkbox(u8("���������� �����"), displaySettings.showLoot)

        imgui.Separator()
        if imgui.Button(u8("�����"), imgui.ImVec2(280, 30)) then
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

    sampAddChatMessage('[����������� ��] {03B12C}������ ��������! {ffffff}/kb ��� ��������� ����', 0x7614C6)

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