---@param t integer[] Durations in ns. Sorted in place.
---@return string
return function(t)
  table.sort(t)
  local sum = 0
  for _, v in ipairs(t) do
    sum = sum + v
  end
  local function at(fraction)
    return t[math.max(1, math.floor(#t * fraction))] / 1e6
  end
  return ("median %.3f ms, p99 %.3f ms, max %.3f ms, mean %.3f ms"):format(
    at(0.5),
    at(0.99),
    t[#t] / 1e6,
    sum / #t / 1e6
  )
end
