local ffi = require "ffi"
local lpeg = require "lpeg"

local rawset = rawset
local tonumber = tonumber
local string_sub = string.sub
local string_char = string.char
local tbl_concat = table.concat
local lpeg_match = lpeg.match


lpeg.locale(lpeg)
lpeg.setmaxstack(1000)


local P, S, R, V = lpeg.P, lpeg.S, lpeg.R, lpeg.V
local C, Cc, Cf, Cg, Ct = lpeg.C, lpeg.Cc, lpeg.Cf, lpeg.Cg, lpeg.Ct

local int_upper = 2 ^ 53
local int_lower = -int_upper

local json_null = ngx.null
local space = S" \t\r\n"^0


local function uint64(s, base)
    base = base or 10

    local n = 0ULL
    for i = 1, #s do
        n = n * base + tonumber(string_sub(s, i, i))
    end

    return n
end


local function tonum(sign, s, typ, base)
    local n
    local neg = sign == "-"

    if typ == 1 then
        n = tonumber(s)
        return neg and -n or n
    end

    n = uint64(s, base)

    if neg then
        n = -ffi.cast("int64_t", n)
        return n > int_lower and tonumber(n) or n
    end

    return n < int_upper and tonumber(n) or n
end


-- group
local function G(patt) return patt * space end
-- delimited(separated) by
local function D(patt, sep) return (patt * (sep * patt)^0)^-1 end


local digit = lpeg.digit  -- R("09")
local xdigit = lpeg.xdigit  -- R("09", "AF", "af")
local escaped = P"\\" *
    ( P"a" / "\a"
    + P"b" / "\b"
    + P"f" / "\f"
    + P"n" / "\n"
    + P"r" / "\r"
    + P"t" / "\t"
    + P"v" / "\v"
    + P"u" / "\\u"  -- TODO: utf8
    + C(S"\\\"/")
    + digit * digit^-2 / tonumber / string_char
    + S"xX" * C(xdigit * xdigit) * Cc(16) / tonumber / string_char
    )
local unescaped = C((P(1) - S'\\"')^1)
local qstring = P'"' * Ct((unescaped + escaped)^0) * P'"' / tbl_concat

local int = digit^1
local sign = S"-+"^-1
local exp = S"Ee" * S"+-"^-1 * int
local decimal = digit^1 * P"." * digit^0 + P"." * int
local float = decimal * exp^-1 + int * exp
local hex = (P"0" * S"xX") * C(xdigit^1)
local number = C(sign) * (hex * Cc(0) * Cc(16) + C(float) * Cc(1) + C(int)) / tonum

local boolean = (G"true" * Cc(true)) + (G"false" * Cc(false))
local null = P"null" * Cc(json_null)


local Grammar = {
    "JSON",
    JSON = space * V"Value" * P(-1),
    Value = G(V"Object" + V"Array" + V"Simple"),
    Object = Cf(G(Ct"{") * D(Cg(G(qstring) * G":" * V"Value"), G",") * P"}", rawset),
    Array = Ct(G"[" * D(V"Value", G",") * P"]"),
    Simple = number + boolean + null + qstring,
}


-- XXX: debug
-- Grammar = require("lpeg.json.pegdebug").trace(Grammar)
Grammar = P(Grammar)


local _M = {}


function _M.decode(s)
    return lpeg_match(Grammar, s)
end


return _M
