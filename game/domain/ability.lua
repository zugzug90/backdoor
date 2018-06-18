
local FX = require 'lux.pack' 'domain.effects'
local OP = require 'lux.pack' 'domain.operators'
local IN = require 'lux.pack' 'domain.inputs'
local DB = require 'database'

local _CMDTYPES = {
  effect = FX,
  inputs = IN,
  operators = OP
}

local function _unref(ref, values)
  if type(ref) == 'string' then
    local n = ref:match '=(.+)'
    if n then
      return values[n]
    end
  end
  return ref
end

local ABILITY = {}

function ABILITY.inputsOf(ability)
  return ipairs(ability.inputs)
end

function ABILITY.input(input_name)
  return IN[input_name]
end

function ABILITY.validate(input_name, actor, input_fields, value)
  return IN[input_name].isValid(actor, input_fields, value)
end

local function _fields(cmd)
  return DB.schemaFor(cmd.type .. 's/' .. cmd.name)
end

local function _unrefFieldValues(cmd, values)
  local unrefd_field_values = {}
  for _,field in _fields(cmd) do
    unrefd_field_values[field.id] = _unref(cmd[field.id], values)
  end
  return unrefd_field_values
end

function ABILITY.checkInputs(ability, actor, inputvalues)
  local values = {}
  for _,cmd in ipairs(ability.inputs) do
    if cmd.type == 'input' then
      local unrefd_field_values = _unrefFieldValues(cmd, values)
      local inputspec = IN[cmd.name]
      if inputspec.isValid(actor, unrefd_field_values,
                           inputvalues[cmd.output]) then
        if cmd.output then
          values[cmd.output] = inputvalues[cmd.output]
        end
      else
        return false
      end
    end
  end
  return true
end

local _CMDLISTS = { 'inputs', 'effects' }

function ABILITY.execute(ability, actor, inputvalues)
  local values = {}
  for _,cmdlist in ipairs(_CMDLISTS) do
    for _,cmd in ipairs(ability[cmdlist]) do
      local value
      local type, name = cmd.type, cmd.name
      if type == 'input' then
        value = inputvalues[cmd.output]
      else
        local unrefd_field_values = _unrefFieldValues(cmd, values)
        if type == 'operator' then
          value = OP[name].process(actor, unrefd_field_values)
        elseif type == 'effect' then
          value = FX[name].process(actor, unrefd_field_values)
        else
          return error("Invalid command type")
        end
      end
      if cmd.output then
        values[cmd.output] = value
      end
    end
  end
end

function _NOPREVIEW()
  return nil
end

function ABILITY.preview(ability, actor, inputvalues)
  local values = {}
  local prevs = {}
  for _,cmdlist in ipairs(_CMDLISTS) do
    for _,cmd in ipairs(ability[cmdlist]) do
      local prev, value
      local type, name = cmd.type, cmd.name
      local unrefd_field_values = _unrefFieldValues(cmd, values)
      if type == 'input' then
        value = inputvalues[cmd.output]
      else
        if type == 'operator' then
          value = OP[name].preview
        elseif type == 'effect' then
          prev = FX[name].preview
        else
          return error("Invalid command type")
        end
      end
      if cmd.output and value then
        values[cmd.output] = value(actor, unrefd_field_values)
      end
      local text = (prev or _NOPREVIEW)(actor, unrefd_field_values)
      if text then
        table.insert(values, text)
      end
    end
  end
  return table.concat(values, "\n\n")
end

return ABILITY

