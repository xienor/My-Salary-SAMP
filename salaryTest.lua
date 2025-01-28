script_name("My Salary")
script_authors("mihaha")
script_version("0.1")

require 'lib.moonloader'
local imgui = require 'imgui'
local events = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'

local playerMoney = 0
local currentMoney = 0
local earned = 0
local main_window_state = imgui.ImBool(false)

function main()
  print("Loading: My Salary")
  while not isSampAvailable() do wait(0) end
  sampRegisterChatCommand("msalary", openWindow)
  wait(0)
  print("Command registered")
  while true do
			if sampIsLocalPlayerSpawned() then
        currentMoney = getPlayerMoney(Player)
        print("Player money" .. currentMoney)
        while true do
          playerMoney = getPlayerMoney(Player)
          if currentMoney < playerMoney then
            earned = earned + (playerMoney - currentMoney)
            print("Session salary: " .. earned)
          elseif currentMoney > playerMoney then
            earned = earned - (currentMoney - playerMoney)
            print("Session salary: " .. earned)
          end
          currentMoney = playerMoney
          wait(0)
        end
      end
      wait(0)
    end
  end
function imgui.OnDrawFrame()
    if main_window_state.v then
      imgui.SetNextWindowSize(imgui.ImVec2(150, 200), imgui.Cond.FirstUseEver)
      imgui.Begin('My Salary', windowOpen)
      imgui.Text('Hello world')
      imgui.Text('Earn: $' .. earned)
      imgui.End()
    end
end
function openWindow()
   main_window_state.v = not main_window_state.v
   imgui.Process = main_window_state.v
 end