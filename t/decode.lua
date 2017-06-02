package.path = package.path .. ";lib/?.lua;"

local cjson = require "cjson.safe"
local bench = require "util.bench".bench
local json = require "lib.lpeg.json.parser"
local assert = assert


local function cjson_encode(obj)
    if type(obj) == "string" then
        return cjson.encode(cjson.decode(obj))
    end

    return cjson.encode(obj)
end


local function test_decode_s(s)
    local obj1 = json.decode(s)
    local obj2 = cjson.decode(s)
    local s1 = cjson.encode(obj1)
    local s2 = cjson.encode(obj2)
    assert(s1 == s2, "\njson: " .. s1 .. "\ncjson: " .. s2)
end


local function test_decode(obj)
    local s = cjson.encode(obj)
    test_decode_s(s)
end


local function test_decode_error(s)
    local obj1 = json.decode(s)
    local obj2 = cjson.decode(s)
    assert(not obj1, s)
    assert(not obj2, s)
end


local block_top = [[
{"beneficiary":"ak_tjnw1KcmnwfqXvhtGa9GRjanbHM3t6PmEWEWtNMM3ouvNKRu5","hash":"kh_iFZoEn7Eb6PLTnnf8xFFxrLoMinnfg3U6gkwkoM2Bdzsienns","height":9000,"miner":"ak_iivjMfr3Qihbzmp95nDPt7uxvWZEBuDrDAbVqxDrwxqvFMR1x","nonce":6405970277170687609,"pow":[3134893,10908387,24738663,34496220,36143951,50058320,53597513,64172883,69242849,75153996,96066697,105388504,124337259,125323732,128124507,176249869,202250295,231574439,233430733,252033355,258132905,259850586,277605525,282893964,318510307,348775622,370598491,375010311,380796947,415202847,423868767,432853653,445452154,457641193,473676953,481726926,498585207,499538476,503192962,511384439,520381996,535243018],"prev_hash":"kh_2v1WgddpHZGWUtwAkWHvS6memg8g8MY8HPRkYa9XTEw8ua68M8","prev_key_hash":"kh_2v1WgddpHZGWUtwAkWHvS6memg8g8MY8HPRkYa9XTEw8ua68M8","state_hash":"bs_26Pf7T3dKk6HUKBw1feuM9bSrwjJqCnQQnQ9XxByzZxvVkE4j8","target":538061121,"time":1540902417443,"version":25}
]]

bench(function() json.decode(block_top) end, 10000, "lpeg json decode")
bench(function() cjson.decode(block_top) end, 10000, "cjson decode")


local block = json.decode(block_top)
block.nonce = tostring(block.nonce)

local block_top_s = cjson.encode(block)

assert(block.nonce == "6405970277170687609ULL")


test_decode(block)
test_decode({hello="你好"})
test_decode({x="\""})
test_decode({x="\"\t\f\n"})
test_decode({x=true})
test_decode({x=false})
test_decode({x=ngx.null})
test_decode({x=0x123456})
test_decode({x=-0x123456})
test_decode({x=10000})
test_decode({x=-10000})
test_decode({x=12.34})
test_decode({x=-12.34})
test_decode({x="'\"\t"})
test_decode({x="\12"})
-- test_decode({x="\x12"})

test_decode_s("1")
test_decode_s("1.11")
test_decode_s("1.11e10")
test_decode_s("1.11E10")
test_decode_s("111E10")
test_decode_s("111E-10")
test_decode_s("{\"1\":[1,2,3]}")
test_decode_s(block_top_s)

test_decode_error("1" .. block_top)
test_decode_error("{}" .. block_top)
test_decode_error(block_top .. "1")
test_decode_error(block_top .. "{}")
test_decode_error("{1:[1,2,3]}")
test_decode_error("{[1,2,3]}")


print("OK")
