
-- luacheck: globals MAIN_TIMER, no self

local DIRECTIONALS  = require 'infra.dir'
local LONG_WALK     = require 'view.helpers.long_walk'
local ADJACENCY     = require 'view.helpers.adjacency'
local INPUT         = require 'input'
local DEFS          = require 'domain.definitions'
local VIEWDEFS      = require 'view.definitions'
local HandView      = require 'view.gameplay.actionhud.hand'
local Minimap       = require 'view.gameplay.actionhud.minimap'
local EquipmentDock = require 'view.gameplay.actionhud.equipmentdock'
local ConditionDock = require 'view.gameplay.actionhud.conditiondock'
local FocusBar      = require 'view.gameplay.actionhud.focusbar'
local CardView      = require 'view.card'
local Util          = require "steaming.util"
local Class         = require "steaming.extra_libs.hump.class"
local ELEMENT       = require "steaming.classes.primitives.element"

local _INFO_LAG = 0.65 -- seconds
local _MARGIN = 20

local ActionHUD = Class{
  __includes = { ELEMENT }
}

-- [[ Constant Variables ]]--

ActionHUD.INTERFACE_COMMANDS = {
  INSPECT_MENU = "INSPECT_MENU",
  SAVE_QUIT = "SAVE_QUIT",
}

--[[ Basic methods ]]--

function ActionHUD:init(route)

  ELEMENT.init(self)

  self.route = route

  local W, _ = VIEWDEFS.VIEWPORT_DIMENSIONS()

  -- Hand view
  self.handview = HandView(route)
  self.handview:register("HUD_BG", nil, "hand_view")

  local margin, off = 20, 20

  -- Wieldable dock
  self.wielddock = EquipmentDock(W/5 - EquipmentDock.getWidth()/2 - margin/2 + off)
  self.wielddock:register("HUD")

  -- Wearable dock
  self.weardock = EquipmentDock(W/5 + EquipmentDock.getWidth()/2 + margin/2 + off)
  self.weardock:register("HUD")

  -- Conditions dock
  self.conddock = ConditionDock(4*W/5 + 15)
  self.conddock:register("HUD_BG")

  self:_loadDocks()

  -- Minimap
  local size = 192
  self.minimap = Minimap(route, W - _MARGIN - size, _MARGIN, size, size)
  self.minimap:register("HUD_BG", nil, "minimap")

  -- HUD state (player turn or not)
  self.player_turn = false
  self.player_focused = false

  -- Card info
  self.info_lag = false

  -- Focus bar
  self.focusbar = FocusBar(route, self.handview)
  self.focusbar:register("HUD")

  -- Long walk variables
  self.alert = false
  self.long_walk = false
  self.adjacency = {}
  ADJACENCY.unset(self.adjacency)
end

function ActionHUD:_loadDocks()
  local player = assert(self.route.getPlayerActor())
  for _, widget in player:getBody():eachWidget() do
    local cardview = CardView(widget)
    local dock = self:getDockFor(widget)
    local pos = dock:getAvailableSlotPosition()
    local mode = dock:getCardMode()
    cardview:register('HUD_FX')
    cardview:setMode(mode)
    cardview.position = pos
    dock:addCard(cardview)
  end
end

function ActionHUD:destroy()
  self.handview:destroy()
  self.focusbar:destroy()
  self.wielddock:destroy()
  self.weardock:destroy()
  self.conddock:destroy()
  self.minimap:destroy()
  ELEMENT.destroy(self)
end

function ActionHUD:activateAbility()
  self.handview:keepFocusedCard(true)
end

function ActionHUD:enableTurn()
  self.player_turn = true
end

function ActionHUD:disableTurn()
  self.player_turn = false
end

function ActionHUD:getHandView()
  return self.handview
end

function ActionHUD:disableCardInfo()
  self.handview.cardinfo:hide()
  self.info_lag = false
end

function ActionHUD:enableCardInfo()
  self.info_lag = self.info_lag or 0
end

function ActionHUD:isHandActive()
  return self.handview:isActive()
end

function ActionHUD:moveHandFocus(dir)
  self.handview:moveFocus(dir)
  self:resetCardInfoLag()
end

function ActionHUD:resetCardInfoLag()
  if self.info_lag then
    self.info_lag = 0
    self.handview.cardinfo:hide()
  end
end

function ActionHUD:sendAlert(flag)
  self.alert = self.alert or flag
end

function ActionHUD:getDockFor(card)
  if card:isWidget() then
    if card:isEquipment() then
      local placement = card:getWidgetPlacement()
      if placement == "wieldable" then
        return self.wielddock
      elseif placement == "wearable" then
        return self.weardock
      else
        return error("unknown equipment placement: ".. placement)
      end
    else
      return self.conddock
    end
  end
end

function ActionHUD:getWidgetCard(card)
  if self.weardock:getCard() and
     self.weardock:getCard().card == card then
    return self.weardock:getCard()
  end
  if self.wielddock:getCard() and
     self.wielddock:getCard().card == card then
      return self.wielddock:getCard()
  end
  for i = 1, self.conddock:getConditionsCount() do
    local condition = self.conddock:getCard(i)
    if condition and
       condition.card == card then
        return condition
    end
  end

  return error("Couldn't find widget")
end

function ActionHUD:removeWidgetCard(card)
  if self.weardock:getCard() and
     self.weardock:getCard().card == card then
    return self.weardock:removeCard()
  end
  if self.wielddock:getCard() and
     self.wielddock:getCard().card == card then
      return self.wielddock:removeCard()
  end
  for i = 1, self.conddock:getConditionsCount() do
    local condition = self.conddock:getCard(i)
    if condition and
       condition.card == card then
        return self.conddock:removeCard(i)
    end
  end

  return error("Couldn't find widget")
end

--[[ INPUT methods ]]--

function ActionHUD:wasAnyPressed()
  return INPUT.wasAnyPressed()
end

local _HAND_FOCUS_DIR = { LEFT = true, RIGHT = true }

function ActionHUD:actionRequested()
  if INPUT.wasActionPressed('SPECIAL') then
    self.player_focused = not self.player_focused
    return false
  end
  local action_request
  local player_focused = self.player_focused
  local dir = DIRECTIONALS.hasDirectionTriggered()
  if player_focused then
    if dir and _HAND_FOCUS_DIR[dir] then
      self:moveHandFocus(dir)
    end
  else
    if LONG_WALK.isAllowed(self) then
      local dir_down = DIRECTIONALS.getDirectionDown()
      if dir_down ~= self.long_walk then
        LONG_WALK.start(self, dir_down)
      else
        self.alert = true
      end
    elseif dir then
      action_request = {DEFS.ACTION.MOVE, dir}
    end
  end

  if INPUT.wasActionPressed('CONFIRM') then
    if player_focused then
      local card_index = self.handview:getFocus()
      if card_index > 0 then
        action_request = {DEFS.ACTION.PLAY_CARD, card_index}
      end
    else
      action_request = {DEFS.ACTION.INTERACT}
    end
  elseif INPUT.wasActionPressed('CANCEL') then
    if player_focused then
      self.player_focused = false
      return
    else
      action_request = {DEFS.ACTION.IDLE}
    end
  elseif INPUT.wasActionPressed('MENU') then
    if player_focused then
      local card_index = self.handview:getFocus()
      if card_index > 0 then
        action_request = {DEFS.ACTION.DISCARD_CARD, card_index}
      end
    else
      action_request = {DEFS.ACTION.RECEIVE_PACK}
    end
  elseif INPUT.wasActionPressed('PAUSE') then
    action_request = {ActionHUD.INTERFACE_COMMANDS.SAVE_QUIT}
  elseif INPUT.wasActionPressed('HELP') then
    local control_hints = Util.findSubtype("control_hints")
    if control_hints then
      for button in pairs(control_hints) do
          button:toggleShow()
      end
    end
  end

  -- choose action
  if self.long_walk then
    if not action_request and LONG_WALK.continue(self) then
      action_request = {DEFS.ACTION.MOVE, self.long_walk}
    else
      self.long_walk = false
    end
  end

  if action_request then
    if action_request[1] ~= DEFS.ACTION.PLAY_CARD then
      self:resetCardInfoLag()
    end
    return unpack(action_request)
  end

  return false
end

--[[ Update ]]--

local function _disableHUDElements(self)
  --self:disableCardInfo()
  if self.handview:isActive() then
    self.handview:deactivate()
  end
end

function ActionHUD:update(dt)
  self.minimap:update(dt)

  -- Input alerts long walk
  if INPUT.wasAnyPressed(0.5) then
    self.alert = true
  end

  if self.player_turn then
    if self.player_focused then
      self.focusbar:show()
      self:enableCardInfo()
      if not self.handview:isActive() then
        self.handview:activate()
      end
    else
      self.focusbar:hide()
      self:disableCardInfo()
      _disableHUDElements(self)
    end
  else
    _disableHUDElements(self)
  end

  -- If card info is enabled
  if self.info_lag then
    self.info_lag = math.min(_INFO_LAG, self.info_lag + dt)

    if self.info_lag >= _INFO_LAG
       and not self.handview.cardinfo:isVisible() then
      self.handview.cardinfo:show()
    end
  end

end

return ActionHUD
