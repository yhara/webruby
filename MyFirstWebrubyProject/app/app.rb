def fib(n)
  case n
  when 0
    0
  when 1
    1
  else
    fib(n-2) + fib(n-1)
  end
end

N = 28
ans = fib(N)
puts "ans: #{ans}"
