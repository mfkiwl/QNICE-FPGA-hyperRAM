/*  VGA World demonstration
 *
 *  This program displays the world using 16 sprites.
 *
 *  How to compile:  qvc world.c sprite.c -c99
 *
 *  The planet sprite was made by Viktor Hahn (Viktor.Hahn@web.de), who licensed
 *  it under the Creative Commons Attribution 4.0 International License (CC BY 4.0).
 *
 *  done by MJoergen in September 2020
*/

#include <stdio.h>

#include "qmon.h"
#include "sysdef.h"
#include "sprite.h"

// convenient mechanism to access QNICE's Memory Mapped IO registers
#define MMIO( __x ) *((unsigned int volatile *) __x )

static const t_sprite_palette palette = {
   0x29ba,
   0x361a,
   0x4677,
   0x52dc,
   0x3e9d,
   0x31d2,
   0x0842,
   0x254c,
   0x10c8,
   0x535e,
   0x633a,
   0x6bbf,
   0x13bf,
   0x4ad2,
   0x366b,
   0x7fff,
};

static const t_sprite_bitmap bitmaps[16] = {
{
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff88,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf886,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf886, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8866, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf886, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf866, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6666, 0x6666, 0x6666,
},

{
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8888, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8888, 0x8886, 0x8666,
   0xffff, 0xffff, 0xffff, 0xfff8, 0x8888, 0x8666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0x8888, 0x6666, 0x6666, 0x6666, 0x6668,
   0xffff, 0xffff, 0xff88, 0x8866, 0x6666, 0x6666, 0x6666, 0x8886,
   0xffff, 0xfff8, 0x8886, 0x6666, 0x6666, 0x6666, 0x6868, 0x6688,
   0xffff, 0xff88, 0x6666, 0x6666, 0x6666, 0x6666, 0x8668, 0x8888,
   0xffff, 0x8866, 0x6666, 0x6666, 0x6666, 0x6868, 0x6888, 0x8888,
   0xff88, 0x8666, 0x6666, 0x6666, 0x6666, 0x8688, 0x8888, 0x8777,
   0xf886, 0x6666, 0x6666, 0x6666, 0x6686, 0x6868, 0x8887, 0x7877,
   0x8666, 0x6666, 0x6666, 0x6666, 0x6868, 0x8888, 0x8777, 0x7777,
   0x6666, 0x6666, 0x6666, 0x6666, 0x6868, 0x8878, 0x7777, 0x777e,
   0x6666, 0x6666, 0x6666, 0x6686, 0x8888, 0x8787, 0x7877, 0x7ee5,
   0x6666, 0x6666, 0x6666, 0x6866, 0x8887, 0x8877, 0x8877, 0x755d,
   0x6666, 0x6666, 0x6666, 0x8688, 0x6888, 0x8778, 0x877e, 0x5e5d,
   0x6666, 0x6666, 0x6668, 0x6868, 0x8788, 0x7787, 0x77e5, 0xe5d2,
   0x6666, 0x6666, 0x6888, 0x8888, 0x8887, 0x7777, 0xee5e, 0xd522,
   0x6666, 0x6668, 0x6868, 0x8888, 0x7877, 0x7777, 0x5d55, 0x5252,
   0x6666, 0x6666, 0x6688, 0x8888, 0x7877, 0x577e, 0xe5e7, 0x5555,
   0x6666, 0x6666, 0x6668, 0x8777, 0x8775, 0x7775, 0x55e7, 0x7512,
   0x6666, 0x6666, 0x6668, 0x7787, 0x7757, 0x557e, 0xe777, 0x7105,
   0x6666, 0x6666, 0x6668, 0x8777, 0x7575, 0x5577, 0x7e77, 0x5011,
   0x6666, 0x6666, 0x6688, 0x7777, 0x5755, 0x555e, 0x7775, 0x0151,
   0x6666, 0x6666, 0x6887, 0x8777, 0x5505, 0x0557, 0x7721, 0x1102,
},

{
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x8888, 0x8888, 0x8fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x6868, 0x8888, 0x8888, 0x8fff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x6666, 0x6686, 0x8888, 0x8888, 0x8fff, 0xffff, 0xffff, 0xffff,
   0x8688, 0x8888, 0x8888, 0x8888, 0x8888, 0xffff, 0xffff, 0xffff,
   0x8888, 0x8888, 0x8888, 0x7877, 0x7888, 0x88ff, 0xffff, 0xffff,
   0x8888, 0x8878, 0x7777, 0x7777, 0x7777, 0x7788, 0x8fff, 0xffff,
   0x8887, 0x8777, 0x7777, 0x7777, 0x7575, 0x5757, 0x78ff, 0xffff,
   0x7877, 0x7777, 0x7777, 0x7555, 0x5555, 0x5555, 0x5578, 0xffff,
   0x7777, 0x77e5, 0xe5e5, 0x5e5e, 0x5e55, 0xe555, 0x5555, 0x77ff,
   0x777e, 0x5555, 0x555e, 0x5dd2, 0xd2d5, 0x25d5, 0xd251, 0x507f,
   0x77e5, 0x5e5e, 0xd5d5, 0xd52d, 0x2d2d, 0xd2d2, 0x52d2, 0xd250,
   0x5e55, 0xdddd, 0x5d5d, 0x2dd2, 0xdd2d, 0x22d2, 0xdd22, 0x224d,
   0xed5d, 0xd5d2, 0xdddd, 0xd2ad, 0xd2d2, 0xdd2d, 0x32d5, 0x2511,
   0x5ddd, 0x2ddd, 0x2d2d, 0xddaa, 0xadad, 0xaaa3, 0xda22, 0xd555,
   0xdd2d, 0xd2aa, 0xaaaa, 0xaada, 0xdada, 0xdada, 0xada3, 0x332d,
   0xd2dd, 0xaada, 0xddad, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0x3d39,
   0xd2a2, 0xadaa, 0xaaaa, 0x5daa, 0xaaad, 0xaada, 0xaaaa, 0xa33d,
   0x222a, 0xaaaa, 0xaaa2, 0x723a, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaa3,
   0x2222, 0xdaaa, 0xaaa1, 0x7751, 0x3aaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x2222, 0xaaaa, 0xaaa2, 0x7670, 0x123a, 0xaaaa, 0xaaaa, 0xaaaa,
   0x2221, 0xaaaa, 0xaaa3, 0x0887, 0x002a, 0xaaaa, 0xaaaa, 0xaaaa,
   0x2211, 0x2aaa, 0xaaaa, 0x1787, 0xd022, 0x2aaa, 0xaaaa, 0xaaaa,
   0x2121, 0x1aaa, 0xaaaa, 0x1577, 0xd233, 0x12aa, 0xaaaa, 0xdaaa,
   0x1211, 0x12aa, 0xaaaa, 0x1155, 0x2aaa, 0x222a, 0xaaaa, 0xaaaa,
},

{
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x7fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x00ff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xc505, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x1cdc, 0x0fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x5112, 0xc0ff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x2244, 0xdc0f, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xa9d9, 0x93c0, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaa9a, 0x3a9c, 0x1fff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaa3, 0xa9a3, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0x33a9, 0x91cf, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaa9, 0xaa9a, 0x99c1, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xa3a9, 0xab9c, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaa3a, 0x9994, 0xcfff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0x9ab9, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff,
},

{
   0xffff, 0xffff, 0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xfff8, 0x8666, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xfff8, 0x6666, 0x6666, 0x6666, 0x6668,
   0xffff, 0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x6666, 0x6666,
   0xffff, 0xffff, 0xffff, 0xf886, 0x6666, 0x6666, 0x6666, 0x6686,
   0xffff, 0xffff, 0xffff, 0xf886, 0x6666, 0x6666, 0x6666, 0x6868,
   0xffff, 0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666, 0x6868,
   0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6666, 0x6868,
   0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6668, 0x8688,
   0xffff, 0xffff, 0xfff8, 0x8666, 0x6666, 0x6666, 0x6666, 0x8888,
   0xffff, 0xffff, 0xfff8, 0x6666, 0x6666, 0x6666, 0x6668, 0x6888,
   0xffff, 0xffff, 0xfff8, 0x6666, 0x6666, 0x6666, 0x6666, 0x8888,
   0xffff, 0xffff, 0xff88, 0x6666, 0x6666, 0x6666, 0x6688, 0x8887,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x6666, 0x6868, 0x8888,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x6666, 0x6686, 0x8877,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x6666, 0x8688, 0x8888,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666, 0x6688, 0x8877,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666, 0x8888, 0x8777,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666, 0x6888, 0x8877,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x6666, 0x8688, 0x7777,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6686, 0x8888, 0x8777,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6668, 0x6887, 0x7775,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6668, 0x8888, 0x7755,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6666, 0x8887, 0x7775,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6688, 0x8877, 0x7755,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6868, 0x8877, 0x7555,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6688, 0x8877, 0x5755,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6868, 0x8777, 0x5555,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6888, 0x8877, 0x5555,
},

{
   0x6666, 0x6666, 0x6878, 0x7775, 0x5555, 0x5057, 0x5211, 0x0111,
   0x6666, 0x6666, 0x8877, 0x7555, 0x5050, 0x5212, 0x1111, 0x1011,
   0x6666, 0x6688, 0x8777, 0x7555, 0x5555, 0x1151, 0x1111, 0x1101,
   0x6688, 0x8888, 0x7777, 0x5555, 0x5121, 0x2111, 0x1111, 0x1001,
   0x6888, 0x8877, 0x7755, 0x5550, 0x2252, 0x1511, 0x1110, 0x0100,
   0x6888, 0x8787, 0x7770, 0x5055, 0x5212, 0x2121, 0x1111, 0x0010,
   0x8688, 0x8777, 0x7057, 0x5552, 0x1222, 0x2212, 0x1110, 0x1000,
   0x8888, 0x7777, 0x5755, 0x0515, 0x2122, 0x2332, 0x2211, 0x0000,
   0x8887, 0x8775, 0x7050, 0x5051, 0x1512, 0x2323, 0x3411, 0x1110,
   0x8887, 0x7775, 0x5555, 0x0511, 0x2111, 0x2233, 0x3322, 0x4111,
   0x8888, 0x7775, 0x5505, 0x1151, 0x1221, 0x1222, 0x3333, 0x2211,
   0x8877, 0x7070, 0x5050, 0x5011, 0x2111, 0x1111, 0x1222, 0x4141,
   0x8777, 0x7707, 0x0500, 0x1111, 0x1111, 0x1111, 0x2111, 0x1211,
   0x8787, 0x0750, 0x5050, 0x0511, 0x1111, 0x1111, 0x1124, 0x2322,
   0x8777, 0x8070, 0x5001, 0x1111, 0x1111, 0x1121, 0x1112, 0x4233,
   0x7777, 0x0705, 0x0050, 0x1011, 0x1110, 0x1111, 0x1111, 0x1112,
   0x7707, 0x0700, 0x0501, 0x1110, 0x1000, 0x1111, 0x1011, 0x1111,
   0x7777, 0x0070, 0x0001, 0x1111, 0x0100, 0x0010, 0x1111, 0x1110,
   0x7770, 0x7500, 0x5051, 0x1110, 0x1000, 0x0001, 0x0001, 0x1100,
   0x7705, 0x5055, 0x0111, 0x1111, 0x1011, 0x0000, 0x0000, 0x1101,
   0x5575, 0x0501, 0x1511, 0x2111, 0x1110, 0x1000, 0x5500, 0x1010,
   0x7055, 0x5052, 0x1121, 0x1211, 0x1111, 0x555e, 0xe750, 0x0000,
   0x5750, 0x5221, 0x2212, 0x2222, 0x122e, 0xeeee, 0xe700, 0x0000,
   0x5555, 0x2512, 0x2122, 0x2122, 0x225e, 0xeeee, 0xe700, 0x0000,
   0x5525, 0x2222, 0x2222, 0x4222, 0xdede, 0xde7e, 0x7500, 0x0000,
   0x5522, 0x2222, 0x2212, 0x2222, 0xdedd, 0xeeee, 0x0100, 0x0000,
   0x5522, 0x2222, 0x1222, 0x2322, 0x2de5, 0xd5e5, 0x5011, 0x0000,
   0x5d22, 0x2222, 0x2223, 0x2222, 0x1222, 0x22d2, 0x2115, 0x5500,
   0x2222, 0x2222, 0x2322, 0x2422, 0x2222, 0x2222, 0x212e, 0xe511,
   0xd252, 0x2222, 0x3222, 0x3223, 0x2323, 0x3333, 0x3211, 0x5011,
   0x5222, 0x2223, 0x2222, 0x3232, 0x23aa, 0xa3aa, 0xa332, 0x2211,
   0xd225, 0x2222, 0x223a, 0x3a3a, 0xaaa3, 0xa3a3, 0x333a, 0xa321,
},

{
   0x1111, 0x013a, 0xaaaa, 0x2111, 0x1aaa, 0xa323, 0xaaaa, 0xaaaa,
   0x1110, 0x1012, 0xaaaa, 0x1111, 0x23aa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x1000, 0x0001, 0x2aaa, 0x1112, 0x2aaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0000, 0x0232, 0x1121, 0x22aa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0000, 0x0001, 0x1212, 0x2aaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0000, 0x0000, 0x1112, 0x3aaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0000, 0x0000, 0x0111, 0x2aaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0033, 0x3000, 0x0012, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x00ab, 0xa311, 0x0013, 0xaaaa, 0xaaaa, 0xaaab, 0xaaaa,
   0x0000, 0x00aa, 0xaaa2, 0x23aa, 0xaaaa, 0xaaaa, 0xaaaa, 0xbaaa,
   0x0000, 0x002a, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa,
   0x0000, 0x0003, 0xaaba, 0xbaab, 0xaaa3, 0x3aaa, 0xaaaa, 0xaaaa,
   0x1100, 0x0000, 0xaaaa, 0xaaba, 0xa210, 0x02aa, 0xaaaa, 0xaa25,
   0x2321, 0x0000, 0x03aa, 0xaaaa, 0xa100, 0x002a, 0xaaaa, 0xaa2d,
   0x4242, 0x1000, 0x113a, 0xabab, 0xa000, 0x0002, 0xaaaa, 0xa311,
   0x2424, 0x1211, 0x0003, 0xaaaa, 0x3000, 0x0001, 0x2222, 0x2221,
   0x1111, 0x2111, 0x0000, 0x3aab, 0xa200, 0x0001, 0x1112, 0x2111,
   0x0000, 0x1100, 0x0000, 0x03aa, 0xa400, 0x0001, 0x1111, 0x1112,
   0x0000, 0x0000, 0x0000, 0x0123, 0x3000, 0x0011, 0x1111, 0x1111,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0011, 0x1001, 0x1111,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0011, 0x0011, 0x1411,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0010, 0x1111, 0x1111,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0011, 0x0114, 0x1111,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x1110, 0x1141, 0x1411,
   0x0000, 0x0000, 0x0000, 0x0000, 0x0014, 0x1111, 0x4444, 0x4111,
   0x0000, 0x0000, 0x0001, 0x1100, 0x1141, 0x4441, 0x4444, 0x4111,
   0x0000, 0x1010, 0x1111, 0x1111, 0x1414, 0x4444, 0x4344, 0x4441,
   0x0001, 0x0114, 0x1111, 0x4144, 0x4444, 0x3343, 0x3443, 0x4440,
   0x1100, 0x1141, 0x4144, 0x4441, 0x4433, 0x3333, 0x3443, 0x4414,
   0x1011, 0x0144, 0x1444, 0x4444, 0x4333, 0x9333, 0x3334, 0x4441,
   0x1101, 0x1114, 0x4433, 0x3333, 0x3339, 0xa939, 0x3333, 0x4444,
   0x1011, 0x1114, 0x1443, 0x3333, 0x33ba, 0xba9a, 0x9933, 0x4444,
},

{
   0xaaaa, 0xaaa9, 0xa99b, 0x9ccf, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xa3aa, 0xaaa9, 0x99cf, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0x9a9a, 0x994c, 0xffff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xdaaa, 0xaaaa, 0xb99c, 0xcfff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaa99, 0xab99, 0xcfff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaaaa, 0x99b9, 0xccff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaaaa, 0xab99, 0x9cff, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaaaa, 0x9ab9, 0x9ccf, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaaaa, 0xaa9b, 0x9ccf, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaaa, 0xaaaa, 0xaab9, 0x99cc, 0xffff, 0xffff, 0xffff,
   0xaaaa, 0xaaa2, 0x2233, 0x33a9, 0x999c, 0xffff, 0xffff, 0xffff,
   0xaaa3, 0x1221, 0x1112, 0x4239, 0x999c, 0xffff, 0xffff, 0xffff,
   0x5221, 0x1115, 0x5114, 0x1139, 0x99cc, 0xcfff, 0xffff, 0xffff,
   0xed5d, 0xd22d, 0xe2d1, 0x104a, 0x9999, 0xcfff, 0xffff, 0xffff,
   0xdedd, 0xdddd, 0xdddd, 0x1013, 0x9b99, 0xccff, 0xffff, 0xffff,
   0x5ddd, 0xdddd, 0xdded, 0xd254, 0xa999, 0xccff, 0xffff, 0xffff,
   0x2ddd, 0xdddd, 0xdddd, 0xdeed, 0x9b99, 0x9cff, 0xffff, 0xffff,
   0x2ddd, 0xdddd, 0xddde, 0xdded, 0x3999, 0x9cff, 0xffff, 0xffff,
   0x22dd, 0xdddd, 0xdadd, 0xe5ed, 0x39b9, 0x9ccf, 0xffff, 0xffff,
   0x1011, 0x1ddd, 0xaddd, 0xeddd, 0x3999, 0x9ccf, 0xffff, 0xffff,
   0x1111, 0x1ddd, 0xddd5, 0x55e2, 0x49b9, 0x9ccf, 0xffff, 0xffff,
   0x1111, 0x12dd, 0xddd1, 0x1114, 0x3399, 0x9ccf, 0xffff, 0xffff,
   0x1111, 0x22dd, 0xdd10, 0x1112, 0x43b9, 0x99cc, 0xffff, 0xffff,
   0x1144, 0x2432, 0x2211, 0x1144, 0x1399, 0x99cc, 0xffff, 0xffff,
   0x1411, 0x4324, 0x1111, 0x1121, 0x4394, 0xc9cc, 0xffff, 0xffff,
   0x4414, 0x3333, 0x1111, 0x1411, 0x4334, 0x99cc, 0xffff, 0xffff,
   0x1113, 0x3444, 0x4111, 0x1111, 0x4444, 0xc9cc, 0xffff, 0xffff,
   0x4444, 0x4114, 0x1111, 0x1411, 0x444c, 0x4bcc, 0xffff, 0xffff,
   0x4444, 0x1114, 0x1414, 0x4111, 0x1444, 0x9b9c, 0xffff, 0xffff,
   0x1444, 0x1014, 0x1441, 0x4100, 0x4144, 0xcb9c, 0xffff, 0xffff,
   0x1144, 0x0014, 0x1111, 0x1401, 0x0444, 0x4b9c, 0xffff, 0xffff,
   0x1441, 0x4044, 0x0410, 0x4100, 0x044c, 0x9b9c, 0xffff, 0xffff,
},

{
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x8888, 0x7775, 0xe55d,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x6888, 0x8777, 0x555d,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x8688, 0x8877, 0x5555,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6668, 0x6888, 0x7777, 0x5d52,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6666, 0x8888, 0x8775, 0x555d,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6868, 0x8777, 0x5d52,
   0xffff, 0xffff, 0x8666, 0x6666, 0x6668, 0x6888, 0x8777, 0x5d55,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6686, 0x8688, 0x8777, 0x5252,
   0xffff, 0xffff, 0x8866, 0x6666, 0x6666, 0x6888, 0x7877, 0x55d5,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6688, 0x6888, 0x8777, 0x5522,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6666, 0x8688, 0x8877, 0x555d,
   0xffff, 0xffff, 0xf866, 0x6666, 0x6668, 0x6868, 0x8777, 0x7552,
   0xffff, 0xffff, 0xf886, 0x6666, 0x6686, 0x8888, 0x8877, 0x7552,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6668, 0x6888, 0x8777, 0x7555,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6666, 0x8688, 0x8887, 0x7755,
   0xffff, 0xffff, 0xff86, 0x6666, 0x6668, 0x6888, 0x8877, 0x7755,
   0xffff, 0xffff, 0xff88, 0x6666, 0x6666, 0x8888, 0x8787, 0x7775,
   0xffff, 0xffff, 0xfff8, 0x6666, 0x6666, 0x6668, 0x8877, 0xe7ee,
   0xffff, 0xffff, 0xfff8, 0x6666, 0x6668, 0x6888, 0x8878, 0x777e,
   0xffff, 0xffff, 0xfff8, 0x8666, 0x6666, 0x8668, 0x8788, 0xe7ee,
   0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6886, 0x887e, 0x777e,
   0xffff, 0xffff, 0xffff, 0x8666, 0x6666, 0x6688, 0x6888, 0x7e7e,
   0xffff, 0xffff, 0xffff, 0xf866, 0x6666, 0x6866, 0x8887, 0x87e7,
   0xffff, 0xffff, 0xffff, 0xf866, 0x6666, 0x6668, 0x8888, 0x777e,
   0xffff, 0xffff, 0xffff, 0xf886, 0x6666, 0x6868, 0x6887, 0x8e8e,
   0xffff, 0xffff, 0xffff, 0xff86, 0x6666, 0x6686, 0x8888, 0x78e7,
   0xffff, 0xffff, 0xffff, 0xff88, 0x6666, 0x6668, 0x6888, 0x8777,
   0xffff, 0xffff, 0xffff, 0xfff8, 0x6666, 0x6686, 0x8688, 0x7877,
   0xffff, 0xffff, 0xffff, 0xfff8, 0x8666, 0x6668, 0x6888, 0x8777,
   0xffff, 0xffff, 0xffff, 0xffff, 0x8866, 0x6666, 0x8868, 0x8877,
   0xffff, 0xffff, 0xffff, 0xffff, 0xf866, 0x6668, 0x6688, 0x8787,
   0xffff, 0xffff, 0xffff, 0xffff, 0xf886, 0x6666, 0x6868, 0x8877,
},

{
   0x2252, 0x2222, 0x233a, 0xaaaa, 0xa333, 0x2323, 0x2333, 0x3a33,
   0x2222, 0x2223, 0x22aa, 0xaaaa, 0x3222, 0x3222, 0x2232, 0x33a3,
   0xd522, 0x2222, 0x2aba, 0xaba3, 0x2323, 0x2333, 0x3333, 0x3333,
   0x2222, 0x2332, 0x2aaa, 0xaa32, 0x3233, 0xaaa3, 0x3233, 0x3aa3,
   0x5222, 0xa222, 0x3333, 0x3323, 0x232a, 0x3aa3, 0x3a33, 0xa333,
   0x2222, 0xdaa3, 0x2323, 0x2232, 0x2333, 0x33aa, 0x33aa, 0x3323,
   0xd222, 0x2a3a, 0x3232, 0x3221, 0x1223, 0xa333, 0x333a, 0x3333,
   0x2222, 0x32a2, 0x3aaa, 0x3211, 0x1122, 0x3a33, 0x33a3, 0xa333,
   0x2222, 0x2223, 0xa333, 0x3210, 0x0001, 0x2232, 0x3a33, 0x3a33,
   0x5222, 0x2222, 0x2233, 0x2110, 0x0001, 0x112a, 0x3aaa, 0x3aa4,
   0x2222, 0x2222, 0x1222, 0x3100, 0x0000, 0x0113, 0x33aa, 0x33a3,
   0x2522, 0x2221, 0x1111, 0x1110, 0x0000, 0x0012, 0x33a9, 0xa3a3,
   0x2222, 0x2212, 0x1100, 0x0101, 0x0000, 0x0002, 0x33aa, 0x3a3b,
   0x2222, 0x2121, 0x1000, 0x1010, 0x0000, 0x0001, 0x3333, 0x33aa,
   0x5222, 0x2211, 0x1110, 0x0000, 0x1000, 0x0001, 0x2333, 0x3333,
   0x5122, 0x2212, 0x1000, 0x0001, 0x0000, 0x0001, 0x2333, 0x3a33,
   0x5551, 0x1121, 0x0000, 0x0010, 0x0000, 0x0001, 0x2332, 0x3333,
   0xeee5, 0x1111, 0x1000, 0x0011, 0x0000, 0x0001, 0x1234, 0x2333,
   0xeeee, 0x5101, 0x0000, 0x1110, 0x0000, 0x0001, 0x1424, 0x4433,
   0xeeee, 0xe501, 0x0101, 0x1110, 0x0000, 0x0001, 0x1114, 0x1334,
   0xeeee, 0xe510, 0x1111, 0x1100, 0x0000, 0x0001, 0x1114, 0x1434,
   0x7eee, 0xeee1, 0x1111, 0x1000, 0x0000, 0x0011, 0x1111, 0x1433,
   0xeeee, 0xee55, 0x0000, 0x0000, 0x0000, 0x0011, 0x0111, 0x1144,
   0xeeee, 0xe500, 0x0000, 0x0000, 0x0000, 0x0000, 0x1111, 0x1144,
   0x7eee, 0xee50, 0x0000, 0x0000, 0x0000, 0x0011, 0x0111, 0x1441,
   0xeeee, 0xee70, 0x0000, 0x0000, 0x0000, 0x0001, 0x1111, 0x1141,
   0xe7ee, 0xe750, 0x0000, 0x0000, 0x0000, 0x0000, 0x1111, 0x1141,
   0x77ee, 0xee75, 0x0000, 0x0000, 0x0000, 0x0000, 0x0111, 0x1141,
   0xee7e, 0xeee7, 0x0000, 0x0000, 0x0000, 0x0000, 0x1111, 0x1424,
   0x7ee7, 0xeee7, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001, 0x1233,
   0x77ee, 0xeee5, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x1142,
   0xee7e, 0xeeee, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001, 0x1124,
},

{
   0x1101, 0x1114, 0x4433, 0x3933, 0x99ab, 0x39b3, 0xb333, 0x4140,
   0x4110, 0x0011, 0x4443, 0x3393, 0x9b9b, 0xba9b, 0x3b33, 0x4041,
   0x3110, 0x0014, 0x1444, 0x9399, 0x3aba, 0xb9a9, 0xbb94, 0x4404,
   0x3410, 0x0040, 0x1443, 0x39a9, 0xabbb, 0xb3bb, 0xab99, 0x4444,
   0x1440, 0x0000, 0x4433, 0x399a, 0xbbbb, 0xabba, 0xbba9, 0x4444,
   0x3441, 0x0000, 0x0443, 0x9b39, 0xabbb, 0xbabb, 0xbb99, 0x3444,
   0x2344, 0x1000, 0x0433, 0x33ba, 0xbbbb, 0xbbbb, 0xbb99, 0x4449,
   0x4341, 0x4000, 0x4443, 0x3993, 0xbbbb, 0xbbbb, 0xbb93, 0x9499,
   0x3443, 0x4444, 0x4443, 0x999b, 0xbbbb, 0xbbbb, 0xbb39, 0x4999,
   0x4143, 0x3444, 0x4433, 0x3993, 0xbbbb, 0xbbbb, 0xb999, 0x9999,
   0x3333, 0x3441, 0x222d, 0xddaa, 0xabbb, 0xbbbb, 0xb999, 0x999b,
   0x33a9, 0x334e, 0xeeed, 0xdddd, 0xdabb, 0xbbbb, 0xb999, 0x9999,
   0x3a93, 0x933d, 0xdedd, 0xdded, 0xddaa, 0xabbb, 0x9999, 0x9999,
   0xaadd, 0xa2d2, 0xdeed, 0xeddd, 0xdddd, 0xdabb, 0x9999, 0x9999,
   0xaddd, 0xdded, 0xdeee, 0xeede, 0xdddd, 0xddd3, 0x9999, 0x9939,
   0x3333, 0x3393, 0xeeee, 0xeded, 0xeddd, 0xdded, 0x9499, 0x9999,
   0x3433, 0x3434, 0xeeee, 0xeeee, 0xdeee, 0xddee, 0xd999, 0x9999,
   0x4444, 0x442e, 0xeeee, 0xeeee, 0xdded, 0xeeed, 0x2999, 0x9993,
   0x4334, 0x34ee, 0xeeee, 0xeeee, 0xeedd, 0xeedd, 0x9999, 0x9349,
   0x4344, 0x445e, 0xeeee, 0xeeee, 0xeded, 0xeded, 0xda93, 0xd399,
   0x4444, 0x44ee, 0xeeee, 0xeeee, 0xeede, 0xdeee, 0xdedd, 0xd9bb,
   0x4444, 0x4dee, 0xeeee, 0xeeee, 0xeeee, 0xeeee, 0xeeee, 0xdd3b,
   0x4444, 0x4dee, 0xeeee, 0xeeee, 0xeeee, 0xeeee, 0xedee, 0xeed3,
   0x4444, 0x4249, 0x2dee, 0xeeee, 0xeeee, 0xeeee, 0xdeed, 0xdee2,
   0x4144, 0x4444, 0x494e, 0xeee8, 0xeeee, 0xeeee, 0xeeee, 0xd299,
   0x4414, 0x1444, 0x4494, 0x2eee, 0xeeee, 0xee7e, 0xeeee, 0xd999,
   0x1441, 0x4444, 0x9444, 0x44c1, 0xee7e, 0xe8e8, 0xeeee, 0x4939,
   0x4144, 0x4444, 0x4444, 0x4444, 0xc0d4, 0x1eee, 0xeeee, 0x3939,
   0x4444, 0x4444, 0x4444, 0x4494, 0x4949, 0xdeee, 0xeddd, 0xd993,
   0x4144, 0x4444, 0x4444, 0x4499, 0x9999, 0x4edd, 0x9499, 0xa999,
   0x4411, 0x4444, 0x4444, 0x4439, 0x3999, 0x9949, 0x4999, 0x9999,
   0x3144, 0x1444, 0x4444, 0x4993, 0x9939, 0x9494, 0x4939, 0x99b9,
},

{
   0x4114, 0x0044, 0x4000, 0x4140, 0x4044, 0x9b9c, 0xffff, 0xffff,
   0x0044, 0x4004, 0x4000, 0x1410, 0x0449, 0x9b9c, 0xffff, 0xffff,
   0x4144, 0x4400, 0x4400, 0x1444, 0x0449, 0x9b9c, 0xffff, 0xffff,
   0x4443, 0x4100, 0x1400, 0x4400, 0x4449, 0x9b9c, 0xffff, 0xffff,
   0x4939, 0x4414, 0x4114, 0x4104, 0x0499, 0x9b9c, 0xffff, 0xffff,
   0x9399, 0x9344, 0x4444, 0x4400, 0x4449, 0xbbcc, 0xffff, 0xffff,
   0x3933, 0x9999, 0x3444, 0x4404, 0x0499, 0x9bcc, 0xffff, 0xffff,
   0x9939, 0x3333, 0x4441, 0x4440, 0xc499, 0x9bcc, 0xffff, 0xffff,
   0xb993, 0x3333, 0x4440, 0x4444, 0x4499, 0x9bcc, 0xffff, 0xffff,
   0xb939, 0x4344, 0x4401, 0x1444, 0x4999, 0xbbcc, 0xffff, 0xffff,
   0x9993, 0x9444, 0x4040, 0x4444, 0x4499, 0xb9cf, 0xffff, 0xffff,
   0x9999, 0x4444, 0x4404, 0x4444, 0x499b, 0xb9cf, 0xffff, 0xffff,
   0x9934, 0x9494, 0x4444, 0x4444, 0x999b, 0xbccf, 0xffff, 0xffff,
   0x9999, 0x9944, 0x4444, 0x9494, 0x999b, 0xbccf, 0xffff, 0xffff,
   0x9999, 0x9999, 0x4499, 0x9949, 0x99bb, 0xbcff, 0xffff, 0xffff,
   0x999b, 0x9949, 0x4939, 0x4494, 0x99bb, 0x9cff, 0xffff, 0xffff,
   0x9999, 0x9999, 0x9944, 0x9449, 0x999b, 0xccff, 0xffff, 0xffff,
   0x99b9, 0x9393, 0x9394, 0x4999, 0x999b, 0xccff, 0xffff, 0xffff,
   0x9999, 0xb999, 0x3949, 0x939a, 0x9bbc, 0xcfff, 0xffff, 0xffff,
   0xbbbb, 0xb993, 0x343a, 0xddd9, 0x999c, 0xcfff, 0xffff, 0xffff,
   0xbb3b, 0x3933, 0xdddd, 0xddab, 0x999c, 0xcfff, 0xffff, 0xffff,
   0xbb9b, 0xb3dd, 0xdddd, 0xdaa9, 0x9b9c, 0xffff, 0xffff, 0xffff,
   0x9ab9, 0xaded, 0xdddd, 0xdabb, 0x9bcc, 0xffff, 0xffff, 0xffff,
   0x9b9b, 0xdddd, 0xdddd, 0xab99, 0xb9cf, 0xffff, 0xffff, 0xffff,
   0x9bba, 0xdddd, 0xdddd, 0xbb9b, 0xbccf, 0xffff, 0xffff, 0xffff,
   0x343a, 0xadaa, 0xaada, 0xb9bb, 0x9cff, 0xffff, 0xffff, 0xffff,
   0x3add, 0xaada, 0xaabb, 0x99bb, 0xccff, 0xffff, 0xffff, 0xffff,
   0x93ad, 0xdaaa, 0xbbbb, 0x9bbc, 0xcfff, 0xffff, 0xffff, 0xffff,
   0x999a, 0xdaab, 0xbbbb, 0xbb9c, 0xcfff, 0xffff, 0xffff, 0xffff,
   0x393a, 0xabbb, 0xbbbb, 0xbbcc, 0xffff, 0xffff, 0xffff, 0xffff,
   0x9999, 0x9bbb, 0xbbbb, 0xb9cf, 0xffff, 0xffff, 0xffff, 0xffff,
   0x9999, 0x9bbb, 0xbbbb, 0xbccf, 0xffff, 0xffff, 0xffff, 0xffff,
},

{
   0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6686, 0x8686, 0x8787,
   0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8666, 0x6888, 0x6888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8666, 0x8668, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8866, 0x6888, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf886, 0x6868, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6686, 0x8887,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8668, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8886, 0x6888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf886, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff88, 0x6888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8, 0x8688,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x8888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xf888,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfff8,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
},

{
   0x77e7, 0xeeee, 0xe500, 0x0000, 0x0000, 0x0000, 0x0001, 0x1142,
   0x7878, 0x7eee, 0xee50, 0x0010, 0x0000, 0x0000, 0x0000, 0x1111,
   0x777e, 0x77ee, 0xeee0, 0x0001, 0x0000, 0x0000, 0x0000, 0x1111,
   0x8877, 0x8e77, 0xe555, 0x0111, 0x1111, 0x0000, 0x0000, 0x0111,
   0x8777, 0x77e7, 0x5001, 0x1112, 0x1111, 0x0000, 0x0000, 0x0001,
   0x8877, 0x7777, 0x5522, 0x2101, 0x1111, 0x1000, 0x0000, 0x0001,
   0x7788, 0x777e, 0x5521, 0x0000, 0x1110, 0x0000, 0x0000, 0x0001,
   0x8877, 0x77e7, 0x7551, 0x5100, 0x0011, 0x0110, 0x0000, 0x0011,
   0x7777, 0x7777, 0x7755, 0x1051, 0x0110, 0x1011, 0x1000, 0x1100,
   0x8877, 0x7575, 0x7550, 0x0000, 0x1111, 0x1111, 0x0010, 0x0000,
   0x8887, 0x7755, 0x5505, 0x5515, 0x1511, 0x1101, 0x1000, 0x1010,
   0x8887, 0x7777, 0x5555, 0x0121, 0x1111, 0x2101, 0x0001, 0x0000,
   0x8887, 0x8770, 0x7055, 0x5222, 0x2015, 0x1100, 0x0000, 0x0001,
   0x8888, 0x7777, 0x5555, 0x5222, 0x2111, 0x2110, 0x0000, 0x0101,
   0x8888, 0x8777, 0x7755, 0x2522, 0x2221, 0x2111, 0x1111, 0x1011,
   0xff88, 0x8877, 0x7555, 0x5522, 0x2222, 0x1111, 0x1011, 0x1010,
   0xfff8, 0x8887, 0x0755, 0x5222, 0x2222, 0x4100, 0x0110, 0x0101,
   0xffff, 0xf888, 0x8555, 0x5522, 0x2122, 0x2110, 0x0011, 0x1011,
   0xffff, 0xfff8, 0x8875, 0x5552, 0x2211, 0x4211, 0x1111, 0x1142,
   0xffff, 0xffff, 0xf787, 0x7552, 0x5222, 0x2242, 0x4441, 0x4444,
   0xffff, 0xffff, 0xffff, 0x8755, 0xc522, 0x4424, 0x444c, 0x4494,
   0xffff, 0xffff, 0xffff, 0xff87, 0x70c5, 0xcd49, 0xd944, 0x4c4c,
   0xffff, 0xffff, 0xffff, 0xffff, 0xff75, 0x7c5c, 0x4c99, 0x9494,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xff55, 0xc5cc, 0xcccc,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
},

{
   0x4411, 0x4414, 0x4444, 0x9939, 0x3993, 0x4949, 0x9999, 0x9933,
   0x4111, 0x1110, 0x1444, 0x3999, 0x9999, 0x9939, 0x3939, 0x3939,
   0x1001, 0x1444, 0x1444, 0x339a, 0xab93, 0x9393, 0x9393, 0x3339,
   0x1001, 0x1414, 0x4443, 0x3333, 0x9339, 0x3333, 0x3934, 0x4944,
   0x1011, 0x4443, 0x3333, 0x3399, 0xa393, 0x9939, 0x3444, 0x4444,
   0x1101, 0x1433, 0x3333, 0x33aa, 0x9a39, 0x3934, 0x4444, 0x4449,
   0x1111, 0x1242, 0x433a, 0x9ab3, 0x393a, 0x9344, 0x4004, 0x4994,
   0x1111, 0x4142, 0x333a, 0xab33, 0x3333, 0x3444, 0x0444, 0x4999,
   0x1124, 0x2223, 0x3aaa, 0xb344, 0x4434, 0x4144, 0x4444, 0x99bb,
   0x1211, 0x2433, 0x333a, 0x3101, 0x1410, 0x0444, 0x4449, 0x9bbb,
   0x1111, 0x1223, 0x3333, 0x4101, 0x1400, 0x0144, 0x4449, 0x9bbb,
   0x1111, 0x2233, 0x3333, 0x3444, 0x4000, 0x4444, 0x999b, 0xbbbb,
   0x1122, 0x233a, 0xa333, 0x3344, 0x4444, 0x4449, 0x499b, 0xbbbb,
   0x1112, 0x23a3, 0x333a, 0x3343, 0x3344, 0x4449, 0x99bb, 0xbbcc,
   0x1222, 0x3232, 0x23aa, 0xa33a, 0x9399, 0x9c99, 0x9b99, 0x9ccc,
   0x1124, 0x4114, 0x3339, 0x3339, 0x9b99, 0x4999, 0x999c, 0xccff,
   0x1211, 0x1111, 0x4333, 0x439a, 0x9999, 0x99c9, 0xc9cc, 0xcfff,
   0x1411, 0x1114, 0x4433, 0x9999, 0x999c, 0x9cb9, 0xcccf, 0xffff,
   0x4444, 0x1444, 0x4949, 0x9999, 0x9999, 0x99cc, 0xcfff, 0xffff,
   0x4444, 0x4444, 0x4499, 0x9999, 0x99cc, 0xcccf, 0xffff, 0xffff,
   0x944c, 0x4c4c, 0x9999, 0x9999, 0xcccc, 0xcfff, 0xffff, 0xffff,
   0x4c44, 0xc999, 0x999c, 0x9ccc, 0xccff, 0xffff, 0xffff, 0xffff,
   0xc4cc, 0x9ccc, 0xcccc, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xcccc, 0xcccc, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
},

{
   0x3999, 0x99bb, 0xbbbb, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x3939, 0x9bbb, 0xbbb9, 0xcfff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x4449, 0xbbbb, 0xbbbc, 0xcfff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x4449, 0xbbbb, 0xbbcc, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x499b, 0xbbbb, 0xbccf, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x999b, 0xbbbb, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0x9bbb, 0xbbbc, 0xcfff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xbbbb, 0xbbcc, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xbbbb, 0xb9cf, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xbbbb, 0xccff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xbbbc, 0xcfff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xbccc, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xcccf, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xcfff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
   0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff,
}
};

int main()
{
   MMIO(VGA_STATE) &= ~VGA_EN_HW_CURSOR; //hide cursor
   qmon_vga_cls();

   sprite_clear_all();

   // Enable sprites
   MMIO(VGA_STATE) |= VGA_EN_SPRITE;

   // Set background color to white
   MMIO(VGA_PALETTE_OFFS) = VGA_PALETTE_OFFS_USER;
   MMIO(VGA_PALETTE_ADDR) = VGA_PALETTE_OFFS_USER + 0x10;
   MMIO(VGA_PALETTE_DATA) = VGA_COLOR_WHITE;

   int offset_x = 100*256;
   int offset_y = 0;

   for (int i=0; i<16; ++i)
   {
      sprite_set_palette(i,  palette);
      sprite_set_bitmap(i,   bitmaps[i]);
      sprite_set_config(i,   VGA_SPRITE_CSR_VISIBLE);
   }

   while (1)
   {
      while (MMIO(VGA_SCAN_LINE) != 480) {}

      int pos_x = 320 + offset_x/256;
      int pos_y = 240 + offset_y/256;
      for (int i=0; i<16; ++i)
      {
         sprite_set_position(i, pos_x-64+(~i%4)*32, pos_y-64+(i/4)*32);
      }

      offset_y -= offset_x/256;
      offset_x += offset_y/256;

      if (MMIO(IO_UART_SRA) & 1)
      {
         unsigned int tmp = MMIO(IO_UART_RHRA);
         break;
      }
      if (MMIO(IO_KBD_STATE) & KBD_NEW_ANY)
      {
         unsigned int tmp = MMIO(IO_KBD_DATA);
         break;
      }
   }

   return 0;
}

