script_name("My Salary")
script_authors("mihaha")
script_version("0.3")
require 'moonloader'
local imgui = require 'imgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'

encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ���������� ����������
local playerMoney = 0
local currentMoney = 0
local earned = 0
local spended = 0
local sessionSalary = 0
local main_window_state = imgui.ImBool(false)

-- ���� � JSON-�����
local path = getWorkingDirectory() .. "\\config\\MySalary[Data].json"

-- ��������� ������
local data = {
    salary = {}, -- ����� ����� ��������� ������ �� ����
    update_date = "" -- ��������� ���� ����������
}

-- ������������� �����
if not doesFileExist(path) then
    createDirectory(getWorkingDirectory() .. "\\config\\")
    local file = io.open(path, "w")
    file:write(encodeJson(data))
    file:close()
else
    local file = io.open(path, "r")
    data = decodeJson(file:read("*a"))
    file:close()
end

-- ������� ��� ��������� ������� ����
function getCurrentDate()
    return os.date("%Y-%m-%d") -- ������: 2025-01-29
end

-- �������� ������ �� ������� ����
function loadData()
    local currentDate = getCurrentDate()
    if data.salary[currentDate] then
        earned = data.salary[currentDate].earned or 0
        spended = data.salary[currentDate].spended or 0
        sessionSalary = data.salary[currentDate].sessionSalary or 0
    else
        earned = 0
        spended = 0
        sessionSalary = 0
    end
end

-- ���������� ������ � ����
function saveData()
    local currentDate = getCurrentDate()
    data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        sessionSalary = sessionSalary
    }
    data.update_date = currentDate

    local file = io.open(path, "w")
    file:write(encodeJson(data))
    file:close()
end

-- �������� �������
function main()
    sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ �����������. ������� ����: {3d85c6} /msalary", 0xFFFFFF)
    sampRegisterChatCommand("msalary", openWindow)

    loadData()

    while true do
        if sampIsLocalPlayerSpawned() then
            currentMoney = getPlayerMoney(Player)
            while true do
                playerMoney = getPlayerMoney(Player)
                if currentMoney < playerMoney then
                    earned = earned + (playerMoney - currentMoney)
                elseif currentMoney > playerMoney then
                    spended = spended - (currentMoney - playerMoney)
                end
                sessionSalary = earned + spended
                currentMoney = playerMoney

                -- ��������� ������ ��� ������ ��������� �����
                saveData()

                wait(0)
            end
        end
        wait(0)
    end
end

-- ��������� GUI
function imgui.OnDrawFrame()
    if main_window_state.v then
        imgui.ShowCursor = false
        imgui.Begin('My Salary', windowOpen, imgui.WindowFlags_AlwaysAutoResize)
        imgui.Text(u8'�����: ')
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), formatNumber(earned) .. u8' $') -- �������
        imgui.Text(u8'������: ')
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), formatNumber(spended) .. u8' $') -- �������
        imgui.Text(u8'����: ')
        imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), formatNumber(sessionSalary) .. u8' $') -- �������
        imgui.End()
    end
end

-- ��������/�������� ����
function openWindow()
    main_window_state.v = not main_window_state.v
    imgui.Process = main_window_state.v
end

-- �������������� �����
function formatNumber(n)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return formatted:gsub("^%.", "") -- ������� ������ ����� � ������, ���� ����� < 1000
end