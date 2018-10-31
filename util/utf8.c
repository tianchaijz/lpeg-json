
/*
 * Copyright (c) 2010-2012  Mark Pulford <mark@kyne.com.au>
 */


#include<stdlib.h>
#include<string.h>


static int hexdigit2int(char hex)
{
    if ('0' <= hex  && hex <= '9')
        return hex - '0';

    /* Force lowercase */
    hex |= 0x20;
    if ('a' <= hex && hex <= 'f')
        return 10 + hex - 'a';

    return -1;
}

static int decode_hex4(const char *hex)
{
    int digit[4];
    int i;

    /* Convert ASCII hex digit to numeric digit
     * Note: this returns an error for invalid hex digits, including
     *       NULL */
    for (i = 0; i < 4; i++) {
        digit[i] = hexdigit2int(hex[i]);
        if (digit[i] < 0) {
            return -1;
        }
    }

    return (digit[0] << 12) +
           (digit[1] << 8) +
           (digit[2] << 4) +
            digit[3];
}

/* Converts a Unicode codepoint to UTF-8.
 * Returns UTF-8 string length, and up to 4 bytes in *utf8 */
static int codepoint_to_utf8(char *utf8, int codepoint)
{
    /* 0xxxxxxx */
    if (codepoint <= 0x7F) {
        utf8[0] = codepoint;
        return 1;
    }

    /* 110xxxxx 10xxxxxx */
    if (codepoint <= 0x7FF) {
        utf8[0] = (codepoint >> 6) | 0xC0;
        utf8[1] = (codepoint & 0x3F) | 0x80;
        return 2;
    }

    /* 1110xxxx 10xxxxxx 10xxxxxx */
    if (codepoint <= 0xFFFF) {
        utf8[0] = (codepoint >> 12) | 0xE0;
        utf8[1] = ((codepoint >> 6) & 0x3F) | 0x80;
        utf8[2] = (codepoint & 0x3F) | 0x80;
        return 3;
    }

    /* 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx */
    if (codepoint <= 0x1FFFFF) {
        utf8[0] = (codepoint >> 18) | 0xF0;
        utf8[1] = ((codepoint >> 12) & 0x3F) | 0x80;
        utf8[2] = ((codepoint >> 6) & 0x3F) | 0x80;
        utf8[3] = (codepoint & 0x3F) | 0x80;
        return 4;
    }

    return 0;
}


/* Called when index pointing to beginning of UTF-16 code escape: \uXXXX
 * \u is guaranteed to exist, but the remaining hex characters may be
 * missing.
 * Translate to UTF-8 and append to temporary token string.
 * Must advance index to the next character to be processed.
 * Returns: 0   success
 *          -1  error
 */
int utf16_to_utf8(const char *src, size_t srclen, char *buf, size_t *buflen)
{
    char utf8[4];       /* Surrogate pairs require 4 UTF-8 bytes */
    size_t bufsize = *buflen, pos = 0;
    int codepoint, surrogate_low, len, escape_len;
    const char *end = src + srclen, *p;

    for (p = src; p + 6 <= end && p[0] == '\\' && p[1] == 'u';) {
        escape_len = 6;

        /* Fetch UTF-16 code unit */
        codepoint = decode_hex4(p + 2);
        if (codepoint < 0) {
            return __LINE__;
        }

        /* UTF-16 surrogate pairs take the following 2 byte form:
         *      11011 x yyyyyyyyyy
         * When x = 0: y is the high 10 bits of the codepoint
         *      x = 1: y is the low 10 bits of the codepoint
         *
         * Check for a surrogate pair (high or low) */
        if ((codepoint & 0xF800) == 0xD800) {
            /* Error if the 1st surrogate is not high */
            if (codepoint & 0x400) {
                return __LINE__;
            }

            /* Ensure the next code is a unicode escape */
            if (p + 12 > end ||
                *(p + escape_len) != '\\' ||
                *(p + escape_len + 1) != 'u') {
                return __LINE__;
            }

            /* Fetch the next codepoint */
            surrogate_low = decode_hex4(p + 2 + escape_len);
            if (surrogate_low < 0) {
                return __LINE__;
            }

            /* Error if the 2nd code is not a low surrogate */
            if ((surrogate_low & 0xFC00) != 0xDC00) {
                return __LINE__;
            }

            /* Calculate Unicode codepoint */
            codepoint = (codepoint & 0x3FF) << 10;
            surrogate_low &= 0x3FF;
            codepoint = (codepoint | surrogate_low) + 0x10000;
            escape_len = 12;
        }

        /* Convert codepoint to UTF-8 */
        len = codepoint_to_utf8(utf8, codepoint);
        if (len == 0) {
            return __LINE__;
        }

        pos += len;

        if (pos > bufsize) {
            return __LINE__;
        }

        buf = (char *) memcpy(buf, utf8, len) + len;
        p += escape_len;
    }

    *buflen = pos;

    return 0;
}
