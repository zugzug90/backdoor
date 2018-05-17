
local behaviors = love.filesystem.getDirectoryItems("domain/behaviors/")
do
  for i=1, #behaviors do
    behaviors[i] = behaviors[i]:gsub("[.]lua", "")
  end
end

return {
  { id = 'extends', name = "Prototype", type = 'enum', options = 'domains.actor',
    optional = true },
  { id = 'name', name = "Full Name", type = 'string' },
  { id = 'description', name = "Description", type = 'text' },
  { id = 'behavior', name = "Behavior", type = 'enum',
    options = behaviors },
  { id = 'signature', name = "Signature Ability", type = 'enum',
    options = 'domains.action' },
  { id = 'cor', name = "COR", type = 'range', min = -4, max = 4 },
  { id = 'arc', name = "ARC", type = 'range', min = -4, max = 4 },
  { id = 'ani', name = "ANI", type = 'range', min = -4, max = 4 },
  { id = 'spd', name = "SPD", type = 'range', min = -4, max = 4 },
  { id = 'collection', name = "Drops", type = 'enum',
    options = 'domains.collection' },
  { id = 'initial_buffer', name = "Buffer Card", type = 'array',
    schema = {
      { id = 'card', name = "Card", type = 'enum', options = "domains.card" },
      { id = 'amount', name = "Amount", type = 'integer', range = {1,16} },
    }
  },
}
