local state    = {}
local Util     = require "steaming.util"
local SWITCHER = require 'infra.switcher'
local FONT     = require 'view.helpers.font'
local COLORS   = require 'domain.definitions.colors'
local VIEWDEFS = require 'view.definitions'
local PROFILE  = require 'infra.profile'
local Draw     = require "draw"

--[[ LOCAL VARIABLES ]]--

local SPEED = 4
local HINTS = {
  open_hand = {
    {
      text = "To activate or deactivate your hand press A",
      region = {x = 400, y = 685, w = 600, h = 80},
      text_pos = {x = 400, y = 640}
    }
  },
  use_card = {
    {
      text = "To use a card press F",
      region = {x = 370, y = 450, w = 530, h = 200},
      text_pos = {x = 150, y = 550}
    },
    {
      text = "You'll need focus to use most cards",
      region = {x = 550, y = 650, w = 250, h = 200},
      text_pos = {x = 400, y = 620}
    },
    {
      text = "Unless the card is consumable,\nit will go to your backbuffer after use",
      region = {x = 1180, y = 560, w = 120, h = 180},
      text_pos = {x = 900, y = 500}
    }
  },
  pp = {
    {
      text = "Food replenishes your \"Play Points\"\n(or PP)",
      region = {x = 0, y = 550, w = 120, h = 180},
      text_pos = {x = 10, y = 520}
    },
    {
      text = "You'll need PP to reshuffle your backbuffer\ninto your buffer when you ran out of cards to draw",
      region = {{x = 1180, y = 560, w = 120, h = 180}, {x = 0, y = 560, w = 120, h = 180}},
      text_pos = {x = 440, y = 620}
    },
  }
}

local _font = FONT.get("Text", 25)
local _hint_data
local _cur_hint
local _alpha
local _leaving

--[[ LOCAL FUNCTIONS ]]--

local stencilFunc

--[[ STATE FUNCTIONS ]]--

function state:enter(_, hint)
  _alpha = 0
  _leaving = false
  PROFILE.setTutorial(hint, true)
  if not HINTS[hint] then
    error("Not a valid hint type: " .. tostring(hint))
  end
  _cur_hint = 1
  _hint_data = HINTS[hint]
end

function state:leave()
  Util.destroyAll()
end

function state:update(dt)
  if not _leaving then
    _alpha = math.min(_alpha + dt*SPEED, 1)
  else
    _alpha = math.max(_alpha - dt*SPEED, 0)
    if _alpha <= 0 then
      SWITCHER:pop()
    end
  end
end

function state:keypressed()
  if _leaving or _alpha < 1.0 then
    return
  end
  if not _hint_data[_cur_hint + 1] then
    _leaving = true
  else
    _cur_hint = _cur_hint + 1
  end
end

function state:draw()
  Draw.allTables()

  local g = love.graphics


  --Draw black filter
  g.stencil(stencilFunc, "replace", 1)
  g.setStencilTest("less", 1)
  local w, h = VIEWDEFS.VIEWPORT_DIMENSIONS()
  g.setColor(0,0,0,.95*_alpha)
  g.rectangle("fill", 0, 0, w, h)
  g.setStencilTest()

  --Draw text
  local c = COLORS.NEUTRAL
  g.setColor(c[1], c[2], c[3], _alpha)
  _font:set()
  local pos = _hint_data[_cur_hint].text_pos
  g.print(_hint_data[_cur_hint].text, pos.x, pos.y - 30)

end

--Local functions

function stencilFunc()
    local g = love.graphics
    local r = _hint_data[_cur_hint].region
    --Multiple regions
    if r[1] and type(r[1]) == "table" then
      for _, region in ipairs(r) do
        g.rectangle("fill", region.x, region.y, region.w, region.h)
      end
    --Only one region
    else
      g.rectangle("fill", r.x, r.y, r.w, r.h)
    end
end

return state
