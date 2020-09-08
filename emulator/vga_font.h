/*
** QNICE Standard Font
**
** done by sy2002 in Januar 2017
*/

#ifndef _QEMU_VGA_FONT
#define _QEMU_VGA_FONT

#include "../dist_kit/sysdef.h"

// 8x12 font with 256 characters
#define QNICE_FONT_CHAR_DX_BITS     8
#define QNICE_FONT_CHAR_DY_BYTES    12
#define QNICE_FONT_CHARS            256
#define QNICE_FONT_SIZE             (QNICE_FONT_CHAR_DY_BYTES * 256)

static unsigned char qnice_font[VGA_FONT_OFFS_MAX+1] =
{
    0x7E,
    0xC3,
    0x99,
    0x99,
    0xF3,
    0xE7,
    0xE7,
    0xFF,
    0xE7,
    0xE7,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6E,
    0xD8,
    0xD8,
    0xD8,
    0xD8,
    0xDE,
    0xD8,
    0xD8,
    0xD8,
    0x6E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6E,
    0xDB,
    0xDB,
    0xDF,
    0xD8,
    0xDB,
    0x6E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x10,
    0x38,
    0x7C,
    0xFE,
    0x7C,
    0x38,
    0x10,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0xF0,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x0F,
    0x80,
    0x80,
    0x80,
    0x80,
    0xF8,
    0x00,
    0x3E,
    0x20,
    0x38,
    0x20,
    0x20,
    0x00,
    0x88,
    0x88,
    0x50,
    0x50,
    0x20,
    0x00,
    0x3E,
    0x08,
    0x08,
    0x08,
    0x08,
    0x00,
    0xF8,
    0x80,
    0xE0,
    0x80,
    0x80,
    0x00,
    0x3E,
    0x20,
    0x38,
    0x20,
    0x20,
    0x00,
    0x78,
    0x80,
    0x80,
    0x80,
    0x78,
    0x00,
    0x3C,
    0x22,
    0x3E,
    0x24,
    0x22,
    0x00,
    0x22,
    0x88,
    0x22,
    0x88,
    0x22,
    0x88,
    0x22,
    0x88,
    0x22,
    0x88,
    0x22,
    0x88,
    0x55,
    0xAA,
    0x55,
    0xAA,
    0x55,
    0xAA,
    0x55,
    0xAA,
    0x55,
    0xAA,
    0x55,
    0xAA,
    0xEE,
    0xBB,
    0xEE,
    0xBB,
    0xEE,
    0xBB,
    0xEE,
    0xBB,
    0xEE,
    0xBB,
    0xEE,
    0xBB,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x06,
    0x0C,
    0x18,
    0x30,
    0x7E,
    0x00,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x60,
    0x30,
    0x18,
    0x0C,
    0x7E,
    0x00,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x06,
    0x0C,
    0xFE,
    0x38,
    0xFE,
    0x60,
    0xC0,
    0x00,
    0x00,
    0x00,
    0x00,
    0x02,
    0x0E,
    0x3E,
    0x7E,
    0xFE,
    0x7E,
    0x3E,
    0x0E,
    0x02,
    0x00,
    0x00,
    0x00,
    0x80,
    0xE0,
    0xF0,
    0xFC,
    0xFE,
    0xFC,
    0xF0,
    0xE0,
    0x80,
    0x00,
    0x00,
    0x00,
    0x18,
    0x3C,
    0x7E,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x7E,
    0x3C,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x0C,
    0xFE,
    0x0C,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x30,
    0x60,
    0xFE,
    0x60,
    0x30,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x3C,
    0x7E,
    0x18,
    0x18,
    0x18,
    0x7E,
    0x3C,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x28,
    0x6C,
    0xFE,
    0x6C,
    0x28,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x06,
    0x06,
    0x36,
    0x66,
    0xFE,
    0x60,
    0x30,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC0,
    0x7C,
    0x6E,
    0x6C,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x3C,
    0x3C,
    0x3C,
    0x18,
    0x18,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x36,
    0x36,
    0x14,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0xFE,
    0x6C,
    0x6C,
    0x6C,
    0xFE,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x10,
    0x7C,
    0xD6,
    0x70,
    0x38,
    0x1C,
    0xD6,
    0x7C,
    0x10,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x62,
    0x66,
    0x0C,
    0x18,
    0x30,
    0x66,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x38,
    0x76,
    0xF6,
    0xCE,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x1C,
    0x1C,
    0x0C,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x18,
    0x0C,
    0x00,
    0x00,
    0x00,
    0x30,
    0x18,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x18,
    0x30,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x38,
    0xFE,
    0x38,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x7E,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x0C,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x06,
    0x0C,
    0x18,
    0x30,
    0x60,
    0xC0,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xD6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x18,
    0x78,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0x0C,
    0x18,
    0x30,
    0x60,
    0xC6,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0x06,
    0x06,
    0x3C,
    0x06,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x1C,
    0x3C,
    0x6C,
    0xCC,
    0xFE,
    0x0C,
    0x0C,
    0x0C,
    0x00,
    0x00,
    0x00,
    0xFE,
    0xC0,
    0xC0,
    0xC0,
    0xFC,
    0x06,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC0,
    0xC0,
    0xFC,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0xFE,
    0xC6,
    0x0C,
    0x18,
    0x30,
    0x30,
    0x30,
    0x30,
    0x30,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0x7E,
    0x06,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x0C,
    0x18,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x60,
    0xC0,
    0x60,
    0x30,
    0x18,
    0x0C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFE,
    0x00,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x60,
    0x30,
    0x18,
    0x0C,
    0x06,
    0x0C,
    0x18,
    0x30,
    0x60,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0x0C,
    0x18,
    0x18,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xDE,
    0xDE,
    0xDE,
    0xDC,
    0xC0,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0xFC,
    0x66,
    0x66,
    0x66,
    0x7C,
    0x66,
    0x66,
    0x66,
    0xFC,
    0x00,
    0x00,
    0x00,
    0x3C,
    0x66,
    0xC0,
    0xC0,
    0xC0,
    0xC0,
    0xC0,
    0x66,
    0x3C,
    0x00,
    0x00,
    0x00,
    0xF8,
    0x6C,
    0x66,
    0x66,
    0x66,
    0x66,
    0x66,
    0x6C,
    0xF8,
    0x00,
    0x00,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x60,
    0x7C,
    0x60,
    0x60,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x60,
    0x7C,
    0x60,
    0x60,
    0x60,
    0xF0,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC0,
    0xC0,
    0xCE,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0xD8,
    0xD8,
    0x70,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xCC,
    0xD8,
    0xF0,
    0xF0,
    0xD8,
    0xCC,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0xF0,
    0x60,
    0x60,
    0x60,
    0x60,
    0x60,
    0x62,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xEE,
    0xFE,
    0xD6,
    0xD6,
    0xD6,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xE6,
    0xE6,
    0xF6,
    0xDE,
    0xCE,
    0xCE,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0xFC,
    0x66,
    0x66,
    0x66,
    0x7C,
    0x60,
    0x60,
    0x60,
    0xF0,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xD6,
    0x7C,
    0x06,
    0x00,
    0x00,
    0xFC,
    0x66,
    0x66,
    0x66,
    0x7C,
    0x78,
    0x6C,
    0x66,
    0xE6,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC0,
    0x60,
    0x38,
    0x0C,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x7E,
    0x5A,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x6C,
    0x38,
    0x10,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xD6,
    0xD6,
    0xD6,
    0xFE,
    0xEE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0x6C,
    0x38,
    0x38,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x66,
    0x66,
    0x66,
    0x66,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0xFE,
    0xC6,
    0x8C,
    0x18,
    0x30,
    0x60,
    0xC2,
    0xC6,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x7C,
    0x60,
    0x60,
    0x60,
    0x60,
    0x60,
    0x60,
    0x60,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC0,
    0x60,
    0x30,
    0x18,
    0x0C,
    0x06,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x0C,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x18,
    0x3C,
    0x66,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x1C,
    0x1C,
    0x18,
    0x0C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x00,
    0xE0,
    0x60,
    0x60,
    0x7C,
    0x66,
    0x66,
    0x66,
    0x66,
    0xFC,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC0,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x1C,
    0x0C,
    0x0C,
    0x7C,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xFE,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x1C,
    0x36,
    0x30,
    0x30,
    0xFC,
    0x30,
    0x30,
    0x30,
    0x78,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x76,
    0xCE,
    0xC6,
    0xC6,
    0x7E,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0xE0,
    0x60,
    0x60,
    0x6C,
    0x76,
    0x66,
    0x66,
    0x66,
    0xE6,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x0C,
    0x0C,
    0x00,
    0x1C,
    0x0C,
    0x0C,
    0x0C,
    0xCC,
    0xCC,
    0x78,
    0x00,
    0xE0,
    0x60,
    0x60,
    0x66,
    0x6C,
    0x78,
    0x6C,
    0x66,
    0xE6,
    0x00,
    0x00,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0xFE,
    0xD6,
    0xD6,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xDC,
    0x66,
    0x66,
    0x66,
    0x66,
    0x66,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xDC,
    0x66,
    0x66,
    0x66,
    0x7C,
    0x60,
    0x60,
    0xF0,
    0x00,
    0x00,
    0x00,
    0x00,
    0x76,
    0xCC,
    0xCC,
    0xCC,
    0x7C,
    0x0C,
    0x0C,
    0x1E,
    0x00,
    0x00,
    0x00,
    0x00,
    0xDC,
    0x66,
    0x60,
    0x60,
    0x60,
    0xF0,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0x70,
    0x1C,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x30,
    0x30,
    0x30,
    0xFC,
    0x30,
    0x30,
    0x30,
    0x36,
    0x1C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0x6C,
    0x38,
    0x10,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xD6,
    0xD6,
    0xFE,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC6,
    0x6C,
    0x38,
    0x38,
    0x6C,
    0xC6,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xCE,
    0x76,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFE,
    0x8C,
    0x18,
    0x30,
    0x62,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x0E,
    0x18,
    0x18,
    0x18,
    0x70,
    0x18,
    0x18,
    0x18,
    0x0E,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x70,
    0x18,
    0x18,
    0x18,
    0x0E,
    0x18,
    0x18,
    0x18,
    0x70,
    0x00,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x66,
    0x66,
    0x00,
    0x66,
    0x66,
    0x66,
    0x3C,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x1F,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x1F,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xF8,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0xF8,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xF8,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0xF8,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0xFF,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x3F,
    0x30,
    0x3F,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6F,
    0x60,
    0x7F,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7F,
    0x60,
    0x6F,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6F,
    0x60,
    0x6F,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFC,
    0x0C,
    0xFC,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0xEC,
    0x0C,
    0xFC,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0xEF,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFC,
    0x0C,
    0xEC,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0xEC,
    0x0C,
    0xEC,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0xFF,
    0x00,
    0xEF,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0xEF,
    0x00,
    0xEF,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x82,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x18,
    0x18,
    0x3C,
    0x3C,
    0x3C,
    0x18,
    0x00,
    0x00,
    0x10,
    0x7C,
    0xD6,
    0xD0,
    0xD0,
    0xD6,
    0x7C,
    0x10,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x60,
    0x60,
    0xF0,
    0x60,
    0x66,
    0xF6,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x3C,
    0x62,
    0x60,
    0xF8,
    0x60,
    0xF8,
    0x60,
    0x62,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x66,
    0x66,
    0x3C,
    0x18,
    0x7E,
    0x18,
    0x3C,
    0x18,
    0x18,
    0x00,
    0x00,
    0x6C,
    0x38,
    0x00,
    0x7C,
    0xC6,
    0xC0,
    0x7C,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0x60,
    0x7C,
    0xC6,
    0xC6,
    0x7C,
    0x0C,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x6C,
    0x38,
    0x00,
    0x7C,
    0xC6,
    0x70,
    0x1C,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x7E,
    0x81,
    0x99,
    0xA5,
    0xA1,
    0xA1,
    0xA5,
    0x99,
    0x81,
    0x7E,
    0x00,
    0x00,
    0x3C,
    0x6C,
    0x6C,
    0x3E,
    0x00,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x36,
    0x6C,
    0xD8,
    0x6C,
    0x36,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0x06,
    0x06,
    0x06,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0x81,
    0xB9,
    0xA5,
    0xA5,
    0xB9,
    0xA5,
    0xA5,
    0x81,
    0x7E,
    0x00,
    0x00,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x7E,
    0x18,
    0x18,
    0x00,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x18,
    0x30,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x18,
    0x6C,
    0x38,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x38,
    0x00,
    0xFE,
    0xC6,
    0x8C,
    0x38,
    0x62,
    0xC6,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xF6,
    0xC0,
    0xC0,
    0x00,
    0x7F,
    0xDB,
    0xDB,
    0xDB,
    0x7B,
    0x1B,
    0x1B,
    0x1B,
    0x1B,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x38,
    0x00,
    0xFE,
    0x8C,
    0x18,
    0x30,
    0x62,
    0xFE,
    0x00,
    0x00,
    0x00,
    0x30,
    0x70,
    0x30,
    0x30,
    0x78,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x6C,
    0x38,
    0x00,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0xD8,
    0x6C,
    0x36,
    0x6C,
    0xD8,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6E,
    0xDF,
    0xD8,
    0xDE,
    0xDE,
    0xD8,
    0xD8,
    0xDF,
    0x6E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0xDA,
    0xDE,
    0xD8,
    0xDA,
    0x6C,
    0x00,
    0x00,
    0x66,
    0x66,
    0x00,
    0x66,
    0x66,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x30,
    0x30,
    0x00,
    0x30,
    0x30,
    0x60,
    0xC6,
    0xC6,
    0x7C,
    0x30,
    0x18,
    0x00,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x18,
    0x30,
    0x00,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x38,
    0x6C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xFE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x7E,
    0xD8,
    0xD8,
    0xD8,
    0xD8,
    0xFE,
    0xD8,
    0xD8,
    0xD8,
    0xDE,
    0x00,
    0x00,
    0x00,
    0x3C,
    0x66,
    0xC0,
    0xC0,
    0xC0,
    0xC6,
    0x66,
    0x3C,
    0x18,
    0xCC,
    0x38,
    0x18,
    0x0C,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x7C,
    0x60,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x18,
    0x30,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x7C,
    0x60,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x7C,
    0x60,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0xFE,
    0x66,
    0x60,
    0x7C,
    0x60,
    0x66,
    0xFE,
    0x00,
    0x00,
    0x18,
    0x0C,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x18,
    0x30,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x3C,
    0x66,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x66,
    0x66,
    0x00,
    0x3C,
    0x18,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0xF8,
    0x6C,
    0x66,
    0x66,
    0xF6,
    0x66,
    0x66,
    0x6C,
    0xF8,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0xC6,
    0xE6,
    0xF6,
    0xDE,
    0xCE,
    0xC6,
    0xC6,
    0x00,
    0x00,
    0x30,
    0x18,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x18,
    0x30,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x38,
    0x38,
    0x6C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0xC6,
    0xCE,
    0xDE,
    0xD6,
    0xF6,
    0xE6,
    0xC6,
    0xFC,
    0x00,
    0x00,
    0x30,
    0x18,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x18,
    0x30,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x00,
    0x66,
    0x66,
    0x66,
    0x3C,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0xF0,
    0x60,
    0x7C,
    0x66,
    0x66,
    0x66,
    0x7C,
    0x60,
    0xF0,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xCC,
    0xC6,
    0xC6,
    0xD6,
    0xDC,
    0x80,
    0x00,
    0x60,
    0x30,
    0x18,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x18,
    0x30,
    0x60,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x30,
    0x78,
    0xCC,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x38,
    0x6C,
    0x38,
    0x00,
    0x78,
    0x0C,
    0x7C,
    0xCC,
    0xDC,
    0x76,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0xDB,
    0x1B,
    0x7F,
    0xD8,
    0xDB,
    0x7E,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7C,
    0xC6,
    0xC0,
    0xC0,
    0xC6,
    0x7C,
    0x18,
    0x6C,
    0x38,
    0x30,
    0x18,
    0x0C,
    0x00,
    0x7C,
    0xC6,
    0xFE,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x00,
    0x7C,
    0xC6,
    0xFE,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x10,
    0x38,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xFE,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xFE,
    0xC0,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x60,
    0x30,
    0x18,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x18,
    0x3C,
    0x66,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x38,
    0x18,
    0x18,
    0x18,
    0x18,
    0x3C,
    0x00,
    0x00,
    0x78,
    0x30,
    0x78,
    0x0C,
    0x7E,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0xDC,
    0x66,
    0x66,
    0x66,
    0x66,
    0x66,
    0x00,
    0x00,
    0x60,
    0x30,
    0x18,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x10,
    0x38,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x76,
    0xDC,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x6C,
    0x6C,
    0x00,
    0x7C,
    0xC6,
    0xC6,
    0xC6,
    0xC6,
    0x7C,
    0x00,
    0x00,
    0x00,
    0x00,
    0x18,
    0x18,
    0x00,
    0x7E,
    0x00,
    0x18,
    0x18,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x7E,
    0xCE,
    0xDE,
    0xF6,
    0xE6,
    0xFC,
    0x00,
    0x00,
    0xC0,
    0x60,
    0x30,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x30,
    0x78,
    0xCC,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x00,
    0xCC,
    0xCC,
    0x00,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0xCC,
    0x76,
    0x00,
    0x00,
    0x0C,
    0x18,
    0x30,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xCE,
    0x76,
    0x06,
    0xC6,
    0x7C,
    0x00,
    0xF0,
    0x60,
    0x60,
    0x78,
    0x6C,
    0x6C,
    0x6C,
    0x78,
    0x60,
    0x60,
    0xF0,
    0x00,
    0xC6,
    0xC6,
    0x00,
    0xC6,
    0xC6,
    0xC6,
    0xCE,
    0x76,
    0x06,
    0xC6,
    0x7C
};

#endif
