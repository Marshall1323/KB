local samp = require("samp.events")
local imgui = require("imgui")
local encoding = require("encoding")
local inicfg = require("inicfg")

encoding.default = "CP1251"
u8 = encoding.UTF8

local configName = "crate_log_configurable"
local defaultData = {
    log = {
        totalMoney = 0,
        myEarnings = 0,
        myRespect = 0,
        totalBoxes = 0,
        showBoxes = true,
        showTotalMoney = true,
        showEarnings = true,
    },
    settings = {
        nickname = "Charlie_Marshall"
    }
}

local config = inicfg.load(defaultData, configName)
if not doesFileExist("moonloader/config/" .. configName .. ".ini") then
    inicfg.save(config, configName)
end

local totalMoney = tonumber(config.log.totalMoney) or 0
local myEarnings = tonumber(config.log.myEarnings) or 0
local myRespect = tonumber(config.log.myRespect) or 0
local totalBoxes = tonumber(config.log.totalBoxes) or 0
local movedBoxes = 0
local nickname = config.settings.nickname or "Charlie_Marshall"

local windowMain = imgui.ImBool(false)
local windowSettings = imgui.ImBool(false)
local windowConfirmClear = imgui.ImBool(false)
local windowConfirmMovedClear = imgui.ImBool(false)

local displaySettings = {
    showBoxes = imgui.ImBool(config.log.showBoxes),
    showTotalMoney = imgui.ImBool(config.log.showTotalMoney),
    showEarnings = imgui.ImBool(config.log.showEarnings),
}

local nicknameBuf = imgui.ImBuffer(64)

local function saveData()
    config.log.totalMoney = totalMoney
    config.log.myEarnings = myEarnings
    config.log.myRespect = myRespect
    config.log.totalBoxes = totalBoxes
    config.log.showBoxes = displaySettings.showBoxes.v
    config.log.showTotalMoney = displaySettings.showTotalMoney.v
    config.log.showEarnings = displaySettings.showEarnings.v
    config.settings.nickname = nickname
    inicfg.save(config, configName)
end

local function clearLog()
    totalMoney = 0
    myEarnings = 0
    myRespect = 0
    totalBoxes = 0
    movedBoxes = 0
    saveData()
end

function samp.onServerMessage(color, message)
    local cleanMessage = message:gsub('{.-}', '')

    local sender, moneyStr = cleanMessage:match('([^%s]+) �������� ���� ����������� �� %$(%d+) ��������� �����')
    if sender and moneyStr then
        local money = tonumber(moneyStr)
        if money then
            movedBoxes = movedBoxes + 1
            if sender == nickname then
                totalMoney = totalMoney + money
                totalBoxes = totalBoxes + 1
                saveData()
            end
        end
        return
    end

    local earningsStr = cleanMessage:match('�� �������� (%d+)%$')
    if earningsStr then
        local money = tonumber(earningsStr)
        if money then
            myEarnings = myEarnings + money
            saveData()
        end
        return
    end

    local respectStr = cleanMessage:match('�� �������� (%d+) AZ Coins')
    if respectStr then
        local respect = tonumber(respectStr)
        if respect then
            myRespect = myRespect + respect
            saveData()
        end
        return
    end
end

function imgui.OnDrawFrame()
    if windowMain.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)

        imgui.Begin(u8("���������� ������ " .. nickname), windowMain,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        imgui.Text(u8("��� ������� ���: " .. nickname))
        imgui.Separator()

        if displaySettings.showBoxes.v then
            imgui.Text(u8('����� ��������� ������: ' .. totalBoxes))
            imgui.Text(u8('���������� �� ��� ��: ' .. movedBoxes))
        end
        if displaySettings.showTotalMoney.v then
            imgui.Text(u8('����� ����� �� ���� �����������: $' .. totalMoney))
        end
        if displaySettings.showEarnings.v then
            imgui.Separator()
            imgui.Text(u8('������ ���������:'))
            imgui.Text(u8('  ������: $' .. myEarnings))
            imgui.Text(u8('  AZ Coins: ' .. myRespect))
        end

        imgui.Separator()

        if imgui.Button(u8("�������� ��� ����������"), imgui.ImVec2(280, 30)) then
            windowMain.v = false
            windowConfirmClear.v = true
        end

        if imgui.Button(u8("�������� ���������� �� ��� ��"), imgui.ImVec2(280, 30)) then
            windowMain.v = false
            windowConfirmMovedClear.v = true
        end

        if imgui.Button(u8("���������"), imgui.ImVec2(280, 30)) then
            windowMain.v = false
            windowSettings.v = true
            nicknameBuf.v = nickname
        end

        imgui.End()
    end

    if windowConfirmClear.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 - 150, sh / 2 - 75), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(300, 70), imgui.Cond.Always)

        imgui.Begin(u8("������������� �������"), windowConfirmClear,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        imgui.Text(u8("�� ����� ������ �������� ��� ����������?"))
        imgui.Separator()

        if imgui.Button(u8("��"), imgui.ImVec2(140, 30)) then
            clearLog()
            windowConfirmClear.v = false
            windowMain.v = true
        end

        imgui.SameLine()

        if imgui.Button(u8("���"), imgui.ImVec2(130, 30)) then
            windowConfirmClear.v = false
            windowMain.v = true
        end

        imgui.End()
    end

    if windowConfirmMovedClear.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 - 150, sh / 2 - 75), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(300, 70), imgui.Cond.Always)

        imgui.Begin(u8("������������� �������"), windowConfirmMovedClear,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        imgui.Text(u8("�������� ������ ���������� �� ��� ��?"))
        imgui.Separator()

        if imgui.Button(u8("��"), imgui.ImVec2(130, 30)) then
            movedBoxes = 0
            windowConfirmMovedClear.v = false
            windowMain.v = true
        end

        imgui.SameLine()

        if imgui.Button(u8("���"), imgui.ImVec2(130, 30)) then
            windowConfirmMovedClear.v = false
            windowMain.v = true
        end

        imgui.End()
    end

    if windowSettings.v then
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw - 320, sh / 4), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(320, 190))

        imgui.Begin(u8("���������"), windowSettings,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove +
            imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoScrollbar)

        imgui.Checkbox(u8("���������� �����"), displaySettings.showBoxes)
        imgui.Checkbox(u8("���������� ����� ����� �����������"), displaySettings.showTotalMoney)
        imgui.Checkbox(u8("���������� ������ ���������"), displaySettings.showEarnings)

        imgui.Separator()

        imgui.Text(u8("��� ��� ��������:"))
        imgui.InputText(u8(""), nicknameBuf)

        imgui.Separator()

        if imgui.Button(u8("���������"), imgui.ImVec2(150, 30)) then
            nickname = nicknameBuf.v
            saveData()
            sampAddChatMessage("[CrateLog] ��� �������: " .. nickname, 0x00FF00)
        end

        imgui.SameLine()

        if imgui.Button(u8("�����"), imgui.ImVec2(150, 30)) then
            windowSettings.v = false
            windowMain.v = true
        end

        imgui.End()
    end
end

function main()
    loadData()

    while not isSampAvailable() do wait(0) end

    sampAddChatMessage(string.format('[CrateLog] ������ �������! ����������� /crate ��� �������� ���� ����������. ������� ���: %s', nickname), 0x00FF00)

    sampRegisterChatCommand("crate", function()
        loadData()
        windowMain.v = not windowMain.v
        windowSettings.v = false
        windowConfirmClear.v = false
        windowConfirmMovedClear.v = false
    end)

    while true do
        wait(50)
        imgui.Process = windowMain.v or windowSettings.v or windowConfirmClear.v or windowConfirmMovedClear.v
        imgui.ShowCursor = false
    end
end

function loadData()
    totalMoney = tonumber(config.log.totalMoney) or 0
    myEarnings = tonumber(config.log.myEarnings) or 0
    myRespect = tonumber(config.log.myRespect) or 0
    totalBoxes = tonumber(config.log.totalBoxes) or 0

    displaySettings.showBoxes.v = config.log.showBoxes ~= false
    displaySettings.showTotalMoney.v = config.log.showTotalMoney ~= false
    displaySettings.showEarnings.v = config.log.showEarnings ~= false

    nickname = config.settings.nickname or "Charlie_Marshall"
end