local ffi = require "ffi"
local lpeg = require "lpeg"


ffi.cdef[[
int utf16_to_utf8(const char *src, size_t srclen, char *buf, size_t *buflen);
int64_t strtoint64(const char *nptr, char **endptr, int base, size_t n);
]]


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


local libutf8 = ffi.load(find_shared_obj(package.cpath, "libutf8.so"))


local ffi_new = ffi.new
local ffi_cast = ffi.cast
local ffi_str = ffi.string

local rawset = rawset
local tonumber = tonumber
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


local function toint(s)
    local n = libutf8.strtoint64(s, nil, 0, #s)
    if n < 0 then
        return n > int_lower and tonumber(n) or n
    end

    return n < int_upper and tonumber(n) or n
end


local buflen = ffi_new("size_t[1]", 0)
local vla_char_type = ffi.typeof("char[?]")


local function toutf8(s)
    local len = #s
    local buf = ffi_new(vla_char_type, len)

    buflen[0] = len

    local rc = libutf8.utf16_to_utf8(s, len, buf, buflen)
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
local hex = P"0" * S"xX" * xdigit^1
local number = C(sign * hex) / toint
    + C(sign * float) / tonumber + C(sign * int) / toint

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
