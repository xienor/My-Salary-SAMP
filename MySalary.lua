script_name("My Salary")
script_authors("mihaha")
script_version("0.1")

require 'lib.moonloader'
local imgui = require 'imgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local playerMoney = 0
local currentMoney = 0
local earned = 0
local spended = 0
local sessionSalary = 0
local main_window_state = imgui.ImBool(false)

function main()
  --print("Loading: My Salary")
  while not isSampAvailable() do wait(0) end
sampAddChatMessage("{674ea7}[My Salary] {FFFFFF}Скрипт активирован. Вывести окно: {3d85c6} /msalary", 0xFFFFFF)
  sampRegisterChatCommand("msalary", openWindow)
  wait(0)
  --print("Command registered")
  while true do
			if sampIsLocalPlayerSpawned() then
        currentMoney = getPlayerMoney(Player)
        print("Player money" .. currentMoney)
        while true do
          playerMoney = getPlayerMoney(Player)
          if currentMoney < playerMoney then
            earned = earned + (playerMoney - currentMoney)
            --print("Session salary: " .. earned)
          elseif currentMoney > playerMoney then
            spended = spended - (currentMoney - playerMoney)
            --print("Session salary: " .. earned)
          end
          sessionSalary = earned + spended
          currentMoney = playerMoney
          wait(0)
        end
      end
      wait(0)
    end
  end
function imgui.OnDrawFrame()
    if main_window_state.v then
      imgui.ShowCursor = false
      imgui.Begin('My Salary', windowOpen, imgui.WindowFlags_AlwaysAutoResize)
      imgui.Text(u8'Доход: ')
      imgui.SameLine()
      imgui.TextColored(imgui.ImVec4(0, 1, 0, 1), formatNumber(earned) .. u8' $') -- Зеленый

      imgui.Text(u8'Расход: ')
      imgui.SameLine()
      imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), formatNumber(spended) .. u8' $') -- Красный

      imgui.Text(u8'Итог: ')
      imgui.SameLine()
      imgui.TextColored(imgui.ImVec4(1, 0.84, 0, 1), formatNumber(sessionSalary) .. u8' $') -- Золотой

      imgui.End()
    end
end
function openWindow()
   main_window_state.v = not main_window_state.v
   imgui.Process = main_window_state.v
 end
 
 function formatNumber(n)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return formatted:gsub("^%.", "") -- Убираем лишнюю точку в начале, если число < 1000
end