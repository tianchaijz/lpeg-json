package.path = package.path .. ";lib/?.lua;"


local io = require "io"
local cjson = require "cjson.safe"
local json = require "lpeg.json.parser"
local bench = require "util.bench".bench


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

    if (s1 ~= s2) then
        print("obj1 ", tostring(obj1))
        print("obj2 ", tostring(obj2))
        io.open("1.swp", "w"):write(tostring(s1))
        io.open("2.swp", "w"):write(tostring(s2))
    end

    assert(s1 == s2)
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

local sample1 = [[
{"items":{"item":[{"id":"0001","type":"donut","name":"Cake","ppu":0.55,"batters":{"batter":[{"id":"1001","type":"Regular"},{"id":"1002","type":"Chocolate"},{"id":"1003","type":"Blueberry"},{"id":"1004","type":"Devil's Food"}]},"topping":[{"id":"5001","type":"None"},{"id":"5002","type":"Glazed"},{"id":"5005","type":"Sugar"},{"id":"5007","type":"Powdered Sugar"},{"id":"5006","type":"Chocolate with Sprinkles"},{"id":"5003","type":"Chocolate"},{"id":"5004","type":"Maple"}]}]}}
]]
local sample2 = [[
{"context":{"date":"2017-07-21 11:40:51","num_cpus":8,"mhz_per_cpu":2500,"cpu_scaling_enabled":false,"library_build_type":"release"},"benchmarks":[{"name":"BM_Cartesian3D_Mag2<double>/8_mean","iterations":86749616,"real_time":8,"cpu_time":8,"time_unit":"ns","bytes_per_second":7680978029,"items_per_second":960122254},{"name":"BM_Cartesian3D_Mag2<double>/8_stddev","iterations":0,"real_time":0,"cpu_time":0,"time_unit":"ns","bytes_per_second":223956483,"items_per_second":27994560},{"name":"BM_Cartesian3D_Mag2<double>/64_mean","iterations":10097367,"real_time":65,"cpu_time":64,"time_unit":"ns","bytes_per_second":7957475871,"items_per_second":994684484},{"name":"BM_Cartesian3D_Mag2<double>/64_stddev","iterations":0,"real_time":2,"cpu_time":2,"time_unit":"ns","bytes_per_second":227985823,"items_per_second":28498228},{"name":"BM_Cartesian3D_Mag2<double>/512_mean","iterations":1497288,"real_time":482,"cpu_time":480,"time_unit":"ns","bytes_per_second":8537339998,"items_per_second":1067167500},{"name":"BM_Cartesian3D_Mag2<double>/512_stddev","iterations":0,"real_time":12,"cpu_time":12,"time_unit":"ns","bytes_per_second":219139697,"items_per_second":27392462},{"name":"BM_Cartesian3D_Mag2<double>/4096_mean","iterations":150380,"real_time":4589,"cpu_time":4582,"time_unit":"ns","bytes_per_second":7153099980,"items_per_second":894137497},{"name":"BM_Cartesian3D_Mag2<double>/4096_stddev","iterations":0,"real_time":84,"cpu_time":83,"time_unit":"ns","bytes_per_second":129719675,"items_per_second":16214959},{"name":"BM_Cartesian3D_Mag2<double>/8192_mean","iterations":83925,"real_time":9152,"cpu_time":9146,"time_unit":"ns","bytes_per_second":7170300923,"items_per_second":896287615},{"name":"BM_Cartesian3D_Mag2<double>/8192_stddev","iterations":0,"real_time":259,"cpu_time":258,"time_unit":"ns","bytes_per_second":200133361,"items_per_second":25016670},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/8_mean","iterations":76841169,"real_time":9,"cpu_time":9,"time_unit":"ns","bytes_per_second":14836153349,"items_per_second":927259584},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/8_stddev","iterations":0,"real_time":0,"cpu_time":0,"time_unit":"ns","bytes_per_second":146048163,"items_per_second":9128010},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/64_mean","iterations":10422250,"real_time":67,"cpu_time":66,"time_unit":"ns","bytes_per_second":15416790881,"items_per_second":963549430},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/64_stddev","iterations":0,"real_time":2,"cpu_time":2,"time_unit":"ns","bytes_per_second":443111647,"items_per_second":27694478},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/512_mean","iterations":1410591,"real_time":505,"cpu_time":504,"time_unit":"ns","bytes_per_second":16253031226,"items_per_second":1015814452},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/512_stddev","iterations":0,"real_time":12,"cpu_time":12,"time_unit":"ns","bytes_per_second":372837126,"items_per_second":23302320},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/4096_mean","iterations":100000,"real_time":5167,"cpu_time":5164,"time_unit":"ns","bytes_per_second":12696196446,"items_per_second":793512278},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/4096_stddev","iterations":0,"real_time":111,"cpu_time":111,"time_unit":"ns","bytes_per_second":267135940,"items_per_second":16695996},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/8192_mean","iterations":57305,"real_time":12186,"cpu_time":11713,"time_unit":"ns","bytes_per_second":11191346211,"items_per_second":699459138},{"name":"BM_Cartesian3D_Mag2<ROOT::Double_v>/8192_stddev","iterations":0,"real_time":197,"cpu_time":118,"time_unit":"ns","bytes_per_second":113086823,"items_per_second":7067926}]}
]]
bench(function() json.decode(block_top) end, 10000, "lpeg json decode")
bench(function() cjson.decode(block_top) end, 10000, "cjson decode")


local block = json.decode(block_top)
block.nonce = tostring(block.nonce)

local block_top_s = cjson.encode(block)

assert(block.nonce == "6405970277170687609LL")


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
test_decode({x="\x12"})
test_decode("\\u4f60\\u597d")
test_decode("hello\\u4f60\\u597dworld")
test_decode("你\\u4f60\\u597d好")
test_decode("你\\u4f60\\u597d\\u4f60\\u597d\\u4f60\\u597d\\u4f60\\u597d\\u4f60\\u597d好")

test_decode_s("{}")
test_decode_s("[]")
test_decode_s("true")
test_decode_s("false")
test_decode_s("null")
test_decode_s("1")
test_decode_s("1.11")
test_decode_s("1.11e10")
test_decode_s("1.11E10")
test_decode_s("111E10")
test_decode_s("111E-10")
test_decode_s("{\"1\":[1,2,3]}")
test_decode_s(block_top_s)
test_decode_s(sample1)
test_decode_s(sample2)

test_decode_error("1" .. block_top)
test_decode_error("{}" .. block_top)
test_decode_error(block_top .. "1")
test_decode_error(block_top .. "{}")
test_decode_error("{1:[1,2,3]}")
test_decode_error("{[1,2,3]}")


local files = {
    "t/data/canada.json",
    "t/data/citm_catalog.json",
    "t/data/pass01.json",
    "t/data/pass02.json",
    "t/data/pass03.json",
}

for _, f in ipairs(files) do
    local fd = io.open(f, "rb")
    local s = fd:read("*a")
    fd:close()

    print(f)
    test_decode_s(s)
end


local n = "16156557666998568266"
assert(json.decode(n) == 16156557666998568266ULL)


print("OK")
