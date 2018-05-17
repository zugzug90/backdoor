--MODULE FOR THE GAMESTATE: MAIN MENU--
local DB              = require 'database'
local MENU            = require 'infra.menu'
local DIRECTIONALS    = require 'infra.dir'
local INPUT           = require 'input'
local CONFIGURE_INPUT = require 'input.configure'
local PROFILE         = require 'infra.profile'
local Activity        = require 'common.activity'
local StartMenuView   = require 'view.startmenu'
local FadeView        = require 'view.fade'

local state = {}

--LOCAL VARIABLES--

local _menu_view
local _menu_context
local _locked
local _activity = Activity()

-- LOCAL METHODS --

function _activity:quit()
  _locked = true
  local fade_view = FadeView(FadeView.STATE_UNFADED)
  fade_view:addElement("GUI")
  fade_view:fadeOutAndThen(self.resume)
  self.yield()
  love.event.quit()
end

function _activity:enterMenu()
  _locked = true
  local fade_view = FadeView(FadeView.STATE_FADED)
  fade_view:addElement("GUI")
  fade_view:fadeInAndThen(self.resume)
  self.yield()
  _locked = false
  fade_view:destroy()
end

function _activity:changeState(mode, to, ...)
  _locked = true
  local fade_view = FadeView(FadeView.STATE_UNFADED)
  fade_view:addElement("GUI")
  fade_view:fadeOutAndThen(self.resume)
  self.yield()
  fade_view:destroy()
  _menu_view.invisible = true
  if mode == 'push' then
    SWITCHER.push(to, ...)
  elseif mode == 'switch' then
    SWITCHER.switch(to, ...)
  end
end


--STATE FUNCTIONS--

function state:enter()
  _menu_context = "START_MENU"

  _menu_view = StartMenuView()
  _menu_view:addElement("HUD")

  _activity:enterMenu()
end

function state:leave()
  _menu_view:destroy()
  _menu_view = nil
end

function state:resume(from, player_info)
  if player_info then
    _locked = true
    print(("%s %s"):format(player_info.species, player_info.background))
    SWITCHER.switch(GS.PLAY, PROFILE.newRoute(player_info))
  else
    _menu_context = "START_MENU"
    _menu_view.invisible = false
    _activity:enterMenu()
  end
end

function state:update(dt)
  MAIN_TIMER:update(dt)

  if not _locked then
    if INPUT.wasActionPressed('CONFIRM') then
      MENU.confirm()
    elseif INPUT.wasActionPressed('SPECIAL') or
           INPUT.wasActionPressed('CANCEL') or
           INPUT.wasActionPressed('QUIT') then
      MENU.cancel()
    elseif DIRECTIONALS.wasDirectionTriggered('UP') then
      MENU.prev()
    elseif DIRECTIONALS.wasDirectionTriggered('DOWN') then
      MENU.next()
    end
  end

  if _menu_context == "START_MENU" then
    _menu_view:setItem("New route")
    _menu_view:setItem("Load route")
    if DEV then
      _menu_view:setItem("Controls")
    end
    _menu_view:setItem("Quit")
  elseif _menu_context == "LOAD_LIST" then
    local savelist = PROFILE.getSaveList()
    if next(savelist) then
      for route_id, route_header in pairs(savelist) do
        local savename = ("%s %s"):format(route_id, route_header.player_name)
        _menu_view:setItem(savename)
      end
    else
      _menu_view:setItem("[ NO DATA ]")
    end
  end

  if MENU.begin(_menu_context) then
    if _menu_context == "START_MENU" then
      if MENU.item("New route") then
        _locked = true
        _activity:changeState('push', GS.CHARACTER_BUILD)
      end
      if MENU.item("Load route") then
        _menu_context = "LOAD_LIST"
      end
      if DEV and MENU.item("Controls") then
        CONFIGURE_INPUT(INPUT, INPUT.getMap())
      end
      if MENU.item("Quit") then
        _activity:quit()
      end
    elseif _menu_context == "LOAD_LIST" then
      local savelist = PROFILE.getSaveList()
      if next(savelist) then
        for route_id, route_header in pairs(savelist) do
          local savename = ("%s %s"):format(route_id, route_header.player_name)
          if MENU.item(savename) then
            local route_data = PROFILE.loadRoute(route_id)
            _activity:changeState('switch', GS.PLAY, route_data)
          end
        end
      else
        if MENU.item("[ NO DATA ]") then
          print("Cannot load no data.")
        end
      end
    end
  else
    if _menu_context == "START_MENU" then
      _activity:quit()
    elseif _menu_context == "LOAD_LIST" then
      _menu_context = "START_MENU"
    end
  end
  MENU.finish()
  _menu_view:setSelection(MENU.getSelection())
end

function state:draw()
  Draw.allTables()
end

--Return state functions
return state

