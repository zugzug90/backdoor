
local FX = {}

FX.schema = {
  { id = 'target', name = "Target", type = 'value/body' },
  { id = 'amount', name = "Damage amount", type = 'value/integer',
    range = {0,999} },
}

function FX.process (actor, sector, params)
  params.target:takeDamage(params.amount or 2)
end

return FX

