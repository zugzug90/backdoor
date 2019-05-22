
local RES = require 'resources'
local PROFILE = require 'infra.profile'

local SoundTrack  = require 'lux.class' :new{}

local source  = love.source
local setfenv = setfenv

function SoundTrack:instance(obj)

  setfenv(1, obj)

  local bgm = {}

  function playTheme(theme)
    if not theme then
      error("theme not provided to play")
    end
    if bgm.id ~= theme then
      if bgm.stream then bgm.stream:stop() end
      bgm.stream = RES.loadBGM(theme)
      bgm.stream:play()
      bgm.id = theme
      updateVolume()
    end
  end

  function stopTheme()
    if bgm.stream then
      bgm.stream:stop()
      bgm.stream = nil
    end
  end

  function updateVolume()
    if bgm.stream then
      bgm.stream:setVolume(PROFILE.getPreference("bgm-volume") / 100)
    end
  end

end

return SoundTrack
