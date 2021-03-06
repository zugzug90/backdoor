
--- Get translated position from pos+dir

local OP = {}

OP.schema = {
  { id = 'pos', name = "Position", type = 'value', match = 'pos' },
  { id = 'dir', name = "Translation", type = 'value', match = 'dir' },
  { id = 'output', name = "Label", type = 'output' }
}

OP.type = 'pos'

function OP.preview(_, fieldvalues)
  local pos = fieldvalues['pos']
  local dir = fieldvalues['dir']
  return ("position in the %s of %s"):format(dir, pos)
end

function OP.process(_, fieldvalues)
  local pos = fieldvalues['pos']
  local dir = fieldvalues['dir']
  return { pos[1]+dir[1], pos[2]+dir[2] }
end

return OP

