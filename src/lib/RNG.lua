local RNG = {}

-- complete list of all possible RNG states
RNG.possible_values = {}
RNG.reverse_possible_values = {}

-- predict the next RNG values
function RNG.predict(seed1, seed2, rng1, rng2)
  local Y = 1
  local A, carry_flag

  local function tick_RNG()
    A = (4*seed1) % 0x100

    carry_flag = true
    A = (A + seed1 + 1)
    if A < 0x100 then carry_flag = false
    else A = A % 0x100; carry_flag = true end

    seed1 = A

    seed2 = 2*seed2
    if seed2 < 0x100 then carry_flag = false
    else seed2 = seed2 % 0x100; carry_flag = true end

    A = 0x20
    local tmp = bit.band(A, seed2)

    -- simplified branches
    if (carry_flag and tmp ~= 0) or (not carry_flag and tmp == 0) then
      seed2 = (seed2 + 1) % 0x100
    end
    A = seed2
    A = bit.bxor(A, seed1)

    -- set RNG byte
    if Y == 0 then
      rng1 = A
    else
      rng2 = A
    end
  end

  tick_RNG()
  Y = Y - 1
  tick_RNG()

  return seed1, seed2, rng1, rng2
end

-- generate a list of all RNG states from the initial state until it loops
function RNG.create_lists()
  local seed1, seed2, rng1, rng2 = 0, 0, 0, 0
  local counter = 1
  while true do
    local RNG_index = seed1 + 0x100*seed2 + 0x10000*rng1 + 0x1000000*rng2
    if RNG.possible_values[RNG_index] then
      break
    end
    RNG.possible_values[RNG_index] = counter
    RNG.reverse_possible_values[counter] = RNG_index

    counter = counter + 1
    seed1, seed2, rng1, rng2 = RNG.predict(seed1, seed2, rng1, rng2)
  end
end

return RNG
