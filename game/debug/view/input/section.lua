
local IMGUI = require 'imgui'
local INPUT = require 'debug.view.input'
local DB    = require 'database'

local _inputs = {}

function _inputs.section(spec, key)

  local schema = require('domain.' .. key.schema).schema
  local backup = {}

  return function(self)
    local element = spec[key.id]
    local enabled
    enabled = select(2, IMGUI.Checkbox(key.name, not not element))
    if not element and (enabled or key.required) then
      element = backup
    elseif element and not enabled and not key.required then
      backup = element
      element = false
    end
    if element then
      IMGUI.Indent(20)
      for _,subkey in ipairs(schema) do
        INPUT(subkey.type, element, subkey)(self)
      end
      IMGUI.Unindent(20)
    end
    spec[key.id] = element
  end
end

return _inputs
