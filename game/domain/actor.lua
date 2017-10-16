
local GameElement = require 'domain.gameelement'
local DB          = require 'database'
local Card        = require 'domain.card'
local ACTION      = require 'domain.action'
local RANDOM      = require 'common.random'
local DEFS        = require 'domain.definitions'
local PLACEMENTS  = require 'domain.definitions.placements'
local PACK        = require 'domain.pack'

local Actor = Class{
  __includes = { GameElement }
}

local BASE_ACTIONS = {
  IDLE = true,
  MOVE = true,
  INTERACT = true,
  NEW_HAND = true,
  RECALL_CARD = true,
  CONSUME_CARD = true,
  GET_PACK_CARD = true,
  CONSUME_PACK_CARD = true
}

--[[ Setup methods ]]--

function Actor:init(spec_name)

  GameElement.init(self, 'actor', spec_name)

  self.behavior = require('domain.behaviors.' .. self:getSpec 'behavior')

  self.body_id = nil
  self.cooldown = DEFS.TIME_UNIT
  self.actions = setmetatable({ PRIMARY = self:getSpec('primary') },
                              { __index = BASE_ACTIONS })


  self.equipped = {}
  for placement in ipairs(PLACEMENTS) do
    self.equipped[placement] = false
  end

  self.widgets = {}
  for _,slot in pairs(DEFS.WIDGETS) do
    self.widgets[slot] = false
  end
  self.hand = {}
  self.hand_limit = 5
  self.upgrades = {
    ATH = 0,
    ARC = 0,
    MEC = 0,
    SPD = 0,
  }
  self.exp = 0
  self.pack = nil

  self.buffers = {}
  for i=1,self:getBufferCount() do
    self.buffers[i] = {{},{}, current = 1}
  end

end

function Actor:loadState(state)
  self.cooldown = state.cooldown
  self.body_id = state.body_id
  self:setId(state.id)
  self.exp = state.exp
  self.upgrades = state.upgrades
  self.hand_limit = state.hand_limit
  self.equipped = state.equipped
  self.hand = {}
  for _,card_state in ipairs(state.hand) do
    local card = Card(card_state.specname)
    card:loadState(card_state)
    table.insert(self.hand, card)
  end
  self.widgets = {}
  for slot, card_state in pairs(state.widgets) do
    if card_state then
      local card = Card(card_state.specname)
      card:loadState(card_state)
      self.widgets[slot] = card
    else
      self.widgets[slot] = false
    end
  end
  self.buffers = {}
  for i=1,self:getBufferCount() do
    local buffer_state = state.buffers[i]
    local buffer = {}
    for j,card_name in ipairs(state.buffers[i]) do
      buffer[j] = card_name
    end
    self.buffers[i] = buffer
  end
  self.last_buffer = state.last_buffer
end

function Actor:saveState()
  local state = {}
  state.specname = self.specname
  state.cooldown = self.cooldown
  state.body_id = self.body_id
  state.id = self.id
  state.exp = self.exp
  state.upgrades = self.upgrades
  state.equipped = self.equipped
  state.hand_limit = self.hand_limit
  state.hand = {}
  for _,card in ipairs(self.hand) do
    local card_state = card:saveState()
    table.insert(state.hand, card_state)
  end
  state.widgets = {}
  for slot, card in pairs(self.widgets) do
    if card then
      local card_state = card:saveState()
      state.widgets[slot] = card_state
    else
      state.widgets[slot] = false
    end
  end
  state.buffers = {}
  for i=1,self:getBufferCount() do
    local buffer = self.buffers[i]
    local buffer_state = {}
    for k,card_name in ipairs(self.buffers[i]) do
      buffer_state[k] = card_name
    end
    state.buffers[i] = buffer_state
  end
  state.last_buffer = self.last_buffer
  return state
end

--[[ Spec methods ]]--

function Actor:isPlayer()
  return self:getSpec('behavior') == 'player'
end

function Actor:getBasicCollection()
  return self:getSpec('collection')
end

function Actor:getExp()
  return self.exp
end

function Actor:modifyExpBy(n)
  self.exp = math.max(0, self.exp + n)
end

function Actor:getBufferCount()
  return self:getSpec('buf_qnt')
end

function Actor:getATH()
  return self:getSpec('ath') + self.upgrades.ATH
end

function Actor:upgradeATH(n)
  self.upgrades.ATH = self.upgrades.ATH + n
end

function Actor:getARC()
  return self:getSpec('arc') + self.upgrades.ARC
end

function Actor:upgradeARC(n)
  self.upgrades.ARC = self.upgrades.ARC + n
end

function Actor:getMEC()
  return self:getSpec('mec') + self.upgrades.MEC
end

function Actor:upgradeMEC(n)
  self.upgrades.MEC = self.upgrades.MEC + n
end

function Actor:getSPD()
  return self:getSpec('spd') + self.upgrades.SPD
end

function Actor:isEquipped(place)
  if not place then return end
  return self.equipped[place]
end

function Actor:equip(place, slot)
  if not place then return end
  -- check if placement is being used
  -- if it is, then remove card from that slot
  -- FIXME: put card back on buffer
  local equipped_slot = self:isEquipped(place)
  if equipped_slot then self:clearSlot(equipped_slot) end
  -- equip new thing on slot
  self.equipped[place] = slot
end

function Actor:unequip(place)
  if not place then return end
  self.equipped[place] = false
end

function Actor:isSlotOccupied(slot)
  return not not self.widgets[slot]
end

function Actor:clearSlot(slot)
  local card = self.widgets[slot]
  local placement = card:getWidgetPlacement()
  self:unequip(placement)
  self.widgets[slot] = false
end

function Actor:setSlot(slot, card)
  if self:isSlotOccupied(slot) then
    self:clearSlot(slot)
  end
  local placement = card:getWidgetPlacement()
  self:equip(placement, slot)
  self.widgets[slot] = card
end

function Actor:getWidgetNameAt(slot)
  local card = self.widgets[slot]
  if card then return card:getName() end
end

function Actor:spendWidget(slot)
  local card = self.widgets[slot]
  if card then
    card:addUsages()
    if card:isSpent() then
      self:clearSlot(slot)
    end
  end
end

--[[ Body methods ]]--

function Actor:setBody(body_id)
  self.body_id = body_id
end

function Actor:getBody()
  return Util.findId(self.body_id)
end

function Actor:getPos()
  return self:getBody():getPos()
end

--[[ Action methods ]]--

function Actor:isWidget(slot)
  return type(slot) == 'string'
         and slot:match("^WIDGET_")
end

function Actor:isCard(slot)
  return type(slot) == 'number'
end

function Actor:getAction(slot)
  if self.actions[slot] then
    if slot == 'PRIMARY' then
      return self.actions[slot]
    else
      return slot
    end
  elseif self.widgets[slot] then
    return self.widgets[slot]:getWidgetAction()
  elseif self:isCard(slot) then
    local card = self.hand[slot]
    if card then
      if card:isArt() then
        return card:getArtAction()
      elseif card:isUpgrade() then
        local cost = card:getUpgradeCost()
        if self.exp >= cost then
          return 'UPGRADE', {
            list = card:getUpgradesList(),
            ["exp-cost"] = cost
          }
        end
      elseif card:isWidget() then
        return 'PLACE_WIDGET', {
          card = card
        }
      end
    end
  end
end

function Actor:setAction(name, id)
  self.actions[name] = id
end

--[[ Card methods ]]--

function Actor:getHand()
  return self.hand
end

function Actor:isHandEmpty()
  return #self.hand == 0
end

function Actor:getBufferSize(which)
  which = which or self.last_buffer
  for i,card in ipairs(self.buffers[which]) do
    if card == DEFS.DONE then
      return i-1
    end
  end
end

function Actor:getBackBufferSize(which)
  which = which or self.last_buffer
  for i,card in ipairs(self.buffers[which]) do
    if card == DEFS.DONE then
      return #self.buffers[which] - i
    end
  end
end

function Actor:isBufferEmpty(which)
  which = which or self.last_buffer
  return #self.buffers[which] == 1
end

function Actor:getHandLimit()
  return self.hand_limit
end

--- Draw a card from actor's buffer
function Actor:drawCard(which)
  if #self.hand >= self.hand_limit then return end
  which = which or self.last_buffer
  -- Empty buffer
  if self:isBufferEmpty(which) then return end

  local card_name = self.buffers[which][1]
  table.remove(self.buffers[which], 1)
  if card_name == DEFS.DONE then
    RANDOM.shuffle(self.buffers[which])
    table.insert(self.buffers[which], DEFS.DONE)
    card_name = self.buffers[which][1]
    table.remove(self.buffers[which], 1)
  end
  local card = Card(card_name)
  table.insert(self.hand, card)
  self.last_buffer = which
  Signal.emit("actor_draw", self, card)
end

function Actor:getHandCard(index)
  assert(index >= 1 and index <= #self.hand)
  return self.hand[index]
end

function Actor:removeHandCard(index)
  assert(index >= 1 and index <= #self.hand)
  table.remove(self.hand, index)
end

function Actor:addCardToBackbuffer(card, buffer_idx)
  assert(buffer_idx >= 0 and buffer_idx <= self:getBufferCount())
  if buffer_idx == 0 then
    buffer_idx = self.last_buffer
  end
  local buffer = self.buffers[buffer_idx]
  table.insert(buffer, card:getSpecName())
end

function Actor:consumeCard(card)
  --FIXME: add card rarity modifier!
  self.exp = self.exp + DEFS.CONSUME_EXP
end

function Actor:hasOpenPack()
  return not not self.pack
end

function Actor:openPack()
  assert(not self.pack)
  self.pack = PACK.open(self:getBasicCollection())
end

function Actor:iteratePack()
  assert(self.pack)
  return ipairs(self.pack)
end

function Actor:getPackCard(idx)
  assert(self.pack)
  assert(idx >= 1 and idx <= #self.pack)
  return Card(self.pack[idx])
end

function Actor:removePackCard(idx)
  assert(self.pack)
  assert(idx >= 1 and idx <= #self.pack)
  table.remove(self.pack, idx)
  if #self.pack == 0 then
    self.pack = nil
  end
end

--[[ Turn methods ]]--

function Actor:tick()
  self.cooldown = math.max(0, self.cooldown - self:getSPD())
end

function Actor:ready()
  return self:getBody():isAlive() and self.cooldown <= 0
end

local function _interact(self)
  local action, params
  local sector = self:getBody():getSector()
  local i, j = self:getPos()
  local id, exit = sector:findExit(i, j, true)
  if id then
    action = 'CHANGE_SECTOR'
    params = { sector = exit.id, pos = exit.target_pos }
  end
  return action, params
end

function Actor:makeAction(sector)
  local success = false
  repeat
    local action_slot, params = self:behavior(sector)
    local check, extra = self:getAction(action_slot)
    if extra then
      -- merge extra onto params
      for k,v in pairs(extra) do
        params[k] = v
      end
    end
    if check then
      local action
      if action_slot == 'INTERACT' then
        action, params = _interact(self)
      else
        action = check
      end
      if self:isCard(action_slot) then
        table.remove(self.hand, action_slot)
      elseif self:isWidget(action_slot) then
        self:spendWidget(action_slot)
      end
      if action then
        success = ACTION.run(action, self, sector, params)
      end
    end
  until success
  return true
end

function Actor:spendTime(n)
  self.cooldown = self.cooldown + n
end

return Actor
