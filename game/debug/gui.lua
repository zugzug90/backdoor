
local GUI = Class {
  __includes = { ELEMENT }
}

function GUI:init(map)

  ELEMENT.init(self)
  self.map = map
  self.shown_actors = {}

end

function GUI:draw()
  if not DEBUG then return end
  local g = love.graphics

  imgui.NewFrame()

  imgui.SetNextWindowPos(50, 50, "FirstUseEver")
  imgui.SetNextWindowSizeConstraints(200, 10, 200, 400)
  imgui.Begin("Actors", true, { "NoCollapse" })
  for actor,_ in pairs(Util.findSubtype 'actor') do
    if imgui.Button(actor.id) then
      self.shown_actors[actor] = not self.shown_actors[actor]
    end
  end
  imgui.End()

  for actor,show in pairs(self.shown_actors) do
    if show then
      imgui.SetNextWindowSizeConstraints(200, 10, 200, 400)
      imgui.Begin(actor.id, false, { "AlwaysAutoResize" })
      imgui.Text(("HP: %d"):format(actor:getBody():getHP()))
      imgui.End()
    end
  end

  g.setBackgroundColor(50, 80, 80, 255)
  g.setColor(255, 255, 255)
  imgui.Render()
end

return GUI
