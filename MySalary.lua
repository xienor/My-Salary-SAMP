-- �������������� �������
script_name("My Salary")
script_authors("mihaha")
script_version("0.15.5")

-- ����������� ���������
require 'moonloader'
local imgui = require 'mimgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'
local ffi = require 'ffi'
local wm = require 'windows.message'

-- ���������
encoding.default = 'CP1251'
u8 = encoding.UTF8

--����������
local updateURL = "https://api.github.com/repos/xienor/My-Salary-SAMP/releases"
local updateWindowState = imgui.new.bool(false)
local isJsonLoaded = false
local releasesData = {}

-- ���������� ����������
local playerMoney = 0 -- ������ � ������
local currentMoney = 0 -- ������ ���������� � �������
local earned = 0 -- �������� �����
local spended = 0 -- ��������� �����
local daySalary = 0 -- ����� ����� �� ����
local bankEarn = 0 -- �������� �� ���������� ����
local depEarn = 0 -- �������� �� �������
local bankSpend = 0 -- ��������� �� ����� � �����
local depSpend = 0 -- ��������� � ����������� �����

local lastOperations = {}
local customTypes = {}
local editOperation = 0

local payDayCount = 0 -- ���������� PayDay �� ����
local lastPayDay = 0

local sessionEarn = 0 -- ������
local sessionSpend = 0
local sessSalary = 0

-- �����
local totalOnlineTime = 0 -- ����� ������ �� ����
local startTime = 0
local nowTime = 0
local onlineTime = 0
local afkTime = 0
local timeSecs = 0 -- ������ ������
local timeMins = 0 -- ������ �����
local timeHours = 0 -- ������ �����

-- �������
local statTab = 1

-- ��� ��������� ���������

local chatLog = {}

-- �����
local screenResX = imgui.new.int(1920)
local screenResY = imgui.new.int(1080)

-- ���������
local hidden = imgui.new.bool(false)
local wasCursorActive = false
local new, str, sizeof = imgui.new, ffi.string, ffi.sizeof
local nameInputField = new.char[256]()
local descInputField = new.char[256]()

-- ���������� ������������� �������
local widget_state = imgui.new.bool(true) -- ��������� �������
local main_window_state = imgui.new.bool(false) -- ��������� �������� ����
local log_window_state = imgui.new.bool(false) -- ��������� ���� �����
local types_window_state = imgui.new.bool(false) -- ��������� ���� ���������������� ����� ��������
local edit_window_state = imgui.new.bool(false) -- ��������� ���� ���������������� ����� ��������-------------------------------------------------
local local_checkbox_state = imgui.new.bool(false)
local edit_mode = imgui.new.bool(false) -- ��������� ���� ���������������� ����� ��������-----------------------------------------------------------------
local widget_position = { x = 1500, y = 190 } -- ������� �������
local widget_size = { width = 200, height = 90 } -- ������ �������
local widget_text_size = imgui.new.int(14) -- ������ ������
local widget_stat_mode = imgui.new.bool(true) -- ����� ������ ������� (0 - ������, 1 - ����)
local hideWidgetWhenCursor = imgui.new.bool(false)
local widgetAlpha = imgui.new.float(1.0)

-- ���������
local settings = {
	hideWidgetWhenCursor = imgui.new.bool(false),
    widget_visible = imgui.new.bool(true), -- ��������� �������
    widget_position = { x = imgui.new.int(1500), y = imgui.new.int(190) }, -- ������� �������
    widget_size = { width = imgui.new.int(200), height = imgui.new.int(90) }, -- ������ �������
    widget_text_size = imgui.new.int(14), -- ������ ������
    widget_stat_mode = imgui.new.bool(true), -- ����� ������ ������� (0 - ������, 1 - ����)
	widgetAlpha = imgui.new.float(1.0)
}

local moneyEvents = {
	{chatString="emptyemptyemptyempty",event=" "},
	{chatString="�� ������� �������� ������������ ����� �� ������������ ������", event="������ ������������ �����"},
	{chatString="�� ������� �������� ������������ ����� �� ������", event="������ ������� �� ������"},
	{chatString="�� ������� �������� ������ ������ ������ � �����", event="������ �����"},
	{chatString="�� ������� ������� �����", event="������� ����� � ������"},
	{chatString="��������� ���� ���� �� ��������������", event="������ ��������������"},
	{chatString="�� �������� ��� ������ �� �����", event="������ ���� �������"},
	{chatString="������� �� ������� ��������", event="������ �� �������"},
	{chatString="��� ������� �����", event="������ �� �������"},
	{chatString="�� ������� ��������", event="������ ��������"},
	{chatString="�� �������� ������� �� ���������� �������", event="������� �� �������"},
	{chatString="�� ������ ������� (.+) �� �����������������", event="��������� �� �����������������"},
	{chatString="���� ����������� �� ������ ����� �� ����", event="������� �� �����������������"},
	{chatString="�� ������� ������", event="������� ��������"},
	{chatString="�� ������� �������", event="������� ��������"},
	{chatString="� ��������� �� ������ �� �������", event="�������� � �������"},
	{chatString="�� ������� �������� (.+) �� (.+) AZ Coins", event="������� AZ �� ��"},
	{chatString="�� ��������� ������� �����", event="������� ����������� ������"},
	{chatString="�� �������� ��������� ����", event="��������� ������ �� ��"},
	{chatString="�� ����� �� ������ ����������� �����", event="������ ����� � ����������� �����"},
	{chatString="�� �������� �� ���� ���������� ����", event="������� �� ���������� ����"},
	{chatString="�� �������� �� ���� ���������� ����", event="������� �� ���������� ����"},
	{chatString="�� ����� ������ � ����������� �����", event="������ ����� � ����������� �����"},
	{chatString="�� �������� (.+) ������ (.+) �� ����", event="������� � ����������� �����"},
	{chatString="��� ��� �������� ������� '����'", event="������� ����"}, -- ���������, ������������� ��� ��������� �� ������
	{chatString="�� ��������� ����� (.+) �� (.+) BTC", event="������� BTC"},
	{chatString="�� ��������� ����� (.+) BTC �� (.+)", event="������� BTC"},
	{chatString="�� ��������� ����� (.+) ASC �� (.+)", event="������� ASC"},
	{chatString="�� ��������� ����� (.+) �� (.+) ASC", event="������� ASC"},
	{chatString="�� ��������� �������� �����, ��� ���������� ���", event="����� ���� /findi"},
	{chatString="�� ��������� �������� �����, ��� ���������� ������", event="����� ������� /findi"},
	{chatString="��������� ���������� ����� ����� �� ���������", event="�������� �� ������"},
	{chatString="�������� ������� �����", event="������� �� ����������"},
	{chatString="�� ������� ����������", event="������� � ������"},
	{chatString="�� �������� (.+)!", event="��������� ����� �� �������"},
	{chatString="��� ���������", event="��������� ����� �� ������"},
	{chatString="������ �������:", event="�������� ��������"},
	{chatString="�� ������� ������������ ����������� � �������� ��������", event="������� NPC"},
	{chatString="�� �������� (.+) �� ���� � �������������", event="����������� �������� ������������"},
	{chatString="�������� 100 ������������ �� ����� ��������", event="�������� ������������"},
	{chatString="�������� ��� ���� ��������� ��������", event="����� ��������� � ���"},
	{chatString="�� ������� �������� (.+) ��������� ���", event="����� ��������� � ������"},
	{chatString="��� ��� �������� ������� '������� ������'", event="������� ��� �������"},
	{chatString="�� �������� �� �����", event="�������� �� �����"},
	{chatString="�� ������� ������� �� ������", event="����� �� ������"},
	{chatString="�� ������� ������� ������ �� ���������", event="������ �� ���������"},
	{chatString="��� ��� �������� ������� '����� ��� ������'", event="������� �����"},
	{chatString="��� ���� ����. � ���", event="��������� ������� � ������ ������"},
	{chatString="�� ������� ���������� ��� ��", event="������ ����������"},
	{chatString="�� ������������ (.+) �� �������� �����!", event="�������������"},
	{chatString="�� ������ (.+) ������������ ��", event="������� ������"},
	{chatString="������� �������� ��������", event="�������� ��"},
	{chatString="�� �������� (.+) ��������� �� ���������", event="������ ��"},
	{chatString="������ �� �������� ���������� ���������", event="�������� ��"},
	{chatString="�� ������� ��������� ������ �� ��������� ����", event="������ � ������������ �������"},
	{chatString="�� ������ ��������� �� ����������� ���������", event="����������� ���������"},
	{chatString="����� �������� � �������", event="������ ��"},
	{chatString="�� ������ ����������� ������", event="������� ����������� �����"},
	{chatString="�� ���������� ���������", event="������ ����������"},
	{chatString="����� � ��� (.+) �� ��������", event="������� ��������"},
	{chatString="�� ������� ��������� ����� �� �����", event="������� ������ � ����"},
	{chatString="�� ������� ��������� (.+) VC-�������� ��", event="������� VC"},
	{chatString="�� ������� �������� (.+) VC-�������� ��", event="������� VC"},
	{chatString="�� ����� ���������� �� ������ ��������", event="������� ���������� �� ������ ��������"},
	{chatString="�� ��������� (.+) ����� ��", event="������� ����� �� �����"},
	{chatString="�������! ������� ���� ����. ������������� �������� ���!", event="������� ��������� �� �����"},
	{chatString="����� ����, ��� ����?", event="���� � �������"},
	{chatString="(.+) ��������� ��������� (.+)", event="�������� ����������"},
	{chatString="������� �����! ����� ���� ������!", event="������� �������� �����"},
	{chatString="����� ������ �������� ����������, ��������� � �������������!", event="������� ����������� � �����"},
	{chatString="��������� �������� ������� �������������!", event="������ �����������"}
}

-- ���� � JSON-�����
local path = getWorkingDirectory() .. "\\config\\MySalary[Data].json"

-- ��������� ������
local data = {
    salary = {}, -- ������� �������
    settings = {
		hideWidgetWhenCursor = false,
        widget_visible = true,
        widget_position = { x = 1500, y = 190 },
        widget_size = { width = 200, height = 90 },
        widget_text_size = 14,
        widget_stat_mode = true,
		widgetAlpha = 1.0
    },
    update_date = "", -- ��������� ���� ����������
	savedTypes = {}
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

-- �������� ������
function loadData()
    local currentDate = getCurrentDate()
    if data.salary[currentDate] then
        earned = data.salary[currentDate].earned or 0
        spended = data.salary[currentDate].spended or 0
        daySalary = data.salary[currentDate].daySalary or 0
        totalOnlineTime = data.salary[currentDate].totalOnlineTime or 0
        payDayCount = data.salary[currentDate].payDayCount or 0
		bankEarn = data.salary[currentDate].bankEarn or 0
		depEarn = data.salary[currentDate].depEarn or 0
		bankSpend = data.salary[currentDate].bankSpend or 0
		depSpend = data.salary[currentDate].depSpend or 0
		lastOperations = data.salary[currentDate].log or {}
		customTypes = data.savedTypes or {}
    else
        earned = 0
        spended = 0
        daySalary = 0
        totalOnlineTime = 0
        payDayCount = 0
		bankEarn = 0 
		depEarn = 0
		bankSpend = 0
		depSpend = 0
		lastOperations = {}
		customTypes = data.savedTypes or {}
    end

    -- �������� ��������
    if data and data.settings then
        settings.widget_visible = imgui.new.bool(data.settings.widget_visible or true) 
        settings.widget_stat_mode =  imgui.new.bool(data.settings.widget_stat_mode or true) 
		settings.hideWidgetWhenCursor = imgui.new.bool(data.settings.hideWidgetWhenCursor or false)
		settings.widgetAlpha = imgui.new.float(data.settings.widgetAlpha or 1.0) 
		
        settings.widget_position = {
            x = imgui.new.int(data.settings.widget_position.x or 1500),
            y = imgui.new.int(data.settings.widget_position.y or 190)
        }
		
        settings.widget_size = {
            width = imgui.new.int(data.settings.widget_size.width or 200),
            height = imgui.new.int(data.settings.widget_size.height or 90)
        }
        settings.widget_text_size = imgui.new.int(data.settings.widget_text_size or 10)
        widget_state[0] = settings.widget_visible[0]
        widget_stat_mode[0]= settings.widget_stat_mode[0]
		hideWidgetWhenCursor[0] = settings.hideWidgetWhenCursor[0]
    end
end

-- ���������� ������
function saveData()
    local currentDate = getCurrentDate()
	if data.salary[currentDate] then
		data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        daySalary = daySalary,
		payDayCount = payDayCount,
		totalOnlineTime = totalOnlineTime,
		bankEarn = bankEarn,
		depEarn = depEarn,
		bankSpend = bankSpend,
		depSpend = depSpend,
		log = lastOperations or {}
		}
		data.update_date = currentDate
		data.savedTypes = customTypes or {}
	else
		earned = 0
		spended = 0
		daySalary = 0
		totalOnlineTime = 0
		payDayCount = 0
		bankEarn = 0
		depEarn = 0
		bankSpend = 0
		depSpend = 0
		lastOperations = {}
		data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        daySalary = daySalary,
		payDayCount = payDayCount,
		bankEarn = bankEarn,
		depEarn = depEarn,
		bankSpend = bankSpend,
		depSpend = depSpend,
		totalOnlineTime = totalOnlineTime,
		log = {}
		}
		data.update_date = currentDate
		data.savedTypes = customTypes or {}
	end

    -- ���������� ��������
    data.settings = {
        widget_visible = settings.widget_visible[0],
        widget_stat_mode = settings.widget_stat_mode[0],
		hideWidgetWhenCursor = settings.hideWidgetWhenCursor[0],
		widgetAlpha = settings.widgetAlpha[0],
        widget_position = {
            x = settings.widget_position.x[0],
            y = settings.widget_position.y[0]
        },
        widget_size = {
            width = settings.widget_size.width[0],
            height = settings.widget_size.height[0]
        },
        widget_text_size = settings.widget_text_size[0]
    }

    local file = io.open(path, "w")
    file:write(encodeJson(data))
    file:close()
end

-- �������� �������
function main()
    while not isSampAvailable() do wait(0) end
	wait(1000)
    sampRegisterChatCommand("msalary", openMainWindow)
	sampRegisterChatCommand("mslog", openChatLog)
	setScreenResolution()
    loadData()
	wait(1000)
	startTime = os.time()
	calcOnline()

    widget_state[0]= settings.widget_visible[0]-- ������������� ��������� �������
    widget_stat_mode[0]= settings.widget_stat_mode[0]
	
	while true do
        if sampIsLocalPlayerSpawned() then
			sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ �����������. ����, ���������: {3d85c6} /msalary", 0xFFFFFF)
			wait(1000)
            currentMoney = getPlayerMoney(Player)
			wait(1000)
            while true do
				if sampIsLocalPlayerSpawned() then -- ������ �� ������� (�� ��������� �������� � ������ ����������)
					playerMoney = getPlayerMoney(Player)
					if currentMoney < playerMoney then
						opEarn = playerMoney - currentMoney
						earned = earned + opEarn
						sessionEarn = sessionEarn + (playerMoney - currentMoney)
						local operationTime = os.time()
						createLog(operationTime, opEarn, "+")
					elseif currentMoney > playerMoney then
						opSpend = currentMoney - playerMoney
						spended = spended - opSpend
						sessionSpend = sessionSpend - (currentMoney - playerMoney)
						local operationTime = os.time()
						createLog(operationTime, opSpend, "-")
						
					end
					daySalary = earned + spended
					sessSalary = sessionEarn + sessionSpend
					currentMoney = playerMoney
					if hideWidgetWhenCursor[0] == true then
						local isCursorActive = sampIsCursorActive()
						if isCursorActive ~= wasCursorActive then
							wasCursorActive = isCursorActive -- ��������� ���������� ���������
						if isCursorActive then
							widget_state[0] = false
							hidden =  new.bool(true)
						else
							widget_state[0] = hidden[0]
							hidden = new.bool(false)
						end
					end
					end
				end
                countPayDay() -- �������� PayDay
                saveData() -- ���������� ������ ��� ������ ��������� �����
				calcOnline()
                wait(0)
            end
        end
        wait(0)
    end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 14.0, nil, glyph_ranges)
    fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', settings.widget_text_size[0], _, glyph_ranges)
end
)

-- ��������� GUI
local widget = imgui.OnFrame(
	function() return widget_state[0] end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(settings.widget_position.x[0], settings.widget_position.y[0]), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(settings.widget_size.width[0], settings.widget_size.height[0]), imgui.Cond.Always)
		imgui.SetNextWindowBgAlpha(settings.widgetAlpha[0])
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1, 1, 1, 0))
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, settings.widgetAlpha[0]))
		imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1, 1, 1, settings.widgetAlpha[0]))
		imgui.Begin(u8'My Salary: ������', widget_state, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
		player.HideCursor = true
        if settings.widget_stat_mode[0] then
            imgui.Text(u8'������: ' .. formatTime(0, 0))

            imgui.Separator()

            imgui.PushFont(fontsize)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 60)

            imgui.Text(u8'�����: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, settings.widgetAlpha[0]), formatNumber(earned) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Text(u8'������: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0, 0, settings.widgetAlpha[0]), formatNumber(spended) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Separator()

            imgui.Text(u8'����: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0.84, 0, settings.widgetAlpha[0]), formatNumber(daySalary) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Columns(1)
            imgui.PopFont()
        else
            imgui.Text(u8'������(������): ' .. formatTime(2, 0))

            imgui.Separator()

            imgui.PushFont(fontsize)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 60)

            imgui.Text(u8'�����: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, settings.widgetAlpha[0]), formatNumber(sessionEarn) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Text(u8'������: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0, 0, settings.widgetAlpha[0]), formatNumber(sessionSpend) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Separator()

            imgui.Text(u8'����: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0.84, 0, settings.widgetAlpha[0]), formatNumber(sessSalary) .. u8' $') -- �������
            imgui.NextColumn()

            imgui.Columns(1)
            imgui.PopFont()
        end
		imgui.PopStyleColor() -- �����
		imgui.PopStyleColor() -- �����
		imgui.PopStyleColor() -- �����������
        imgui.End()
    end
)

local mainWindow = imgui.OnFrame(
	function() return main_window_state[0] end,
	function(player)
		imgui.SetNextWindowSize(imgui.ImVec2(650, 450), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'My Salary: ������� ����', main_window_state, imgui.WindowFlags.NoCollapse)
		player.HideCursor = false
		
		statsChildWidth = imgui.new.float(imgui.GetWindowWidth() * 0.45)
		
		if imgui.BeginTabBar('Tabs') then 
			if imgui.BeginTabItem(u8'�������') then -- -----------------------------------�������---------------------------

            imgui.Text(u8'����� ����������: ')
            if imgui.Button(u8'��� ������') then
                statTab = 1
            end

            imgui.SameLine()

            if imgui.Button(u8'������') then
                statTab = 2
            end

            imgui.SameLine()

            if imgui.Button(u8'�����') then
                statTab = 3
            end

            imgui.Separator()

            if statTab == 1 then
				if imgui.BeginChild('Cash', imgui.ImVec2(statsChildWidth[0], 130), true) then
					if widget_stat_mode[0] == false then
						imgui.Text(u8'������ �� ������: ' .. formatTime(2, 0))
						imgui.Text(u8'����� �� ������: ' .. formatNumber(sessionEarn) .. '$')
						imgui.Text(u8'������ �� ������: ' .. formatNumber(sessionSpend) .. '$')
						imgui.Text(u8'����� �� ������: ' .. formatNumber(sessSalary) .. '$')
					else
						imgui.Text(u8'������ �� �������: ' .. formatTime(0, 0))
						imgui.Text(u8'����� �� �������: ' .. formatNumber(earned) .. '$')
						imgui.Text(u8'������ �� �������: ' .. formatNumber(spended) .. '$')
						imgui.Text(u8'����� �� �������: ' .. formatNumber(daySalary) .. ' $')
					end
					imgui.EndChild() 
				end
				imgui.SameLine()
				if imgui.BeginChild('Bank', imgui.ImVec2(statsChildWidth[0], 130), true) then
					imgui.Text(u8'���������� ����� �� �������: ' .. formatNumber(bankEarn) .. ' $')
					imgui.Text(u8'�������� � ����� �� �������: ' .. formatNumber(bankSpend) .. '$')
					imgui.Text(u8'���������� �������� �� �������: ' .. formatNumber(depEarn) .. ' $')
					imgui.Text(u8'�������� � �������� �� �������: ' .. formatNumber(depSpend) .. '$')
					itogBank = (bankEarn - bankSpend) + (depEarn - depSpend)
					imgui.Text(u8'����� � ����� �� �������: ' .. formatNumber(itogBank) .. '$')
					imgui.Text(u8'PayDay �������� �� �������: ' .. payDayCount)
					imgui.EndChild() 
				end

				imgui.Text(u8'����� �� �������: ' .. formatNumber(daySalary + itogBank) .. '$')
				
				imgui.Separator()

				if imgui.Button(u8'�������� ���������� �� ������') then
					sessionEarn = 0
					sessionSpend = 0
					sessSalary = 0
				end
				imgui.SameLine()
				if imgui.Button(u8'�������� ���������� �� �������') then
					currentDate = getCurrentDate()
					earned = 0
					spended = 0
					daySalary = 0
					totalOnlineTime = 0
					payDayCount = 0
					depEarn = 0
					depSpend = 0
					bankEarn = 0
					bankSpend = 0
					data.salary[currentDate].log = {}
					lastOperations = {}
					saveData()
					loadData()
					
				end
            end


            if statTab == 2 then
                local stats = getWeekStats()
				if imgui.BeginChild('Cash', imgui.ImVec2(statsChildWidth[0], 130), true) then
					imgui.Text(u8'������ �� ������: ' .. formatTime(1, stats.weekOnline))
					imgui.Text(u8'����� �� ������: ' .. formatNumber(stats.weekEarned) .. '$')
					imgui.Text(u8'������ �� ������: ' .. formatNumber(stats.weekSpended) .. '$')
					imgui.Text(u8'����� �� ������: ' .. formatNumber(stats.weekSalary) .. '$')
					imgui.EndChild()
				end
				imgui.SameLine()
				if imgui.BeginChild('Bank', imgui.ImVec2(statsChildWidth[0], 130), true) then
					imgui.Text(u8'���������� ����� �� ������: ' .. formatNumber(stats.weekBankEarn) .. ' $')
					imgui.Text(u8'�������� � ����� �� ������: ' .. formatNumber(stats.weekBankSpend) .. '$')
					imgui.Text(u8'���������� �������� �� ������: ' .. formatNumber(stats.weekDepEarn) .. ' $')
					imgui.Text(u8'�������� � �������� �� ������: ' .. formatNumber(stats.weekDepSpend) .. '$')
					itogBank = (stats.weekBankEarn - stats.weekBankSpend) + (stats.weekDepEarn + stats.weekDepSpend)
					imgui.Text(u8'����� � ����� �� ������: ' .. formatNumber(itogBank) .. '$')
					imgui.Text(u8'PayDay �� ������: ' .. stats.weekPayDay)
					imgui.EndChild()
				end
				imgui.Text(u8'����� �� ������: ' .. formatNumber(stats.weekSalary + itogBank) .. '$')
            end

            if statTab == 3 then
                local stats = getMonthStats()
				if imgui.BeginChild('Cash', imgui.ImVec2(statsChildWidth[0], 130), true) then
					imgui.Text(u8'������ �� �����: ' .. formatTime(1, stats.monthOnline))
					imgui.Text(u8'����� �� �����: ' .. formatNumber(stats.monthEarned) .. '$')
					imgui.Text(u8'������ �� �����: ' .. formatNumber(stats.monthSpended) .. '$')
					imgui.Text(u8'����� �� �����: ' .. formatNumber(stats.monthSalary) .. '$')
					imgui.EndChild()
				end
				imgui.SameLine()
				if imgui.BeginChild('Bank', imgui.ImVec2(statsChildWidth[0], 130), true) then
					imgui.Text(u8'���������� ����� �� �����: ' .. formatNumber(stats.monthBankEarn) .. '$')
					imgui.Text(u8'�������� � ����� �� �����: ' .. formatNumber(stats.monthBankSpend) .. '$')
					imgui.Text(u8'���������� �������� �� �����: ' .. formatNumber(stats.monthDepEarn) .. '$')
					imgui.Text(u8'�������� � �������� �� �����: ' .. formatNumber(stats.monthDepSpend) .. '$')
					itogBank = (stats.monthBankEarn - stats.monthBankSpend) + (stats.monthDepEarn - stats.monthDepSpend)
					imgui.Text(u8'����� � ����� �� �����: ' .. formatNumber(itogBank) .. '$')
					imgui.Text(u8'PayDay �� �����: ' .. stats.monthPayDay)
					imgui.EndChild()
				end
				imgui.Text(u8'����� �� �����: ' .. formatNumber(stats.monthSalary + itogBank) .. '$')
            end
			
				imgui.EndTabItem() -- -----------------------------------������� (�����)---------------------------
			end
			if imgui.BeginTabItem(u8'�������') then -- -----------------------------------�������---------------------------
				imgui.Text(u8'���� � �����: ' .. os.date("%d.%m.%Y") .. ', ' .. os.date("%X", os.time()))
				imgui.SameLine()
				if imgui.Checkbox(u8'�������������', edit_mode) then

				end
				
				imgui.Separator()
				
				if next(data.salary) == nil then
					imgui.Text(u8"��� ������ ��� �����������")
				else
					-- �������� � ��������� ����
					local sortedOps = {}
					for date in pairs(data.salary) do
						table.insert(sortedOps, date)
					end
					table.sort(sortedOps, function(a, b) return a > b end)

					-- ���������� ����
					for _, date in ipairs(sortedOps) do
						local todayOps = data.salary[date].log
						local stats = data.salary[date]
						
						if stats then
							if imgui.CollapsingHeader(u8(date)) then
								imgui.Text(u8'���������� �� ����:')
								imgui.Separator()
								imgui.Columns(2)
								imgui.Text(u8'������ �� ����: ')
								imgui.NextColumn()
								imgui.Text(formatTime(1, (stats.totalOnlineTime) or 0))
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'PayDay �� ����: ')
								imgui.NextColumn()
								imgui.Text(string.format((stats.payDayCount) or 0))
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'�����: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.earned) or 0) .. u8' $')
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'������: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.spended) or 0) .. u8' $')
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'���������� ����� � �����: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.bankEarn) or 0) .. u8' $')
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'�������� �� ����� � �����: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.bankSpend) or 0) .. u8' $')
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'����� �� �������� �� ��������: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.depEarn) or 0) .. u8' $')
								imgui.Separator()
								imgui.NextColumn()
								imgui.Text(u8'�������� � ��������: ')
								imgui.NextColumn()
								imgui.Text(formatNumber((stats.depSpend) or 0) .. u8' $')
								imgui.Separator()
								imgui.Columns(1)
								imgui.NewLine()
								imgui.Text(u8'����: ' .. formatNumber((stats.daySalary or 0) + (stats.bankEarn or 0) - (stats.bankSpend or 0) + (stats.depEarn or 0) - (stats.depSpend or 0)) .. u8' $')
								
								if date ~= os.date("%Y-%m-%d") then
									if imgui.Button(u8'������� ����') then
										data.salary[date] = nil
										saveData()
									end
								end
								
								imgui.NewLine()
								imgui.Text(u8'��������������� �������� �� ����:')
									
								if todayOps and next(todayOps) then
									
									imgui.Separator()

									local sortedOperations = {}
									
									-- ��������� ������ ��������
									for operationTime, operation in pairs(todayOps) do
										table.insert(sortedOperations, { time = operationTime, data = operation })
									end

									-- ��������� �������� �� �������
									table.sort(sortedOperations, function(a, b) return a.time < b.time end)

									-- ������� ��������
									for _, op in ipairs(sortedOperations) do
										local operation = op.data
										local op_id = date .. "_" .. op.time
										
										if edit_mode[0] then
											-- ����� ��������������
											imgui.Text(op.time .. ': ' .. operation.sym .. formatNumber(operation.summ) .. " $ ")
											imgui.SameLine()
											
											-- ���������� ������ �����
											local allTypes = {}
											local originalTypes = {} -- ��������� ������������ ��������
											
											-- ��������� moneyEvents
											for _, t in ipairs(moneyEvents) do
												table.insert(allTypes, u8(t.event))
												table.insert(originalTypes, t.event)
											end
											
											-- ��������� customTypes
											if customTypes and next(customTypes) ~= nil then
												for _, t in ipairs(customTypes) do
													table.insert(allTypes, u8(t.event))
													table.insert(originalTypes, t.event)
												end
											end
											
											-- ������� ������� ������
											local currentIndex = 0
											local currentType = operation.type or "�������� �� ����������"
											for i, typeName in ipairs(originalTypes) do
												if typeName == currentType then
													currentIndex = i - 1
													break
												end
											end
											
											-- ComboBox
											local currentIndexPtr = imgui.new.int(currentIndex)
											local comboName = "##type_" .. date .. "_" .. op.time
											local imguiTypes = imgui.new['const char*'][#allTypes](allTypes)
											
											if imgui.Combo(comboName, currentIndexPtr, imguiTypes, #allTypes) then
												local selectedIndex = currentIndexPtr[0] + 1
												if selectedIndex >= 1 and selectedIndex <= #originalTypes then
													operation.type = originalTypes[selectedIndex]
												else
													operation.type = "�������� �� ����������"
												end
												saveData()
											end
										else
											-- ������� ����� �����������
											local color
											local opType = operation.type or "�������� �� ����������"
											if operation.sym == "+" and opType ~= "�������� �� ����������" then
												color = imgui.ImVec4(0, 1, 0, settings.widgetAlpha[0])
											elseif operation.sym == "-" and opType ~= "�������� �� ����������" then
												color = imgui.ImVec4(1, 0, 0, settings.widgetAlpha[0])
											else
												color = imgui.ImVec4(0.5, 0.5, 0.5, settings.widgetAlpha[0])
											end
											imgui.TextColored(color, op.time .. ': ' .. u8(operation.sym .. formatNumber(operation.summ) .. " $" .. " " .. opType))
										end
									end
								else
									imgui.Text(u8"��� �������� �� ���� ����")
								end
							end
						end
					end
				end
				imgui.EndTabItem() -- ----------------------------------- ������� (�����)---------------------------
			end
			
			if imgui.BeginTabItem(u8'���������') then -- -----------------------------------���������---------------------------
				imgui.Text(u8'��������� �������:')
				imgui.SameLine()
				if imgui.Checkbox(u8"��������", settings.widget_visible) then
					widget_state[0] = settings.widget_visible[0]
					data.settings.widget_visible = settings.widget_visible[0]
					saveData()
				end

				imgui.Text(u8'����� ������� (��� - ����, ���� - ������): ')
				imgui.SameLine()
				if imgui.Checkbox(u8"����", settings.widget_stat_mode) then
					widget_stat_mode[0] = settings.widget_stat_mode[0]
					data.settings.widget_stat_mode = settings.widget_stat_mode[0]
					saveData()
				end
				imgui.Text(u8'�������� ������ ��� �������� ������� (���������, ���...)')
				imgui.SameLine()
				if imgui.Checkbox(u8"��������", settings.hideWidgetWhenCursor) then
					hideWidgetWhenCursor[0] = settings.hideWidgetWhenCursor[0]
					data.settings.hideWidgetWhenCursor = settings.hideWidgetWhenCursor[0]
					saveData()
				end

				imgui.Separator()
				
				if imgui.Button(u8'��������� ������������ ���������') then
					types_window_state[0] = not types_window_state[0]
				end
				
				imgui.Separator()

				imgui.Text(u8'������� �������:')
				imgui.SliderInt("X", settings.widget_position.x, 0, screenResX[0] - widget_size.width)
				imgui.SliderInt("Y", settings.widget_position.y, 0, screenResY[0] - widget_size.height)

				imgui.Separator()

				imgui.Text(u8'������ �������:')
				imgui.SliderInt(u8"������", settings.widget_size.width, 100, 500)
				imgui.SliderInt(u8"������", settings.widget_size.height, 50, 300)

				imgui.Separator()

				imgui.Text(u8"������������ �������: ")
				imgui.SliderFloat(u8"0-1", settings.widgetAlpha, 0.0, 1.0)
				
				imgui.Separator()

				imgui.Text(u8'������ ������')
				imgui.SliderInt(u8"������", settings.widget_text_size, 5, 20)
				saveData()
				imgui.SameLine()
				if imgui.Button(u8'���������') then
					saveData()
					sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ ����� ������������...", 0xFFFFFF)
					main_window_state[0] = false
					thisScript():reload()
				end

				imgui.Separator()
				
				if imgui.Button(u8"��������� ����������") then
					updateWindowState[0] = not updateWindowState[0]
				end
				
				imgui.Separator()

				if imgui.Button(u8'�������� ��� ����������') then
					earned = 0
					spended = 0
					daySalary = 0
					payDayCount = 0
					totalOnlineTime = 0
					data.salary = {}
					saveData()
				end
				imgui.EndTabItem() -- -----------------------------------��������� (�����)---------------------------
			end
			imgui.EndTabBar() -- ����� ���� �������
		end

        imgui.End()
		if not main_window_state[0] then
		imgui.GetIO().MouseDrawCursor = false
		end
    end
)

local logWindow = imgui.OnFrame(
	function() return log_window_state[0] end,
	function(player)
		imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'My Salary: ������', log_window_state, imgui.WindowFlags.NoCollapse)
		player.HideCursor = false
		
		for _, log in ipairs(chatLog) do
			logButtonText = string.format("[" .. os.date("%H:%M:%S", log.time) .. "]" .. " " .. log.text)
			if imgui.Button(u8(logButtonText)) then
				print(logButtonText)
			end
		end
		
        imgui.End()
		if not log_window_state[0] then
		imgui.GetIO().MouseDrawCursor = false
		end
    end
)

local typesWindow = imgui.OnFrame(
    function() return types_window_state[0] end,
    function(player)
        imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'My Salary: ������������ ���������', types_window_state, imgui.WindowFlags.NoCollapse)
        player.HideCursor = false
        
        -- ��������� ��������� ��� ��������
        

        if imgui.CollapsingHeader(u8'����������') then
            imgui.Text(u8'� ���� ������� �� ������ ������ ���� ���� ��������� ��� ����������.')
            imgui.Text(u8'��� ���������� ����� ��������� ����� ��������� 2 ���� � ������ ������ - �������')
            imgui.Text(u8'� ���� �������� - ������� �� ��� �� ������ ����� �������� ������������.')
            imgui.Text(u8'� ���� �������� - ������� ������ ������� ��������� � ��� ����� ��������� ���������� ��������.')
            imgui.Text(u8'�� ������� ����� ������� ��� $ [ ]')
            imgui.Text(u8'����� ����� �� ��� �� ����� � ���� �������� ���������� �� ���������� ������ ��������.')
            imgui.Text(u8'�������� �������� ����� �� �����, ����� ����� ������� ��� �������� � �����: � ������ ���� � � �� �.')
        end
        
        if imgui.InputText(u8"��������", nameInputField, sizeof(descInputField)) then
        end
            
        -- ���������� ���� �������� ������ ���� ������� ���������
        if not local_checkbox_state[0] then
            if imgui.InputText(u8"��������", descInputField, sizeof(descInputField)) then
            end
        end
            
        if imgui.Button(u8'��������') then
            local descSrt = u8:decode(ffi.string(nameInputField))
            -- ���������� ������������� �������� ���� ������� �������
            local nameStr = local_checkbox_state[0] and "locallocallocallocal" or u8:decode(ffi.string(descInputField))
            
            table.insert(customTypes, {
                chatString = nameStr,
                event = descSrt
            })
            ffi.fill(nameInputField, sizeof(nameInputField), 0)
            ffi.fill(descInputField, sizeof(descInputField), 0)
        end
        
        -- ��������� ������� �� �� �� ����� ��� � ������
        imgui.SameLine()
        imgui.Checkbox(u8"���������", local_checkbox_state)

        imgui.Separator()
        
        if next(customTypes) == nil then
            imgui.Text(u8'�� ������� �� ����� ������������ ���������')
        else
            local indicesToRemove = {}

            for i, type in ipairs(customTypes) do
                imgui.Text(u8(type.event))
                imgui.SameLine()
                imgui.Text(u8(type.chatString))
                imgui.SameLine()
                if imgui.Button(u8'������� ' .. i) then
                    table.insert(indicesToRemove, 1, i)
                end
            end

            for _, i in ipairs(indicesToRemove) do
                table.remove(customTypes, i)
            end

            if #indicesToRemove > 0 then
                saveData()
            end
        end
        
        imgui.End()
        if not types_window_state[0] then
            imgui.GetIO().MouseDrawCursor = false
        end
    end
)

local editWindow = imgui.OnFrame(
	function() return edit_window_state[0] end,
	function(player)
		imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'My Salary: �������������� ��������', edit_window_state, imgui.WindowFlags.NoCollapse)
		player.HideCursor = false
		
		imgui.Text(u8(editOperation))

        imgui.End()
		if not edit_window_state[0] then
		imgui.GetIO().MouseDrawCursor = false
		end
    end
)

-- ��������/�������� ����
function openMainWindow()
    main_window_state[0]= not main_window_state[0]
end

function openChatLog()
    log_window_state[0]= not log_window_state[0]
end

function openTypesWindow()
	types_window_state[0] = not types_window_state[0]
end

-- �������������� �����
function formatNumber(n)
    local sign = n < 0 and "-" or ""
    local formatted = tostring(math.abs(n)):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return sign .. formatted:gsub("^%.", "")
end

-- ������� ��� ��������� ������� ����
function getCurrentDate()
    return os.date("%Y-%m-%d")
end

function calcOnline()
	local oldOnline = onlineTime
	local oldAfk = afkTime
	
	onlineTime = os.time() - startTime
	afkTime = os.clock() - gameClock()
	
	if afkTime < 0 then
		afkTime = 0
		oldAfk = 0
	end
	
	if (totalOnlineTime + (onlineTime - oldOnline) - (afkTime - oldAfk)) > totalOnlineTime then
		totalOnlineTime = totalOnlineTime + (onlineTime - oldOnline) - (afkTime - oldAfk)
	end
	
	curT = os.date("*t")
	if curT.hour == 0 and curT.min == 0 and curT.sec == 0 then
		totalOnlineTime = 0
	end
end

function formatTime(mode, vremya)
	if mode == 0 then
		onlTime = totalOnlineTime
	elseif mode == 1 then
		onlTime = vremya or 0
	else 
		onlTime = gameClock()
	end
	
	local timeHours = math.floor(onlTime / 3600)
    local remaining = onlTime % 3600
    local timeMins = math.floor(remaining / 60)
    local timeSecs = remaining % 60

    return string.format("%02d:%02d:%02d", timeHours, timeMins, timeSecs)
	end

function onReceivePacket(id)
    if id == 32 then
        thisScript():unload()
    end
end

function getWeekStats()
    local currentDate = os.date("*t")
    local stats = {
        weekEarned = 0,
        weekSpended = 0,
        weekSalary = 0,
        weekPayDay = 0,
		weekBankEarn = 0,
		weekDepEarn = 0,
		weekBankSpend = 0,
		weekDepSpend = 0,
		weekOnline = 0
    }

    for i = 0, 6 do
        local date = os.date("%Y-%m-%d", os.time({ year = currentDate.year, month = currentDate.month, day = currentDate.day }) - i * 86400)
        if data.salary[date] then
            stats.weekEarned = stats.weekEarned + (data.salary[date].earned or 0)
            stats.weekSpended = stats.weekSpended + (data.salary[date].spended or 0)
            stats.weekSalary = stats.weekSalary + (data.salary[date].daySalary or 0)
            stats.weekPayDay = stats.weekPayDay + (data.salary[date].payDayCount or 0)
			stats.weekBankEarn = stats.weekBankEarn + (data.salary[date].bankEarn or 0)
			stats.weekDepEarn = stats.weekDepEarn + (data.salary[date].depEarn or 0)
			stats.weekBankSpend = stats.weekBankSpend + (data.salary[date].bankSpend or 0)
			stats.weekDepSpend = stats.weekDepSpend + (data.salary[date].depSpend or 0)
			stats.weekOnline = stats.weekOnline + (data.salary[date].totalOnlineTime or 0)
        end
    end

    return stats
end

function getMonthStats()
    local currentDate = os.date("*t")
    local stats = {
        monthEarned = 0,
        monthSpended = 0,
        monthSalary = 0,
        monthPayDay = 0,
		monthBankEarn = 0,
		monthDepEarn = 0,
		monthBankSpend = 0,
		monthDepSpend = 0,
		monthOnline = 0
    }

    for i = 0, 29 do
        local date = os.date("%Y-%m-%d", os.time({ year = currentDate.year, month = currentDate.month, day = currentDate.day }) - i * 86400)
        if data.salary[date] then
            stats.monthEarned = stats.monthEarned + (data.salary[date].earned or 0)
            stats.monthSpended = stats.monthSpended + (data.salary[date].spended or 0)
            stats.monthSalary = stats.monthSalary + (data.salary[date].daySalary or 0)
            stats.monthPayDay = stats.monthPayDay + (data.salary[date].payDayCount or 0)
			stats.monthBankEarn = stats.monthBankEarn + (data.salary[date].bankEarn or 0)
			stats.monthDepEarn = stats.monthDepEarn + (data.salary[date].depEarn or 0)
			stats.monthBankSpend = stats.monthBankSpend + (data.salary[date].bankSpend or 0)
			stats.monthDepSpend = stats.monthDepSpend + (data.salary[date].depSpend or 0)
			stats.monthOnline = stats.monthOnline + (data.salary[date].totalOnlineTime or 0)
        end
    end

    return stats
end

function countPayDay()
    local currentOsTime = os.date("*t")
    local now = os.time()

    if (currentOsTime.min == 0 or currentOsTime.min == 30) and (now - lastPayDay >= 1800) then
        payDayCount = payDayCount + 1
        lastPayDay = now
		getBankEarnings()
    end
end

function getBankEarnings()
    local currentTime = os.time()
    local timeWindow = 300 -- 5-�������� ���� ������
	
    -- ����� �� ����� � ����������
    for i = #chatLog, 1, -1 do
        local entry = chatLog[i]
        
        if entry.time >= (currentTime - timeWindow) then
            if entry.text:match("���������� ���") then
                for j = i, math.min(i + 10, #chatLog) do
                    local text = chatLog[j].text
                    
                    -- ������� ����� � ������� �� ������
                    if text:find("������� ����� � �����") then
                        local amount_str = text:match("%+%$([%d%.]+)")
                        if amount_str then
                            local cleaned = amount_str:gsub("%D", "")
                            if cleaned ~= "" then
                                bankEarn = bankEarn + tonumber(cleaned) or 0
                                print("[����] ��������:", tonumber(cleaned))
                            end
                        end
                    end
                    
                    -- ������� �������� � ������� �� ������
                    if text:find("������� ����� �� ��������") then
                        local amount_str = text:match("%+%$([%d%.]+)")
                        if amount_str then
                            local cleaned = amount_str:gsub("%D", "")
                            if cleaned ~= "" then
                                depEarn = depEarn + tonumber(cleaned) or 0
                                print("[�������] ��������:", tonumber(cleaned))
                            end
                        end
                    end
                end
                break
            end
        end
    end
    
    -- ���� �� �������, ���� � ��������� ����������
    if bankEarn == 0 or depEarn == 0 then
        for i = #chatLog, math.max(1, #chatLog - 20), -1 do
            local text = chatLog[i].text
            
            if text:find("������� ����� � �����") then
                local amount_str = text:match("%+%$([%d%.]+)")
                if amount_str then
                    bankEarn = bankEarn + tonumber(amount_str:gsub("%D", "")) or 0
                end
            end
            
            if text:find("������� ����� �� ��������") then
                local amount_str = text:match("%+%$([%d%.]+)")
                if amount_str then
                    depEarn = depEarn + tonumber(amount_str:gsub("%D", "")) or 0
                end
            end
        end
    end
    return bankEarn, depEarn
end

local function fetchReleaseData()
    downloadUrlToFile(updateURL, "moonloader\\config\\MySalary[Releases].json", function(_, status)
        if status == require("moonloader").download_status.STATUSEX_ENDDOWNLOAD then
            local file = io.open("moonloader\\config\\MySalary[Releases].json", "r")
            if file then
                releasesData = decodeJson(file:read("*a")) or {}
				local latestRelease = releasesData[1]
				local latestVersion = latestRelease.tag_name
				if compare_versions(thisScript().version, latestVersion) then
					sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}�������� ����� ������! ���������� ����� � ����������.", 0xFFFFFF)
				else
					sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}� ��� ����������� ����� ��������� ������.", 0xFFFFFF)
				end
                file:close()
                isJsonLoaded = true
            else
                print("������: �� ������� ������� MySalary[Releases].json")
            end
        end
    end)
end

fetchReleaseData()

local updateWindow = imgui.OnFrame(
    function() return updateWindowState[0] end,
    function(player)
		imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.FirstUseEver)
		imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.48, 0.16, 0.16, 1.0))
        imgui.Begin(u8'MySalary: ����������', updateWindowState, imgui.WindowFlags.NoCollapse)
        player.HideCursor = false
        -- ���������, ��������� �� ������
		imgui.Text(u8" ������������� ������: " .. thisScript().version)
        if not isJsonLoaded then
            imgui.Text(u8"�������� ����������...")
        else
            for _, release in ipairs(releasesData) do
                if imgui.CollapsingHeader(u8(release.tag_name)) then
                    imgui.Text(u8"������: " .. release.tag_name)
                    imgui.Text(u8"���� �������: " .. release.published_at)
                    imgui.Text(u8"��� ������: " .. release.body)
                    
                    for _, asset in ipairs(release.assets or {}) do
                        if imgui.Button(u8"������� " .. asset.name) then
                            local verUrl = asset.browser_download_url
                            local tempPath = thisScript().path .. ".new"

                            downloadUrlToFile(verUrl, tempPath, function(_, status)
                                if status == require("moonloader").download_status.STATUSEX_ENDDOWNLOAD then
                                    if doesFileExist(tempPath) then
                                        os.remove(thisScript().path)
                                        os.rename(tempPath, thisScript().path)
                                        thisScript():reload()
                                    else
                                        print("������: �� ������� ������� ����...")
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
		imgui.PopStyleColor()
        imgui.End()
    end
)

function compare_versions(v1, v2)
    local function split_version(version)
        local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major), tonumber(minor), tonumber(patch)
    end

    local major1, minor1, patch1 = split_version(v1)
    local major2, minor2, patch2 = split_version(v2)

    if major1 ~= major2 then
        return major1 < major2
    elseif minor1 ~= minor2 then
        return minor1 < minor2
    else
        return patch1 < patch2
    end
end

function setScreenResolution()
	screenResX[0], screenResY[0] = getScreenResolution()
end

function events.onServerMessage(color, text)
    local uncoloredText = string.gsub(text, "{.-}", "")
    table.insert(chatLog, {
        time = os.time(), -- ��������� timestamp ������ ������
        text = uncoloredText
    })
    
    -- ������������ ������ ���� (��������, ��������� 50 ���������)
    if #chatLog > 200 then
        table.remove(chatLog, 1)
    end
end

function createLog(oTime, summ, sym)
    operationType = "�������� �� ����������"
    logString = ""
    for i = #chatLog, 1, -1 do
        local logEntry = chatLog[i]
        -- ���������, ���� �� ��������� �� ����� 5 ������ �����
        if oTime - logEntry.time <= 5 then
            -- ������������� customTypes ��� �������������
            if next(customTypes) == nil then
                customTypes = {
                    {event = "HIDDEN", chatString = "DO NOT DELETE"}
                }
            end
            
            local found = false -- ���� ��� ������������ ���������� ����������
            
            -- ������� ��������� ��� �������� � customTypes
            for _, event in ipairs(customTypes) do
                if string.match(logEntry.text, event.chatString) then
                    operationType = event.event
					logString = logEntry.text
                    found = true
                    break -- ������� �� ����� �� customTypes
                end
            end
            
            -- ���� � customTypes �� �����, ��������� moneyEvents
            if not found then
                for _, event in ipairs(moneyEvents) do
                    if string.match(logEntry.text, event.chatString) then
                        operationType = event.event
						logString = logEntry.text
                        found = true
                        break -- ������� �� ����� �� moneyEvents
                    end
                end
            end
            
            -- ������� HIDDEN, ���� �� ��� ��������
            if customTypes[1] and customTypes[1].event == "HIDDEN" then
                table.remove(customTypes, 1)
            end
            
            -- ���� ����� ����������, ��������� ���� �� chatLog
            if found then
                break
            end
        else
            break -- ���������, ���� ��������� ������� ������
        end
    end
    
	if string.match(logString, "�� ����� �� ������ ����������� �����") then
		amount = clearSumm(logString)
		if amount then
			bankSpend = bankSpend - amount
		end
	end
	
	if string.match(logString, "�� �������� �� ���� ���������� ����") then
		amount = clearSumm(logString)
			if amount then
				bankEarn = bankEarn + amount
			end
	end
	
	if string.match(logString, "�� �������� �� ���� ���������� ����") then
		amount = clearSumm(logString)
			if amount then
				depEarn = depEarn + amount
			end
	end
	
	if string.match(logString, "�� ����� ������ � ����������� �����") then
		amount = clearSumm(logString)
			if amount then
				depSpend = depSpend - amount
			end
	end
	
	
    lastOperations[os.date("%H:%M:%S", oTime)] = {
        sym = sym,
        summ = summ,
        type = operationType
    }
end

function clearSumm(logString)
	local amount_str = logString:match("%$([%d%.]+)")
	if amount_str then
		-- ������� ��� ��-����� (������� �����, ������� � ������ �������)
		local cleaned_amount = amount_str:gsub("[^%d]", "")
		-- ����������� � ����� (��� �������� ������� ���������)
		amount = tonumber(cleaned_amount)
		return amount
	end
end

