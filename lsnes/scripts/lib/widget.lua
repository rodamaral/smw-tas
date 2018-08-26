local M = {}

local draw = require 'draw'
local keyinput = require 'keyinput'

M.all_widgets = {} -- table of names

function M:new(name, x, y, symbol)
  self.all_widgets[name] = {
    name = name,
    x = x or 0,
    y = y or 0,
    symbol = symbol or true,  -- the display object that is passed to draw.button
    display_flag = false,
  }
end

function M:exists(name)
  return self.all_widgets[name] and true or false
end

function M:get_property(name, property)
  local object = self.all_widgets[name]

  return object[property]
end

function M:set_property(name, property, value)
  local object = self.all_widgets[name]

  object[property] = value
end

function M:display_all()
  if keyinput.key_state.mouse_inwindow == 1 then
    for name, object in pairs(self.all_widgets) do
        if object.display_flag then
          draw.button(draw.AR_x * object.x, draw.AR_y * object.y, object.symbol, function()
            self.left_mouse_dragging = true
            self.selected_object = name
          end)
      end
    end
  end
end

function M:drag_widget()
  if self.left_mouse_dragging then
    local object = self.all_widgets[self.selected_object]
    object.x = math.floor(keyinput.key_state.mouse_x/draw.AR_x)
    object.y = math.floor(keyinput.key_state.mouse_y/draw.AR_y)
  end
end

return M
