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

`var t0 = new Date();`
N = 28
ans = fib(N)
puts "ans: #{ans}"

%x{
  var t1 = new Date();
  console.log("time", (t1 - t0)/1000);
}
