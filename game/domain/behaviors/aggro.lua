
local DIR = require 'domain.definitions.dir'
local Action = require 'domain.action'
local TILE = require 'common.tile'
local Heap = require 'common.heap'

local function _hash(pos)
  if not pos then return "none" end
  return string.format("%d:%d", unpack(pos))
end

local function _findPath(start, goal, sector)
  local frontier = Heap:new()
  local came_from = {}
  local cost_so_far = {}
  local path = {}
  local found = false

  frontier:add(start, 0)
  came_from[_hash(start)] = true
  cost_so_far[_hash(start)] = 0

  while not frontier:isEmpty() do
    local current, rank = frontier:getNext()

    -- if you found your goal, quit loop
    if TILE.distUniform(goal[1], goal[2], unpack(current)) == 1 then
      found = true
      goal = current
      break
    end

    -- look at neighbors
    for n = 1, 4 do
      local i, j = unpack(current)
      local ti, tj = unpack(goal)
      local di, dj = unpack(DIR[DIR[n]])
      local next_pos = { i+di, j+dj }
      if sector:isValid(unpack(next_pos)) then
        local new_cost = cost_so_far[_hash(current)] + 1

        -- is it a valid and not yet checked neighbor?
        if not cost_so_far[_hash(next_pos)]
          or new_cost < cost_so_far[_hash(next_pos)] then
          local new_rank = new_cost + TILE.dist(ti, tj, unpack(next_pos))
          cost_so_far[_hash(next_pos)] = new_cost
          came_from[_hash(next_pos)] = current
          frontier:add(next_pos, new_rank)
        end
      end
    end
  end

  local current = goal
  if found then
    while _hash(start) ~= _hash(current) do
      table.insert(path, current)
      current = came_from[_hash(current)]
    end
    return path[#path]
  end
  return false
end

return function (actor, sector)
  local actorlist = sector:getActors()
  local target, dist
  local i, j = actor:getPos()

  -- create list of opponents
  for _,opponent in ipairs(actorlist) do
    if opponent:isPlayer() then
      local k, l = opponent:getPos()
      local d = TILE.distUniform(i, j, k, l)
      if not target or not dist or d < dist then
        target = opponent
        dist = d
      end
    end
  end

  if dist == 1 then
    -- attack if close!
    return 'PRIMARY', { target = {target:getPos()} }
  elseif dist <= 8 then
    -- chase if far away!
    local start = os.clock()
    local pos = _findPath({i,j}, {target:getPos()}, sector)
    print(("%.10f"):format(os.clock() - start))
    if pos then
      return 'MOVE', { pos = pos }
    end
  end

  return 'IDLE', {}
end

