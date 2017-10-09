
local GameElement = require 'domain.gameelement'

local Card = Class{
  __includes = { GameElement }
}

function Card:init(specname)

  GameElement.init(self, 'card', specname)

end

function Card:getName()
  return self:getSpec('name')
end

function Card:getRelatedAttr()
  return self:getSpec('attr')
end

function Card:isArt()
  return not not self:getSpec('art')
end

function Card:isUpgrade()
  return not not self:getSpec('upgrade')
end

function Card:isWidget()
  return not not self:getSpec('widget')
end

function Card:getArtAction()
  return self:getSpec('art').art_action
end

function Card:getUpgradesList()
  return self:getSpec('upgrade').list
end

function Card:getUpgradeCost()
  return self:getSpec('upgrade').cost
end

function Card:getWidgetAction()
  return self:getSpec('widget').widget_action
end

function Card:getWidgetPlacement()
  return self:getSpec('widget').placement
end

function Card:getWidgetCharges()
  return self:getSpec('widget').charges
end

function Card:getWidgetTrigger()
  return self:getSpec('widget').expend_trigger
end

return Card

