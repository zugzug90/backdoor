
local TILE       = require 'common.tile'
local Action     = require 'domain.action'
local ACTIONDEFS = require 'domain.definitions.action'
local FindPath   = require 'domain.behaviors.helpers.findpath'

return function (actor)
  local target, dist
  local sector = actor:getBody():getSector()
  local i, j = actor:getPos()

  if not actor:hasVisibleBodies() then return ACTIONDEFS.IDLE end

  -- create list of opponents
  for body_id,seen in actor:eachSeenBody() do
    local opponent = Util.findId(body_id)
    if opponent:getFaction() ~= actor:getBody():getFaction() then
      local k, l = opponent:getPos()
      local d = TILE.dist(i, j, k, l)
      if not target or not dist or d < dist then
        target = opponent
        dist = d
      end
    end
  end

  if not dist then
    -- there are not valid targets!
    return ACTIONDEFS.IDLE, {}
  elseif dist == 1 then
    -- attack if close!
    return ACTIONDEFS.USE_SIGNATURE, { pos = {target:getPos()} }
  elseif dist <= 8 then
    -- chase if far away!
    local pos = FindPath.getNextStep({i,j}, {target:getPos()}, sector)
    if pos then
      return ACTIONDEFS.MOVE, { pos = pos }
    end
  end

  -- there are valid targets, but i can't reach them
  return ACTIONDEFS.IDLE, {}
end

