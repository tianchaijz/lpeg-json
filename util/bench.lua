local clock = require("os").clock
local print = print
local string_format = string.format


local _M = {}


function _M.bench(func, iters, msg)
    local start = clock()
    local n = 0
    while n < iters do
        func()
        n = n + 1
    end

    local elapsed = clock() - start
    print(string_format("%-50s: elapsed %.6f s, per %.6f us", msg, elapsed,
                        1000000 * elapsed / iters))
end


return _M
