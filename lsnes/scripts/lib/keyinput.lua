-- Module for external user input
-- Partially based on this script of the player Fat Rat Knight (FRK)
-- http://tasvideos.org/userfiles/info/5481697172299767

local keyinput = {}
keyinput.key_state = {}
keyinput.key_press = {}
keyinput.key_release = {}

function keyinput.register_key_press(key, fn)
-- key - string. Which key do you wish to bind?
-- fn  - function. To execute on key press. False or nil removes it.
-- Return value: The old function previously assigned to the key.

  local old_function = keyinput.key_press[key]
  local is_function = type(fn) == "function"
  keyinput.key_press[key] = is_function and fn or nil
  input.keyhook(key, is_function)

  return old_function
end

function keyinput.register_key_release(key, fn)
-- key - string. Which key do you wish to bind?
-- fn  - function. To execute on key release. False or nil removes it.
-- Return value: The old function previously assigned to the key.

  local old_function = keyinput.key_release[key]
  local is_function = type(fn) == "function"
  keyinput.key_release[key]= is_function and fn or nil
  input.keyhook(key, is_function)

  return old_function
end

function keyinput.altkeyhook(key, state)
-- key, state - input expected is identical to on_keyhook input. Also passed along.
-- You may set by this line: on_keyhook = keyinput.altkeyhook
-- Only handles keyboard input. If you need to handle other inputs, you may
-- need to have your own on_keyhook function to handle that, but you can still
-- call this when generic keyboard handling is desired.

  if keyinput.key_press[key] and (state.value == 1) then
    keyinput.key_press[key](key, state)
    keyinput.key_state[key] = 1
  elseif keyinput.key_release[key] and (state.value == 0) then
    keyinput.key_release[key](key, state)
    keyinput.key_state[key] = 0
  --[[
  elseif state.type == "mouse" then  -- BUG: keyhook for mouse coordinates can crash the emulator
    keyinput.key_state[key] = math.floor(state.value)
  --]]
  end
end

-- Stores the raw input in a table for later use. Should be called at the start of paint and timer callbacks
function keyinput.get_mouse()
  local tmp = input.raw()
  keyinput.key_state.mouse_x = math.floor(tmp.mouse_x.value)
  keyinput.key_state.mouse_y = math.floor(tmp.mouse_y.value)
end

-- Stores the raw input in a table for later use. Should be called at the start of paint and timer callbacks
function keyinput.get_all_keys()
  local user_input = keyinput.key_state
  for key, inner in pairs(input.raw()) do
    user_input[key] = inner.value
  end
  user_input.mouse_x = math.floor(user_input.mouse_x)
  user_input.mouse_y = math.floor(user_input.mouse_y)
end

return keyinput
