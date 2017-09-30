
local json = require 'dkjson'
local SCHEMA = require 'lux.pack' 'database.schema'

local DB = {}

local _dbcache = {}
local _subschemas = {}

local function _fullpath(relpath)
  local srcpath = love.filesystem.getSource()
  return ("%s/%s"):format(srcpath, relpath)
end

function _loadSubschema(base)
  local fs = love.filesystem
  local sub = _subschemas[base]
  if not sub then
    sub = {}
    for _,file in ipairs(fs.getDirectoryItems("domain/" .. base)) do
      if file:match "^.+%.lua$" then
        file = file:gsub("%.lua", "")
        sub[file] = require('domain.' .. base .. '.' .. file).schema
        table.insert(sub, file)
      end
    end
    _subschemas[base] = sub
  end
  return sub
end

function _subschemaFor(base, branch)
  return _loadSubschema(base)[branch]
end

local function _loadGroup(category, group_name)
  return _dbcache[category][group_name]
end

local function _loadDomainGroup(group)
  return _loadGroup('domains', group)
end

local function _loadResourceGroup(group)
  return _loadGroup('resources', group)
end

local function _loadSetting(setting)
  return _loadGroup('settings', setting)
end

local function _loadFile(relpath)
  local file = assert(io.open(_fullpath(relpath), 'r'))
  local data, _, err = json.decode(file:read('*a'))
  file:close()
  return assert(data, err)
end

local function _writeFile(relpath, rawdata)
  local file = assert(io.open(_fullpath(relpath), 'w'))
  local data = json.encode(rawdata, {indent = true})
  file:write(data)
  return file:close()
end

local function _save(cache, basepath)
  if getmetatable(cache).group then
    for group, subcache in pairs(cache) do
      local meta = getmetatable(subcache) or {}
      local item = meta.group or group
      local newbasepath = basepath.."/"..item
      _save(subcache, newbasepath)
    end
  else
    local filepath = basepath..".json"
    _writeFile(filepath, cache)
  end
end

local function _metaSpec(container)
  return {
    is_leaf = true,
    __index = function(self, key)
      local extends = rawget(self, "extends")
      if extends then
        return container[extends][key]
      end
    end
  }
end

function DB.initSpec(spec, container)
  return setmetatable(spec, _metaSpec(container))
end

function DB.subschemaTypes(base)
  return ipairs(_loadSubschema(base))
end

function DB.schemaFor(domain_name)
  local base, branch = domain_name:match('^(.+)/(.+)$')
  if base and branch then
    return ipairs(_subschemaFor(base, branch))
  else
    return ipairs(SCHEMA[domain_name])
  end
end

function DB.loadDomain(name)
  return _loadDomainGroup(name)
end

function DB.loadSpec(domain_name, spec_name)
  return DB.loadDomain(domain_name)[spec_name]
end

function DB.loadSetting(setting_name)
  return _loadSetting(setting_name)
end

function DB.loadResource(res_type, res_name)
  return _loadResourceGroup(res_type)[res_name]
end

function DB.loadResourcePath(res_type, res_name)
  local path = "assets/%s/%s"
  local filename = DB.loadResource(res_type, res_name).filename
  return path:format(res_type, filename)
end

function DB.save()
  local basepath = getmetatable(_dbcache).relpath
  _save(_dbcache, basepath)
end

function DB.init()
  local fs = love.filesystem
  local function get(self, key)
    local path = ("%s/%s"):format(getmetatable(self).relpath, key)
    local meta = {relpath = path, group = key}
    local obj = setmetatable({}, meta)

    -- if directory
    if fs.isDirectory(path) then
      meta.__index = get
      self[key] = obj
      return obj
    end

    -- if json file
    local filepath = path..".json"
    if fs.exists(filepath) then
      obj = _loadFile(filepath)
      DB.initSpec(obj, self)
      self[key] = obj
      return obj
    end
  end
  local meta = {
    relpath = "database",
    group = "database",
    __index = get,
  }
  setmetatable(_dbcache, meta)
end

return DB

