
local DB = require 'database'
local RES = require 'resources'
local COLORS = require 'domain.definitions.colors'

local PickWidgetView = Class{
  __includes = { ELEMENT }
}

local _FONT_SIZE = 24
local _BLOCK_HEIGHT = 48
local _MARGIN = 16
local _PADDING = 4
local _FMT = "SLOT #%d: %s"

local _width, _height
local _font, _text_width, _pd
local _alpha

local function _initGraphicValues()
  local g = love.graphics
  _width, _height = g.getDimensions()
  _font = function () g.setFont(RES.loadFont("Text", _FONT_SIZE)) end
  _text_width = _width/4
end

function PickWidgetView:init(target_actor)
  ELEMENT.init(self)

  self.target = target_actor
  self.selection = 1
  self.alpha = 0

  _initGraphicValues()
end

function PickWidgetView:setSelection(n)
  self.selection = n
end

function PickWidgetView:draw()
  local g = love.graphics
  g.setColor(0, 0, 0, self.alpha*0x80)
  g.rectangle("fill", 0, 0, _width, _height)
  g.push()

  g.translate(_width/8, _height/2-2*(_BLOCK_HEIGHT+_MARGIN))
  -- draw stuff
  for slot, cardspec in self.target:allSlots() do
    local name, pd
    if not cardspec then
      name = "[ EMPTY ]"
    else
      name = self.target:getWidgetNameAt(slot)
    end
    if self.selection == slot then
      g.setColor(0xff, 0xff, 0xff, self.alpha*0xff)
    else
      g.setColor(0x16, 0x16, 0x16, self.alpha*0xff)
    end
    g.rectangle("fill", 0, 0, _text_width, _BLOCK_HEIGHT)
    _font()
    if self.selection == slot then
      g.setColor(0x00, 0x00, 0x00, self.alpha*0xff)
    else
      g.setColor(0xff, 0xff, 0xff, self.alpha*0xff)
    end
    g.print(_FMT:format(slot, name), 4*_PADDING, _PADDING)
    g.translate(0, _BLOCK_HEIGHT + _MARGIN)
  end

  g.pop()
end

function PickWidgetView:fadeOut()
  self:removeTimer("widget_picker_fade", MAIN_TIMER)
  self:addTimer("widget_picker_fade", MAIN_TIMER, "tween",
                 .2, self, { alpha = 0 }, "out-quad",
                 function () self:destroy() end)
end

function PickWidgetView:fadeIn()
  self:removeTimer("widget_picker_fade", MAIN_TIMER)
  self:addTimer("widget_picker_fade", MAIN_TIMER, "tween",
                .25, self, { alpha = 1 }, "out-quad")
end

return PickWidgetView

