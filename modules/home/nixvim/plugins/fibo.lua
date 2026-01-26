function fibo(n)
  if type(n) ~= "number" or n < 0 or n % 1 ~= 0 then
    return nil
  end
  local a, b = 0, 1
  for i = 1, n do
    a, b = b, a + b
  end
  return a
end
