--�������������� �������
script_name("My Salary")
script_authors("mihaha")
script_version("0.8.1")

--����������� ���������
require 'moonloader'
local imgui = require 'imgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'

--���������
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- ���������� ����������
local playerMoney = 0 -- ������ � ������
local currentMoney = 0 -- ������ ���������� � �������
local earned = 0 -- �������� �����
local spended = 0 -- ��������� �����
local sessionSalary = 0 --����� ����� �� ����

local totalOnlineTime = 0 -- ����� ������ �� �����
local timeSecs = 0 -- ������ ������
local timeMins = 0 -- ������ �����
local timeHours = 0 -- ������ �����

local tabN = 1

-- ���������� ������������� �������
local widget_state = imgui.ImBool(false) -- ��������� �������
local main_window_state = imgui.ImBool(false) -- ��������� �������� ����
local widget_position = { x = 100, y = 100 } -- ������� �������
local widget_size = { width = 150, height = 100 } -- ������ �������
local widget_text_size = imgui.ImInt(14) -- ������ ������

-- ���������
local settings = {
    widget_visible = imgui.ImBool(false), -- ��������� �������
    widget_position = { x = imgui.ImInt(100), y = imgui.ImInt(100) }, -- ������� �������
    widget_size = { width = imgui.ImInt(150), height = imgui.ImInt(100) }, -- ������ �������
	widget_text_size = imgui.ImInt(14) -- ������ ������
}

-- ���� � JSON-�����
local path = getWorkingDirectory() .. "\\config\\MySalary[Data].json"

-- ��������� ������
local data = {
    salary = {}, -- ������� �������
    settings = {
        widget_visible = false,
        widget_position = { x = 100, y = 100 },
        widget_size = { width = 150, height = 100 },
		widget_text_size = 14
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
        sessionSalary = data.salary[currentDate].sessionSalary or 0
		totalOnlineTime = data.salary[currentDate].totalOnlineTime or 0
    else
        earned = 0
        spended = 0
        sessionSalary = 0
		totalOnlineTime = 0
    end

    -- �������� ��������
    if data and data.settings then
        settings.widget_visible = imgui.ImBool(data.settings.widget_visible)
        settings.widget_position = {
            x = imgui.ImInt(data.settings.widget_position.x or 100),
            y = imgui.ImInt(data.settings.widget_position.y or 100)
        }
        settings.widget_size = {
            width = imgui.ImInt(data.settings.widget_size.width or 150),
            height = imgui.ImInt(data.settings.widget_size.height or 100)
        }
		settings.widget_text_size = imgui.ImInt(data.settings.widget_text_size or 10)
		widget_state.v = settings.widget_visible.v
    end
end

-- ���������� ������
function saveData()
    local currentDate = getCurrentDate()
    data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        sessionSalary = sessionSalary,
		totalOnlineTime = totalOnlineTime + gameClock()
    }
    data.update_date = currentDate

    -- ���������� ��������
    data.settings = {
        widget_visible = settings.widget_visible.v,
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
	imgui.Process = true -- ������ ImGui
	while true do
        if sampIsLocalPlayerSpawned() then
			sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ �����������. ����, ���������: {3d85c6} /msalary", 0xFFFFFF)
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
        imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), formatNumber(sessionSalary) .. u8' $') -- �������
		imgui.NextColumn()
		
		imgui.Columns(1)
		imgui.PopFont()
		
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
		if imgui.Button(u8'���������') then
		tabN = 2
		end
		
		imgui.Separator()
		
		if tabN == 1 then
			saveData()
			
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
						imgui.Text(u8'����: ' .. formatNumber(stats.sessionSalary) .. u8' $')
					end
				end
			end
		end
		
		
		if tabN == 2 then
			imgui.Text(u8'��������� �������:')
            imgui.SameLine()
            if imgui.Checkbox(u8"��������", settings.widget_visible) then
				widget_state.v = settings.widget_visible.v
				data.settings.widget_visible = settings.widget_visible.v
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
	else 
		totalTime = prevOnline or 0
	end
    
    -- ������������ � ����, ������, �������
    local timeHours = math.floor(totalTime / 3600)
    local remaining = totalTime % 3600
    local timeMins = math.floor(remaining / 60)
    local timeSecs = remaining % 60
    
    -- ���������� ����������������� ������
    return string.format("%02d:%02d:%02d", timeHours, timeMins, timeSecs)
end

function script.onExit()
    saveData()
    sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}������ ���������. ���������� �������", 0xFFFFFF)
end