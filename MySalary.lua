-- Характеристики скрипта
script_name("My Salary")
script_authors("mihaha")
script_version("0.14.1")

-- Подключение библиотек
require 'moonloader'
local imgui = require 'mimgui' -- Используем mimgui
local events = require 'lib.samp.events'
local encoding = require 'encoding'
local ffi = require 'ffi'
local wm = require 'windows.message'    -- Список событий для окна игры

-- Кодировка
encoding.default = 'CP1251'
u8 = encoding.UTF8

--Обновления
local updateURL = "https://api.github.com/repos/xienor/My-Salary-SAMP/releases"
local updateWindowState = imgui.new.bool(false)
local isJsonLoaded = false
local releasesData = {}

-- Глобальные переменные
local playerMoney = 0 -- Деньги у игрока
local currentMoney = 0 -- Деньги записанные в скрипте
local earned = 0 -- Получено денег
local spended = 0 -- Потрачено денег
local daySalary = 0 -- Общий доход за день

local lastOperations = {}

local payDayCount = 0 -- Количество PayDay за день
local lastPayDay = 0

local sessionEarn = 0 -- Сессия
local sessionSpend = 0
local sessSalary = 0

-- Время
local totalOnlineTime = 0 -- Общий онлайн за день
local startTime = 0
local nowTime = 0
local onlineTime = 0
local afkTime = 0
local timeSecs = 0 -- Онлайн секунд
local timeMins = 0 -- Онлайн минут
local timeHours = 0 -- Онлайн часов

-- Вкладки
local tabN = 1
local statTab = 1

-- Лог серверных сообщений

local chatLog = {}

-- Экран
local screenResX = imgui.new.int(1920)
local screenResY = imgui.new.int(1080)

-- Настройки
local hidden = imgui.new.bool(false)
local wasCursorActive = false
local new = imgui.new

-- Переменные характеристик скрипта
local widget_state = imgui.new.bool(true) -- Видимость виджета
local main_window_state = imgui.new.bool(false) -- Видимость главного окна
local log_window_state = imgui.new.bool(false) -- Видимость окна логов
local widget_position = { x = 1500, y = 190 } -- Позиция виджета
local widget_size = { width = 200, height = 90 } -- Размер виджета
local widget_text_size = imgui.new.int(14) -- Размер текста
local widget_stat_mode = imgui.new.bool(true) -- Режим работы виджета (0 - сессия, 1 - день)
local hideWidgetWhenCursor = imgui.new.bool(false)
local widgetAlpha = imgui.new.float(1.0)

-- Настройки
local settings = {
	hideWidgetWhenCursor = imgui.new.bool(false),
    widget_visible = imgui.new.bool(true), -- Видимость виджета
    widget_position = { x = imgui.new.int(1500), y = imgui.new.int(190) }, -- Позиция виджета
    widget_size = { width = imgui.new.int(200), height = imgui.new.int(90) }, -- Размер виджета
    widget_text_size = imgui.new.int(14), -- Размер текста
    widget_stat_mode = imgui.new.bool(true), -- Режим работы виджета (0 - сессия, 1 - день)
	widgetAlpha = imgui.new.float(1.0)
}

local moneyEvents = {
	--{chatString="",event=""},
	{chatString="Вы успешно погасили неоплаченные счета за коммунальные услуги",event="Оплата коммунальных услуг"},
	{chatString="пополнили счёт дома за электроэнергию" ,event="Оплата электроэнергии"},
	{chatString="Вы оплатили все налоги на сумму",event="Оплата всех налогов"}
}

-- Путь к JSON-файлу
local path = getWorkingDirectory() .. "\\config\\MySalary[Data].json"

-- Структура данных
local data = {
    salary = {}, -- Таблица доходов
    settings = {
		hideWidgetWhenCursor = false,
        widget_visible = true,
        widget_position = { x = 1500, y = 190 },
        widget_size = { width = 200, height = 90 },
        widget_text_size = 14,
        widget_stat_mode = true,
		widgetAlpha = 1.0
    },
    update_date = "" -- Последняя дата обновления
}

-- Инициализация файла
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

-- Загрузка данных
function loadData()
    local currentDate = getCurrentDate()
    if data.salary[currentDate] then
        earned = data.salary[currentDate].earned or 0
        spended = data.salary[currentDate].spended or 0
        daySalary = data.salary[currentDate].daySalary or 0
        totalOnlineTime = data.salary[currentDate].totalOnlineTime or 0
        payDayCount = data.salary[currentDate].payDayCount or 0
    else
        earned = 0
        spended = 0
        daySalary = 0
        totalOnlineTime = 0
        payDayCount = 0
    end

    -- Загрузка настроек
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

-- Сохранение данных
function saveData()
    local currentDate = getCurrentDate()
	if data.salary[currentDate] then
		data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        daySalary = daySalary,
		payDayCount = payDayCount,
		totalOnlineTime = totalOnlineTime
    }
    data.update_date = currentDate
	else
		earned = 0
		spended = 0
		daySalary = 0
		totalOnlineTime = 0
		payDayCount = 0
		data.salary[currentDate] = {
        earned = earned,
        spended = spended,
        daySalary = daySalary,
		payDayCount = payDayCount,
		totalOnlineTime = totalOnlineTime,
    }
    data.update_date = currentDate
	end

    -- Сохранение настроек
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

-- Основная функция
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

    widget_state[0]= settings.widget_visible[0]-- Устанавливаем состояние виджета
    widget_stat_mode[0]= settings.widget_stat_mode[0]
	
	while true do
        if sampIsLocalPlayerSpawned() then
			sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}Скрипт активирован. Меню, настройки: {3d85c6} /msalary", 0xFFFFFF)
			wait(1000)
            currentMoney = getPlayerMoney(Player)
			wait(1000)
            while true do
				if sampIsLocalPlayerSpawned() then -- Защита от вылетов (не учитывает операции в случае дисконекта)
					playerMoney = getPlayerMoney(Player)
					if currentMoney < playerMoney then
						earned = earned + (playerMoney - currentMoney)
						sessionEarn = sessionEarn + (playerMoney - currentMoney)
						lastOperations[os.date("%H:%M:%S")] = string.format('+' .. formatNumber((playerMoney - currentMoney)) .. ' $')
					elseif currentMoney > playerMoney then
						spended = spended - (currentMoney - playerMoney)
						sessionSpend = sessionSpend - (currentMoney - playerMoney)
						
						operationType = "Операция не опеределена"
						local operationTime = os.time()
						for i = #chatLog, 1, -1 do
							local logEntry = chatLog[i]
							-- Проверяем, было ли сообщение не более 5 секунд назад
							if operationTime - logEntry.time <= 5 then
								for _, event in ipairs(moneyEvents) do
									if string.match(logEntry.text, event.chatString) then
										operationType = event.event
										break
									end
								end
							else
								break -- Прерываем, если сообщения слишком старые
							end
						end
						lastOperations[os.date("%H:%M:%S", operationTime)] = string.format('-' .. formatNumber((currentMoney - playerMoney)) .. ' $' .. " " .. operationType)
					end
					daySalary = earned + spended
					sessSalary = sessionEarn + sessionSpend
					currentMoney = playerMoney
					if hideWidgetWhenCursor[0] == true then
						local isCursorActive = sampIsCursorActive()
						if isCursorActive ~= wasCursorActive then
							wasCursorActive = isCursorActive -- Обновляем предыдущее состояние
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
                countPayDay() -- Проверка PayDay
                saveData() -- Сохранение данных при каждом изменении суммы
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

-- Рендеринг GUI
local widget = imgui.OnFrame(
	function() return widget_state[0] end,
	function(player)
		imgui.SetNextWindowPos(imgui.ImVec2(settings.widget_position.x[0], settings.widget_position.y[0]), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(settings.widget_size.width[0], settings.widget_size.height[0]), imgui.Cond.Always)
		imgui.SetNextWindowBgAlpha(settings.widgetAlpha[0])
		imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1, 1, 1, 0))
		imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, settings.widgetAlpha[0]))
		imgui.PushStyleColor(imgui.Col.Separator, imgui.ImVec4(1, 1, 1, settings.widgetAlpha[0]))
		imgui.Begin(u8'My Salary: Виджет', widget_state, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
		player.HideCursor = true
        if settings.widget_stat_mode[0] then
            imgui.Text(u8'Онлайн: ' .. formatTime(0, 0))

            imgui.Separator()

            imgui.PushFont(fontsize)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 60)

            imgui.Text(u8'Доход: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, settings.widgetAlpha[0]), formatNumber(earned) .. u8' $') -- Зеленый
            imgui.NextColumn()

            imgui.Text(u8'Расход: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0, 0, settings.widgetAlpha[0]), formatNumber(spended) .. u8' $') -- Красный
            imgui.NextColumn()

            imgui.Separator()

            imgui.Text(u8'Итог: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0.84, 0, settings.widgetAlpha[0]), formatNumber(daySalary) .. u8' $') -- Золотой
            imgui.NextColumn()

            imgui.Columns(1)
            imgui.PopFont()
        else
            imgui.Text(u8'Онлайн(сессия): ' .. formatTime(2, 0))

            imgui.Separator()

            imgui.PushFont(fontsize)
            imgui.Columns(2, nil, false)
            imgui.SetColumnWidth(0, 60)

            imgui.Text(u8'Доход: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(0, 1, 0, settings.widgetAlpha[0]), formatNumber(sessionEarn) .. u8' $') -- Зеленый
            imgui.NextColumn()

            imgui.Text(u8'Расход: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0, 0, settings.widgetAlpha[0]), formatNumber(sessionSpend) .. u8' $') -- Красный
            imgui.NextColumn()

            imgui.Separator()

            imgui.Text(u8'Итог: ')
            imgui.NextColumn()
            imgui.TextColored(imgui.ImVec4(1, 0.84, 0, settings.widgetAlpha[0]), formatNumber(sessSalary) .. u8' $') -- Золотой
            imgui.NextColumn()

            imgui.Columns(1)
            imgui.PopFont()
        end
		imgui.PopStyleColor() -- Текст
		imgui.PopStyleColor() -- Рамка
		imgui.PopStyleColor() -- Разделители
        imgui.End()
    end
)

local mainWindow = imgui.OnFrame(
	function() return main_window_state[0] end,
	function(player)
		imgui.SetNextWindowSize(imgui.ImVec2(500, 400), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'My Salary: Главное окно', main_window_state, imgui.WindowFlags.NoCollapse)
		player.HideCursor = false
        if imgui.Button(u8'Статистика') then
            tabN = 1
        end
        imgui.SameLine()
        if imgui.Button(u8'Последние операции') then
            tabN = 2
        end
        imgui.SameLine()
        if imgui.Button(u8'Настройки') then
            tabN = 3
        end

        imgui.Separator()

        if tabN == 1 then
            saveData()

            imgui.Text(u8'Общая статистика: ')
            if imgui.Button(u8'Эта сессия') then
                statTab = 1
            end

            imgui.SameLine()

            if imgui.Button(u8'Неделя') then
                statTab = 2
            end

            imgui.SameLine()

            if imgui.Button(u8'Месяц') then
                statTab = 3
            end

            imgui.Separator()

            if statTab == 1 then
				imgui.Columns(2, nil, false)
				imgui.Text(u8'Доход за сессию: ' .. formatNumber(sessionEarn) .. '$')
				imgui.Text(u8'Расход за сессию: ' .. formatNumber(sessionSpend) .. '$')
				imgui.Text(u8'Итого за сессию: ' .. formatNumber(sessSalary) .. '$')
				imgui.NextColumn()
				imgui.Text(u8'Доход за сегодня: ' .. formatNumber(earned) .. '$')
				imgui.Text(u8'Расход за сегодня: ' .. formatNumber(spended) .. '$')
				imgui.Text(u8'Итого за сегодня: ' .. formatNumber(daySalary) .. ' $')
				imgui.Text(u8'PayDay получено за сегодня: ' .. payDayCount)
				imgui.Columns(1)

				if imgui.Button(u8'Очистить статистику за сессию') then
					sessionEarn = 0
					sessionSpend = 0
					sessSalary = 0
				end
				imgui.SameLine()
				if imgui.Button(u8'Очистить статистику за сегодня') then
					earned = 0
					spended = 0
					daySalary = 0
					totalOnlineTime = 0
					payDayCount = 0
					saveData()
				end
            end

            if statTab == 2 then
                local stats = getWeekStats()
                imgui.Text(u8'Доход за неделю: ' .. formatNumber(stats.weekEarned) .. '$')
                imgui.Text(u8'Расход за неделю: ' .. formatNumber(stats.weekSpended) .. '$')
                imgui.Text(u8'Итого за неделю: ' .. formatNumber(stats.weekSalary) .. '$')
                imgui.Text(u8'PayDay за неделю: ' .. stats.weekPayDay)
            end

            if statTab == 3 then
                local stats = getMonthStats()
                imgui.Text(u8'Доход за месяц: ' .. formatNumber(stats.monthEarned) .. '$')
                imgui.Text(u8'Расход за месяц: ' .. formatNumber(stats.monthSpended) .. '$')
                imgui.Text(u8'Итого за месяц: ' .. formatNumber(stats.monthSalary) .. '$')
                imgui.Text(u8'PayDay за месяц: ' .. stats.monthPayDay)
            end

            imgui.Separator()
			if imgui.BeginChild("allStats") then
				imgui.Text(u8'Подневная статистика: ')

				if next(data.salary) == nil then
					imgui.Text(u8"Нет данных для отображения")
				else
					-- Получаем и сортируем даты в порядке убывания (сначала новые)
					local sortedDates = {}
					for date in pairs(data.salary) do
						table.insert(sortedDates, date)
					end
					table.sort(sortedDates, function(a, b) return a > b end) -- Сортировка от новых к старым

					-- Перебираем уже отсортированные даты
					for _, date in ipairs(sortedDates) do
						local stats = data.salary[date]
						if imgui.CollapsingHeader(u8(date)) then
							imgui.Text(u8'Онлайн за день: ' .. formatTime(1, stats.totalOnlineTime))
							imgui.Text(u8'PayDay за день: ' .. stats.payDayCount)
							imgui.Separator()
							imgui.Text(u8'Доход: ' .. formatNumber(stats.earned) .. u8' $')
							imgui.Text(u8'Расход: ' .. formatNumber(stats.spended) .. u8' $')
							imgui.Separator()
							imgui.Text(u8'Итог: ' .. formatNumber(stats.daySalary) .. u8' $')
							if date ~= os.date("%Y-%m-%d") then
								if imgui.Button(u8'Удалить день') then
									data.salary[date] = nil
									saveData()
								end
							end
						end
					end
				end
			imgui.EndChild()
			end
        end

        if tabN == 2 then
            imgui.Text(u8'Дата и время: ' .. os.date("%d.%m.%Y") .. ', ' .. os.date("%X", os.time()))
            imgui.Separator()
            for operationTime, summ in pairs(lastOperations) do
                imgui.Text(operationTime .. ': ' .. u8(summ))
            end
        end

        if tabN == 3 then
            imgui.Text(u8'Видимость виджета:')
            imgui.SameLine()
            if imgui.Checkbox(u8"Включено", settings.widget_visible) then
                widget_state[0] = settings.widget_visible[0]
                data.settings.widget_visible = settings.widget_visible[0]
                saveData()
            end

            imgui.Text(u8'Режим виджета (ВКЛ - День, ВЫКЛ - Сессия): ')
            imgui.SameLine()
            if imgui.Checkbox(u8"День", settings.widget_stat_mode) then
                widget_stat_mode[0] = settings.widget_stat_mode[0]
                data.settings.widget_stat_mode = settings.widget_stat_mode[0]
                saveData()
            end
			imgui.Text(u8'Скрывать виджет при активном курсоре (инвентарь, чат...)')
			imgui.SameLine()
			if imgui.Checkbox(u8"Скрывать", settings.hideWidgetWhenCursor) then
                hideWidgetWhenCursor[0] = settings.hideWidgetWhenCursor[0]
                data.settings.hideWidgetWhenCursor = settings.hideWidgetWhenCursor[0]
                saveData()
            end

            imgui.Separator()

            imgui.Text(u8'Позиция виджета:')
            imgui.SliderInt("X", settings.widget_position.x, 0, screenResX[0] - widget_size.width)
            imgui.SliderInt("Y", settings.widget_position.y, 0, screenResY[0] - widget_size.height)

            imgui.Separator()

            imgui.Text(u8'Размер виджета:')
            imgui.SliderInt(u8"Ширина", settings.widget_size.width, 100, 500)
            imgui.SliderInt(u8"Высота", settings.widget_size.height, 50, 300)

            imgui.Separator()

			imgui.Text(u8"Прозрачность виджета: ")
			imgui.SliderFloat(u8"0-1", settings.widgetAlpha, 0.0, 1.0)
			
			imgui.Separator()

            imgui.Text(u8'Размер шрифта')
            imgui.SliderInt(u8"Размер", settings.widget_text_size, 5, 20)
            saveData()
            imgui.SameLine()
            if imgui.Button(u8'Применить') then
                saveData()
                sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}Скрипт будет перезагружен...", 0xFFFFFF)
                main_window_state[0] = false
                thisScript():reload()
            end

            imgui.Separator()
			
			if imgui.Button(u8"Проверить обновления") then
				updateWindowState[0] = not updateWindowState[0]
			end
			
			imgui.Separator()

            if imgui.Button(u8'Очистить всю статистику') then
                earned = 0
                spended = 0
                daySalary = 0
                payDayCount = 0
                totalOnlineTime = 0
                data.salary = {}
                saveData()
            end
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
        imgui.Begin(u8'My Salary: ЧатЛог', log_window_state, imgui.WindowFlags.NoCollapse)
		player.HideCursor = false
		
		-- for _, log in ipairs(chatLog) do
			-- imgui.Text(u8(log))
		-- end
		for _, log in ipairs(chatLog) do
			logButtonText = string.format("[" .. os.date("%H:%M:%S", log.time) .. "]" .. " " .. log.text)
			if imgui.Button(u8(logButtonText)) then
				print(logButtonText)
			end
			--imgui.Text(u8(string.format("[" .. log.time .. "]" .. " " .. log.text)))
		end
		
        imgui.End()
		if not log_window_state[0] then
		imgui.GetIO().MouseDrawCursor = false
		end
    end
)

-- Открытие/закрытие окна
function openMainWindow()
    main_window_state[0]= not main_window_state[0]
end

function openChatLog()
    log_window_state[0]= not log_window_state[0]
end

-- Форматирование чисел
function formatNumber(n)
    local sign = n < 0 and "-" or ""
    local formatted = tostring(math.abs(n)):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return sign .. formatted:gsub("^%.", "")
end

-- Функция для получения текущей даты
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
		oTime = totalOnlineTime
	elseif mode == 1 then
		oTime = vremya or 0
	else 
		oTime = gameClock()
	end
	
	local timeHours = math.floor(oTime / 3600)
    local remaining = oTime % 3600
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
        weekPayDay = 0
    }

    for i = 0, 6 do
        local date = os.date("%Y-%m-%d", os.time({ year = currentDate.year, month = currentDate.month, day = currentDate.day }) - i * 86400)
        if data.salary[date] then
            stats.weekEarned = stats.weekEarned + (data.salary[date].earned or 0)
            stats.weekSpended = stats.weekSpended + (data.salary[date].spended or 0)
            stats.weekSalary = stats.weekSalary + (data.salary[date].daySalary or 0)
            stats.weekPayDay = stats.weekPayDay + (data.salary[date].payDayCount or 0)
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
        monthPayDay = 0
    }

    for i = 0, 29 do
        local date = os.date("%Y-%m-%d", os.time({ year = currentDate.year, month = currentDate.month, day = currentDate.day }) - i * 86400)
        if data.salary[date] then
            stats.monthEarned = stats.monthEarned + (data.salary[date].earned or 0)
            stats.monthSpended = stats.monthSpended + (data.salary[date].spended or 0)
            stats.monthSalary = stats.monthSalary + (data.salary[date].daySalary or 0)
            stats.monthPayDay = stats.monthPayDay + (data.salary[date].payDayCount or 0)
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
    end
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
					sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}Доступна новая версия! Обновиться можно в настройках.", 0xFFFFFF)
				else
					sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}У вас установлена самая последняя версия.", 0xFFFFFF)
				end
                file:close()
                isJsonLoaded = true
            else
                print("Ошибка: Не удалось открыть MySalary[Releases].json")
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
        imgui.Begin(u8'MySalary: Обновление', updateWindowState, imgui.WindowFlags.NoCollapse)
        player.HideCursor = false
        -- Проверяем, загружены ли данные
		imgui.Text(u8" Установленная версия: " .. thisScript().version)
        if not isJsonLoaded then
            imgui.Text(u8"Загрузка обновлений...")
        else
            for _, release in ipairs(releasesData) do
                if imgui.CollapsingHeader(u8(release.tag_name)) then
                    imgui.Text(u8"Версия: " .. release.tag_name)
                    imgui.Text(u8"Дата выпуска: " .. release.published_at)
                    imgui.Text(u8"Что нового: " .. release.body)
                    
                    for _, asset in ipairs(release.assets or {}) do
                        if imgui.Button(u8"Скачать " .. asset.name) then
                            local verUrl = asset.browser_download_url
                            local tempPath = thisScript().path .. ".new"

                            downloadUrlToFile(verUrl, tempPath, function(_, status)
                                if status == require("moonloader").download_status.STATUSEX_ENDDOWNLOAD then
                                    if doesFileExist(tempPath) then
                                        os.remove(thisScript().path)
                                        os.rename(tempPath, thisScript().path)
                                        thisScript():reload()
                                    else
                                        print("Ошибка: не удалось скачать файл...")
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
        time = os.time(), -- Сохраняем timestamp вместо строки
        text = uncoloredText
    })
    
    -- Ограничиваем размер лога (например, последние 50 сообщений)
    if #chatLog > 50 then
        table.remove(chatLog, 1)
    end
end