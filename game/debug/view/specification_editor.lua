
local DB = require 'database'

local spec_item = {}

for _,file in ipairs(love.filesystem.getDirectoryItems "debug/view/input") do
  if file:match "^.+%.lua$" then
    file = file:gsub("%.lua", "")
    for k,input in ipairs(require('debug.view.input.' .. file)) do
      spec_item[k] = input
    end
  end
end

--[[ Invalid input ]]-----------------------------------------------------------

local function _invalid(spec, key)
  return function (self)
    imgui.PushStyleColor("Text", 200, 100, 0, 255)
    imgui.Text(("Unknown input type: %s"):format(key.type))
    imgui.PopStyleColor(1)
  end
end

--[[ Common inputs ]]-----------------------------------------------------------

function spec_item.boolean(spec, key)
  return function (self) 
    local value = spec[key.id] or false
    local changed, newvalue = imgui.Checkbox(key.name, value)
    if changed then
      spec[key.id] = newvalue
    end
  end
end

function spec_item.integer(spec, key)
  return function (self) 
    local value = spec[key.id] or key.range[1]
    local changed, newvalue = imgui.InputInt(key.name, value, 1, 10)
    if changed then
      spec[key.id] = math.max(key.range[1], math.min(key.range[2], newvalue))
    end
  end
end

--[[ Enumerations ]]------------------------------------------------------------

function spec_item.enum(spec, key)
  return function(self)
    -- Build option list from given array or from a database domain
    local options = key.options
    if type(options) == 'string' then
      local domain = DB.loadDomain(options)
      options = {}
      for k,v in pairs(domain) do
        table.insert(options,k)
      end
      table.sort(options)
    end
    -- Find the index of the currently assigned option
    local current = 0
    for i,option in ipairs(options) do
      if option == spec[key.id] then
        current = i
        break
      end
    end
    -- Value getter/setter
    local function value(newvalue)
      if newvalue then
        current = newvalue
        spec[key.id] = options[newvalue]
      else
        return current
      end
    end
    imgui.InputText(key.name, spec[key.id] or "<none>", 64, { "ReadOnly" })
    if imgui.IsItemClicked() then
      self:push("list_picker", key.name, options, value)
    end
  end
end

--[[ List of elements ]]--------------------------------------------------------

function spec_item.list(spec, key)

  local list = spec[key.id] or {}
  local selected = nil
  local typeoptions = {}

  for _,option in DB.subschemaTypes(key.id) do
    table.insert(typeoptions, option)
  end

  local function delete()
    table.remove(list, selected)
  end

  return function(self)
    imgui.Text(("%ss:"):format(key.name))
    imgui.Indent(20)
    for i,element in ipairs(list) do
      local view = ("%2d: %s"):format(i, element.typename)
      if imgui.Selectable(view, selected == i) then
        selected = i
        self:push('specification_editor', element,
                  key.id .. '/' .. element.typename, key.name, delete)
      end
    end
    if imgui.Button("New " .. key.name) then
      self:push(
        'list_picker', key.name, typeoptions,
        function (value)
          if value then
            table.insert(list, { typename = typeoptions[value] })
            return true
          end
          return 0
        end
      )
    end
    imgui.Unindent(20)
  end
end

--[[ Menu rendering ]]----------------------------------------------------------

return function(spec, domain_name, title, delete)

  local inputs = {}
  for _,key in DB.schemaFor(domain_name) do
    local input = spec_item[key.type]
    table.insert(inputs, (input or _invalid)(spec, key) or _invalid())
  end

  return title .. " Editor", 1, function(self)
    imgui.PushItemWidth(120)
    for _,input in ipairs(inputs) do
      input(self)
    end
    imgui.PopItemWidth()
    imgui.Spacing()
    imgui.Indent(180)
    if imgui.Button("Delete") then
      delete()
      return true
    end
    imgui.Unindent(180)
  end

end

