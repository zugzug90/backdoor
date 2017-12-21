
local INPUT        = require 'input'
local DIRECTIONALS = require 'infra.dir'
local DIR          = require 'domain.definitions.dir'
local state = {}

local _sector_view
local _current_dir
local _body_block

local function _updateDir(dir)
  _current_dir = DIR[dir]
  _sector_view:setRayDir(_current_dir, _body_block)
end

function state:enter(prev, sector_view, body_block)
  _sector_view = sector_view
  _body_block = body_block
  _updateDir(DIR[1])
end

function state:update(dt)
  MAIN_TIMER:update(dt)

  if INPUT.wasActionPressed('CONFIRM') then
    _sector_view:setRayDir()
    SWITCHER.pop(_current_dir)
  elseif INPUT.wasActionPressed('CANCEL') then
    _sector_view:setRayDir()
    SWITCHER.pop()
  else
    for _,dir in ipairs(DIR) do
      if DIRECTIONALS.wasDirectionTriggered(dir) then
        _updateDir(dir)
      end
    end
  end
end

function state:draw()
  Draw.allTables()
end

return state
