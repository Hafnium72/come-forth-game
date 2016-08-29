local config = require "config"

local tiled = require "lib.levels.tiled"
local layer = require "lib.levels.layer"
local tiles = require "lib.tiles"
local vector = require "lib.vector"

local entity_handlers = require "lib.levels.entity_handlers"

local level = {} ; level.__index = level 

function level.new (map_data) 
    local self = setmetatable({}, level)
    
    self.width = map_data.width
    self.height = map_data.height
    
    self.layers = {
      walls       = layer.new(tiled.getLayerData(map_data, "walls")),
      platforms   = layer.new(tiled.getLayerData(map_data, "platforms")),
      background  = layer.new(tiled.getLayerData(map_data, "background"))
    }
    
    self.objects = {}
    
    local object_layer = tiled.getLayerData(map_data, "objects")
    
    for k, object in ipairs(object_layer.objects) do
      self.objects[#self.objects + 1] = object
    end
    
    return self
end

function level:initialize (env)
  assert(env.level == self) -- sanity check
  
  for i, object in pairs(self.objects) do
    if entity_handlers[object.type] then
      entity_handlers[object.type](env, object)
    else
      print('no handler for level object type ' .. tostring(object.type))
    end
  end
end

function level:getObjectByName (object_name)
  for i, object in ipairs(self.objects) do
    if object.name == object_name then
      return object
    end
  end
  
  error('no object with name: ' .. object_name)
end

function level:getObjectById (object_id)
  for i, object in ipairs(self.objects) do
    if object.id == object_id then
      return object
    end
  end
  
  error('no object with id: ' .. object_id)
end

function level:getObject (id_or_name)  
  if type(id_or_name) == 'string' then
    return self:getObjectByName(id_or_name)
  elseif type(id_or_name) == 'number' then
    return self:getObjectById(id_or_name)
  else
    error('expected string name or number id; found ' .. type(id_or_name))
  end
end

function level:getTilemap () 
  local tileset_image = love.graphics.newImage("res/art/tileset.png")
  tileset_image:setFilter("nearest", "nearest")
  
  local batch = love.graphics.newSpriteBatch(tileset_image, self.width * self.height * 3 --[[ three layers ]])
  
  for x = 0, self.width - 1 do
    for y = 0, self.height - 1 do
      local background  = self.layers.background:getTile(x, y)
      local platform    = self.layers.platforms:getTile(x, y)
      local wall        = self.layers.walls:getTile(x, y)
      
      if background then batch:add(tiles[background].quad, x * config.tile_size, y * config.tile_size, 0) end
      if platform then batch:add(tiles[platform].quad, x * config.tile_size, y * config.tile_size, 0) end
      if wall then batch:add(tiles[wall].quad, x * config.tile_size, y * config.tile_size, 0) end
    end
  end
  
  return batch
end

return level