local ffi = require "ffi"
local lpeg = require "lpeg"


ffi.cdef[[
int utf16_to_utf8(const char *src, size_t srclen, char *buf, size_t *buflen);
]]


local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_str = ffi.string

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
        n = -ffi_cast("int64_t", n)
        return n > int_lower and tonumber(n) or n
    end

    return n < int_upper and tonumber(n) or n
end


local function find_shared_obj(cpath, so_name)
    local io, string = io, string
    for k in string.gmatch(cpath, "[^;]+") do
        local so_path = string.match(k, "(.*/)")
        so_path = so_path .. so_name

        -- Don't get me wrong, the only way to know if a file exist is trying
        -- to open it.
        local f = io.open(so_path)
        if f ~= nil then
            io.close(f)
            return so_path
        end
    end
end


local buflen = ffi_new("size_t[1]", 0)
local utf8 = ffi.load(find_shared_obj(package.cpath, "libutf8.so"))


local function toutf8(s)
    local len = #s
    local buf = ffi_new("char[?]", len)

    buflen[0] = len

    local rc = utf8.utf16_to_utf8(s, #s, buf, buflen)
    if rc == 0 then
        return ffi_str(buf, buflen[0])
    end
end


-- group
local function G(patt) return patt * space end
-- delimited(separated) by
local function D(patt, sep) return (patt * (sep * patt)^0)^-1 end


local digit = lpeg.digit  -- R("09")
local xdigit = lpeg.xdigit  -- R("09", "AF", "af")
local esc_seq = P"\\" *
    ( P"b" / "\b"
    + P"t" / "\t"
    + P"n" / "\n"
    + P"f" / "\f"
    + P"r" / "\r"
    + C(S"\\\"/")
    + digit * digit^-2 / tonumber / string_char
    + S"xX" * C(xdigit * xdigit) * Cc(16) / tonumber / string_char
    )
local unicode = (P"\\u" * xdigit^4)^1 / toutf8
local escaped = esc_seq + unicode
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
