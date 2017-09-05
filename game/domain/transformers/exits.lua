
local RANDOM = require 'common.random'
local SCHEMATICS = require 'domain.definitions.schematics'

local transformer = {}

transformer.schema = {
  {
    id = 'exits', name = "Exit", type = 'array', preview = {1},
    schema = {
      {
        id = "target_specname", name = "Target Sector Spec", type = 'enum',
        options = "sector"
      }
    }
  },
}

local function _isPossibleExit(grid, x, y)
  local f = SCHEMATICS.FLOOR
  local e = SCHEMATICS.EXIT
  for dx = -1, 1, 1 do
    for dy = -1, 1, 1 do
      local tx, ty = dx + x, dy + y
      local tile = grid.get(tx, ty)
      -- verify it's a position surrounded by floors and not a single exit
      if tile ~= f or tile == e then return false end
    end
  end
  return true
end

function transformer.process(sectorinfo, params)
  local sectorgrid = sectorinfo.grid
  local exits_specs = params.exits

  local possible_exits = {}
  local chosen_exits = {}

  -- construct list of possible exits
  do
    for x, y, tile in sectorgrid.iterate() do
      if _isPossibleExit(sectorgrid, x, y) then
        table.insert(possible_exits, {y, x})
      end
    end
  end

  -- get a number of random possible exits from that list
  (function()
    local N = #exits_specs -- max number of exits
    for edx = 1, N do
      local i, j
      repeat
        local COUNT = #possible_exits
        if COUNT == 1 then
          -- if there is only one last possible exit, check it:
          i, j = unpack(possible_exits[1])
          -- if it's not a good position, tough luck, break it up
          -- this is why this has to be a lambda
          if not _isPossibleExit(sectorgrid, j, i) then return end
        else
          -- if there are many possible exits, get a random one:
          local idx = RANDOM.generate(1, COUNT)
          i, j = unpack(possible_exits[idx])
          -- remove found position from list of possible exits
          possible_exits[idx] = possible_exits[COUNT]
          possible_exits[COUNT] = nil
        end
        -- repeat until you find a position that:
        -- > is not an exit or around another exit
      until _isPossibleExit(sectorgrid, j, i)
      local exit = {
        pos = {i, j},
        target_specname = exits_specs[edx].target_specname
      }
      -- add exit info to sectorinfo
      -- and set and exit tile on the sectorgrid
      table.insert(chosen_exits, exit)
      sectorgrid.set(j, i, SCHEMATICS.EXIT)
    end
  end)()

  sectorinfo.exits = chosen_exits
  return sectorinfo
end

return transformer

