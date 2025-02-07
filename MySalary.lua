--�������������� �������
script_name("My Salary")
script_authors("mihaha")
script_version("0.10.2")

--����������� ���������
require 'moonloader'
local imgui = require 'imgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'

--���������
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ���������� ����������
local lastOperations = {}
local playerMoney = 0 -- ������ � ������
local currentMoney = 0 -- ������ ���������� � �������
local earned = 0 -- �������� �����
local spended = 0 -- ��������� �����
local daySalary = 0 --����� ����� �� ����

local sessionEarn = 0
local sessionSpend = 0
local sessSalary = 0

local totalOnlineTime = 0 -- ����� ������ �� �����
local timeSecs = 0 -- ������ ������
local timeMins = 0 -- ������ �����
local timeHours = 0 -- ������ �����

local tabN = 1
local statTab = 1

-- ���������� ������������� �������
local widget_state = imgui.ImBool(true) -- ��������� �������
local main_window_state = imgui.ImBool(false) -- ��������� �������� ����
local widget_position = { x = 1500, y = 190 } -- ������� �������
local widget_size = { width = 200, height = 90 } -- ������ �������
local widget_text_size = imgui.ImInt(14) -- ������ ������
local widget_stat_mode = imgui.ImBool(true) -- ����� ������ ������� (0 - ������, 1 - ����)

-- ���������
local settings = {
    widget_visible = imgui.ImBool(true), -- ��������� �������
    widget_position = { x = imgui.ImInt(1500), y = imgui.ImInt(190) }, -- ������� �������
    widget_size = { width = imgui.ImInt(200), height = imgui.ImInt(90) }, -- ������ �������
	widget_text_size = imgui.ImInt(14), -- ������ ������
	widget_stat_mode = imgui.ImBool(true) -- ����� ������ ������� (0 - ������, 1 - ����)
}

-- ���� � JSON-�����
local path = getWorkingDirectory() .. "\\config\\MySalary[Data].json"

-- ��������� ������
local data = {
    salary = {}, -- ������� �������
    settings = {
        widget_visible = true,
        widget_position = { x = 1500, y = 190 },
        widget_size = { width = 200, height = 90 },
		widget_text_size = 14,
		widget_stat_mode = true
    },
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

-- �������� ������
function loadData()
    local currentDate = getCurrentDate()
    if data.salary[currentDate] then
        earned = data.salary[currentDate].earned or 0
        spended = data.salary[currentDate].spended or 0
        daySalary = data.salary[currentDate].daySalary or 0
		totalOnlineTime = data.salary[currentDate].totalOnlineTime or 0
    else
        earned = 0
        spended = 0
        daySalary = 0
		totalOnlineTime = 0
    end

    -- �������� ��������
    if data and data.settings then
        settings.widget_visible = imgui.ImBool(data.settings.widget_visible)
		settings.widget_stat_mode = imgui.ImBool(data.settings.widget_stat_mode)
        settings.widget_position = {
            x = imgui.ImInt(data.settings.widget_position.x or 1500),
            y = imgui.ImInt(data.settings.widget_position.y or 190)
        }
        settings.widget_size = {
            width = imgui.ImInt(data.settings.widget_size.width or 200),
            height = imgui.ImInt(data.settings.widget_size.height or 90)
        }
		settings.widget_text_size = imgui.ImInt(data.settings.widget_text_size or 10)
		widget_state.v = settings.widget_visible.v
		widget_stat_mode�� = settings.widget_stat_mode.v
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
		totalOnlineTime = totalOnlineTime + gameClock()
    }
    data.update_date = currentDate
	else
		earned = 0
		spended = 0
		daySalary = 0
		data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        daySalary = daySalary,
		totalOnlineTime = totalOnlineTime + gameClock()
    }
    data.update_date = currentDate
	end
    

    -- ���������� ��������
    data.settings = {
        widget_visible = settings.widget_visible.v,
		widget_stat_mode = settings.widget_stat_mode.v,
        widget_position = {
            x = settings.widget_position.x.v,
            y = settings.widget_position.y.v
        },
        widget_size = {
            width = settings.widget_size.width.v,
            height = settings.widget_size.height.v
		},
		widget_text_size = settings.widget_text_size.v
	}
    local file = io.open(path, "w")
    file:write(encodeJson(data))
    file:close()
end

-- �������� �������
function main()
	while not isSampAvailable() do wait(0) end
    sampRegisterChatCommand("msalary", openMainWindow)
    loadData()
	
    widget_state.v = settings.widget_visible.v -- ������������� ��������� �������
	widget_stat_mode.v = settings.widget_stat_mode.v
	imgui.Process = true -- ������ ImGui
	while true do
        if sampIsLocalPlayerSpawned() then
			sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ �����������. ����, ���������: {3d85c6} /msalary", 0xFFFFFF)
            currentMoney = getPlayerMoney(Player)
            while true do
				if sampIsLocalPlayerSpawned() then -- ������ �� ������� (�� ��������� �������� � ������ ����������)
					playerMoney = getPlayerMoney(Player)
					if currentMoney < playerMoney then
						earned = earned + (playerMoney - currentMoney)
						sessionEarn = sessionEarn + (playerMoney - currentMoney)
						lastOperations[os.date("%H:%M:%S")] = string.format('+' .. formatNumber((playerMoney - currentMoney)) .. ' $')
					elseif currentMoney > playerMoney then
						spended = spended - (currentMoney - playerMoney)
						sessionSpend = sessionSpend - (currentMoney - playerMoney)
						lastOperations[os.date("%H:%M:%S")] = string.format('-' .. formatNumber((currentMoney - playerMoney)) .. ' $')
					end
					daySalary = earned + spended
					sessSalary = sessionEarn + sessionSpend
					currentMoney = playerMoney
				end
                
                saveData() -- ���������� ������ ��� ������ ��������� �����
                wait(0)
            end
        end
        wait(0)
    end
end

local fontsize = nil
function imgui.BeforeDrawFrame()
    if fontsize == nil then
		imgui.GetIO().Fonts:Clear()
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', settings.widget_text_size.v, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end


-- ��������� GUI
function imgui.OnDrawFrame()

	if not main_window_state.v then
        imgui.ShowCursor = false
    end
	
	-- ������
    if settings.widget_visible.v then
        imgui.SetNextWindowPos(imgui.ImVec2(settings.widget_position.x.v, settings.widget_position.y.v), imgui.Cond_FirstUseEver)
		imgui.SetNextWindowSize(imgui.ImVec2(settings.widget_size.width.v, settings.widget_size.height.v), imgui.Cond_FirstUseEver)
        imgui.ShowCursor = false
        imgui.Begin('My Salary', widget_state, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
		
		if settings.widget_stat_mode.v then
			imgui.Text(u8'������: ' .. calcOnline(0, 0))
			
			imgui.Separator()
			
			imgui.PushFont(fontsize)
			imgui.Columns(2, nil, false)
			imgui.SetColumnWidth(0, 60)
			
			imgui.Text(u8'�����: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), formatNumber(earned) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Text(u8'������: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), formatNumber(spended) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Separator()
			
			imgui.Text(u8'����: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), formatNumber(daySalary) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Columns(1)
			imgui.PopFont()
			
		else
			imgui.Text(u8'������(������): ' .. calcOnline(2, 0))
			
			imgui.Separator()
			
			imgui.PushFont(fontsize)
			imgui.Columns(2, nil, false)
			imgui.SetColumnWidth(0, 60)
			
			imgui.Text(u8'�����: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), formatNumber(sessionEarn) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Text(u8'������: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), formatNumber(sessionSpend) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Separator()
			
			imgui.Text(u8'����: ')
			imgui.NextColumn()
			imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), formatNumber(sessSalary) .. u8' $') -- �������
			imgui.NextColumn()
			
			imgui.Columns(1)
			imgui.PopFont()
		end
        imgui.End()
    end

	-- ������� ����
    if main_window_state.v then
        imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond_FirstUseEver)
        imgui.ShowCursor = true
        imgui.Begin('My Salary Main Window', main_window_state, imgui.WindowFlags_NoCollapse)

		
		
		if imgui.Button(u8'����������') then
			tabN = 1
		end
		imgui.SameLine()
		if imgui.Button(u8'��������� ��������') then
			tabN = 2
		end
		imgui.SameLine()
		if imgui.Button(u8'���������') then
			tabN = 3
		end
		
		imgui.Separator()
		
		if tabN == 1 then
			saveData()
			
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
				imgui.Columns(2, nil, false)
				imgui.Text(u8'����� �� ������: ' .. formatNumber(sessionEarn) .. '$')
				imgui.Text(u8'������ �� ������: ' .. formatNumber(sessionSpend) .. '$')
				imgui.Text(u8'����� �� ������: ' .. formatNumber(sessSalary) .. '$')
				imgui.NextColumn()
				imgui.Text(u8'����� �� �������: ' .. formatNumber(earned) .. '$')
				imgui.Text(u8'������ �� �������: ' .. formatNumber(spended) .. '$')
				imgui.Text(u8'����� �� �������: ' .. formatNumber(daySalary) .. '$')
				imgui.Columns(1)
				if imgui.Button(u8'�������� ���������� �� ������') then
					sessionEarn = 0
					sessionSpend = 0
					sessSalary = 0
				end
				imgui.SameLine()
				if imgui.Button(u8'�������� ���������� �� �������') then
					earned = 0
					spended = 0
					daySalary = 0
					saveData()
				end
			end
			
			if statTab == 2 then
				local stats = getWeekStats()
				imgui.Text(u8'����� �� ������: ' .. formatNumber(stats.weekEarned) .. '$')
				imgui.Text(u8'������ �� ������: ' .. formatNumber(stats.weekSpended) .. '$')
				imgui.Text(u8'����� �� ������: ' .. formatNumber(stats.weekSalary) .. '$')
			end
			
			if statTab == 3 then 
				local stats = getMonthStats()
				imgui.Text(u8'����� �� �����: ' .. formatNumber(stats.monthEarned) .. '$')
				imgui.Text(u8'������ �� �����: ' .. formatNumber(stats.monthSpended) .. '$')
				imgui.Text(u8'����� �� �����: ' .. formatNumber(stats.monthSalary) .. '$')
			end
			
			imgui.Separator()
			imgui.Text(u8'��������� ����������: ')
			
			if next(data.salary) == nil then
				imgui.Text(u8"��� ������ ��� �����������")
			else
				for date, stats in pairs(data.salary) do
					if imgui.CollapsingHeader(u8(date)) then
						imgui.Text(u8'������ �� ����: ' .. calcOnline(1, stats.totalOnlineTime))
						imgui.Separator()
						imgui.Text(u8'�����: ' .. formatNumber(stats.earned) .. u8' $')
						imgui.Text(u8'������: ' .. formatNumber(stats.spended) .. u8' $')
						imgui.Separator()						
						imgui.Text(u8'����: ' .. formatNumber(stats.daySalary) .. u8' $')
						if date ~= os.date("%Y-%m-%d") then
							if imgui.Button(u8'������� ����') then
								data.salary[date] = nil
								saveData()
							end
						end
					end
				end
			end
		end
		
		if tabN == 2 then
			imgui.Text(u8'���� � �����: ' .. os.date("%d.%m.%Y") .. ', ' .. os.date("%X",os.time()))
			imgui.Separator()
			for operationTime, summ in pairs(lastOperations) do
				imgui.Text(operationTime .. ': ' .. summ)
			end
		end
		
		if tabN == 3 then
			imgui.Text(u8'��������� �������:')
            imgui.SameLine()
            if imgui.Checkbox(u8"��������", settings.widget_visible) then
				widget_state.v = settings.widget_visible.v
				data.settings.widget_visible = settings.widget_visible.v
				saveData()
			end
			
			imgui.Text(u8'����� ������� (��� - ����, ���� - ������): ')
            imgui.SameLine()
            if imgui.Checkbox(u8"���", settings.widget_stat_mode) then
				widget_stat_mode.v = settings.widget_stat_mode.v
				data.settings.widget_stat_mode = settings.widget_stat_mode.v
				saveData()
			end
			
			imgui.Separator()
			
            imgui.Text(u8'������� �������:')
            imgui.SliderInt("X", settings.widget_position.x, 0, 1920)
            imgui.SliderInt("Y", settings.widget_position.y, 0, 1080)

			imgui.Separator()

            imgui.Text(u8'������ �������:')
            imgui.SliderInt(u8"������", settings.widget_size.width, 100, 500)
            imgui.SliderInt(u8"������", settings.widget_size.height, 50, 300)
			
			imgui.Separator()
			
			imgui.Text(u8'������ ������')
			imgui.SliderInt(u8"������", settings.widget_text_size, 5, 20)
            saveData()
			imgui.SameLine()
			if imgui.Button(u8'���������') then
				saveData()
				sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ ����� ������������...", 0xFFFFFF)
				main_window_state.v = false
				showCursor(false,false)
				imgui.Process = false
				thisScript():reload()
			end
			
			imgui.Separator()
			
			if imgui.Button(u8'�������� ��� ����������') then
				earned = 0
				spended = 0
				daySalary = 0
				data.salary = {}
				saveData()
			end
		end
        imgui.End()
    end
	
	-- ���� ��� ���� �������, �������� ������
	if not main_window_state.v then
		imgui.ShowCursor = false
	end
end

-- ��������/�������� ����
function openMainWindow()
    main_window_state.v = not main_window_state.v
end

-- �������������� �����
function formatNumber(n)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return formatted:gsub("^%.", "") -- ������� ������ ����� � ������, ���� ����� < 1000
end

-- ������� ��� ��������� ������� ����
function getCurrentDate()
    return os.date("%Y-%m-%d") -- ������: 2025-01-29
end

function calcOnline(mode, prevOnline)
    local sessionTime = gameClock()
    
	local totalTime
	if mode == 0 then
		totalTime = totalOnlineTime + sessionTime
	elseif mode == 1 then
		totalTime = prevOnline or 0
	else 
		totalTime = sessionTime
	end
    
    -- ������������ � ����, ������, �������
    local timeHours = math.floor(totalTime / 3600)
    local remaining = totalTime % 3600
    local timeMins = math.floor(remaining / 60)
    local timeSecs = remaining % 60
    
    -- ���������� ����������������� ������
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
        weekSalary = 0
    }

    for i = 0, 6 do
        local date = os.date("%Y-%m-%d", os.time({year = currentDate.year, month = currentDate.month, day = currentDate.day}) - i * 86400)
        if data.salary[date] then
            stats.weekEarned = stats.weekEarned + (data.salary[date].earned or 0)
            stats.weekSpended = stats.weekSpended + (data.salary[date].spended or 0)
            stats.weekSalary = stats.weekSalary + (data.salary[date].daySalary or 0)
        end
    end

    return stats
end

function getMonthStats()
    local currentDate = os.date("*t")
    local stats = {
        monthEarned = 0,
        monthSpended = 0,
        monthSalary = 0
    }

    for i = 0, 29 do
        local date = os.date("%Y-%m-%d", os.time({year = currentDate.year, month = currentDate.month, day = currentDate.day}) - i * 86400)
        if data.salary[date] then
            stats.monthEarned = stats.monthEarned + (data.salary[date].earned or 0)
            stats.monthSpended = stats.monthSpended + (data.salary[date].spended or 0)
            stats.monthSalary = stats.monthSalary + (data.salary[date].daySalary or 0)
        end
    end

    return stats
end