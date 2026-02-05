-- cursor-1a2b3c4d
-- cursor-1o2p3q4r[Ww]
function greet(name)
  -- cursor-5e6f7g8h
  return "Hello, " .. name .. "!"
end

-- cursor-a7cp3312[Www]
local function fetch_data()
  -- cursor-9i0j1k2l
  return "data"
end

-- cursor-7q8r9s0t[Ww]
local calculate = function(x)
  -- cursor-3m4n5o6p
  return x * 2
end

-- cursor-axbpbq73[W]
my_func = function()
  -- cursor-5s6t7u8v
  return "global"
end

function processData(data)
  function inner()
    -- cursor-1u2v3w4x
    return data
  end
  return inner()
end

function outer()
  function middle()
    function deepest()
      -- cursor-5y6z7a8b
      return "deep"
    end
    return deepest()
  end
  return middle()
end

function withLocalNested()
  local function helper()
    -- cursor-9c0d1e2f
    return "help"
  end
  return helper()
end

function withTableFilter(items)
  return table.filter(function()
    -- cursor-3g4h5i6j
    return true
  end, items)
end
