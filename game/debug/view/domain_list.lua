
local IMGUI = require 'imgui'
local DB = require 'database'

local function add(list, value)
  table.insert(list, value)
  list.n = list.n + 1
end

local function sort(list)
  table.sort(list)
end

return function(domain_name, title)

  local domain = DB.loadDomain(domain_name)
  local list = { n = 0 }
  local selected = 0
  for name,spec in pairs(domain) do
    add(list, name)
  end
  sort(list)

  local function delete()
    domain[list[selected]] = nil
    table.remove(list, selected)
    list.n = list.n - 1
  end

  local function newvalue(value, spec)
    local new = spec or DB.initSpec({}, domain_name)
    for _,key in DB.schemaFor(domain_name) do
      if key.type == 'list' then
        new[key.id] = new[key.id] or {}
      end
    end
    domain[value] = new
    add(list, value)
    sort(list)
    for i,v in ipairs(list) do
      if v == value then
        selected = i
      end
    end
  end

  local function rename(value)
    local spec = domain[list[selected]]
    if spec then
      delete()
      newvalue(value, spec)
    end
  end

  return title .. " List", 1, function(self)
    if IMGUI.Button("New "..title) then
      self:push('name_input', title, newvalue)
    end
    IMGUI.Text(("All %ss:"):format(title))
    local changed
    IMGUI.PushItemWidth(208)
    changed, selected = IMGUI.ListBox("", selected, list, list.n, 15)
    IMGUI.PopItemWidth()
    if changed then
      self:push('specification_editor', domain[list[selected]], domain_name,
                title, delete, rename)
    end
  end

end

