/*  VGA Sprite demonstration
 *
 *  This program demonstrates bouncing balls using all 128 sprites.
 *
 *  How to compile: qvc demo_sprite_balls.c sprite.c rand.c images.c stat.c -O3 -c99
 *
 *  done by MJoergen in September 2020
*/

#include <stdio.h>

#include "qmon.h"
#include "sysdef.h"
#include "sprite.h"
#include "rand.h"
#include "images.h"
#include "stat.h"

// convenient mechanism to access QNICE's Memory Mapped IO registers
#define MMIO( __x ) *((unsigned int volatile *) __x )

#define VEL_SCALE 256
#define POS_SCALE 32

typedef struct
{
   int x;
   int y;
} t_vec;

typedef struct
{
   long x;
   long y;
} t_longvec;

typedef struct
{
   t_vec                 pos_scaled;
   t_vec                 vel_scaled;
   unsigned int          radius_scaled;
   unsigned int          mass;
   const t_sprite_bitmap *sprite_bitmap;
   unsigned int          color;
   int                   collided;
} t_ball;

#define NUM_SPRITES 45

t_ball balls[NUM_SPRITES];

static void init_all_sprites()
{
   // Enable sprites
   MMIO(VGA_STATE) |= VGA_EN_SPRITE;

   // Initialize each sprite
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      int image_index = my_rand()%NUM_IMAGES;

      balls[i].pos_scaled.x  = (my_rand()%(640-64)+32)*POS_SCALE;
      balls[i].pos_scaled.y  = (my_rand()%(480-64)+32)*POS_SCALE;
      balls[i].vel_scaled.x  = (my_rand()%VEL_SCALE-VEL_SCALE/2)*4;
      balls[i].vel_scaled.y  = (my_rand()%VEL_SCALE-VEL_SCALE/2)*4;
      balls[i].radius_scaled = images[image_index].radius_scaled*POS_SCALE;
      balls[i].mass          = images[image_index].mass;
      balls[i].sprite_bitmap = images[image_index].sprite_bitmap;
      balls[i].color         = (my_rand()&0x7FFF) | 0xC63; // Avoid darks colors
      balls[i].collided      = 0;

      t_sprite_palette palette = sprite_palette_transparent;
      palette[1] = balls[i].color;
      sprite_set_palette(4+i, palette);
      sprite_set_bitmap(4+i, *(balls[i].sprite_bitmap));
      sprite_set_config(4+i, VGA_SPRITE_CSR_VISIBLE);
   }
} // init_all_sprites

static t_vec calcNewVelocity(int mass1, int mass2, t_vec pos1, t_vec pos2, t_vec vel1, t_vec vel2)
{
   t_longvec delta_pos = {.x=pos1.x-pos2.x, .y=pos1.y-pos2.y};
   t_longvec delta_vel = {.x=vel1.x-vel2.x, .y=vel1.y-vel2.y};

   long dvdc = (delta_pos.x*delta_vel.x + delta_pos.y*delta_vel.y)/VEL_SCALE;
   long dcdc = (delta_pos.x*delta_pos.x + delta_pos.y*delta_pos.y)/VEL_SCALE;

   t_vec result = vel1;
   if (dvdc < 0)
   {
      long divisor = dcdc*(mass1+mass2);
      long dividend = 2L*(-dvdc)*mass2;

      long dx = dividend*delta_pos.x;
      if (dx > 0)
         dx += divisor/2;
      else
         dx -= divisor/2;

      long dy = dividend*delta_pos.y;
      if (dy > 0)
         dy += divisor/2;
      else
         dy -= divisor/2;

      result.x += dx/divisor;
      result.y += dy/divisor;
   }

   return result;
}

static void update()
{
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      t_ball *pBall = &balls[i];
      pBall->collided = 0;
   }

   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      t_ball *pBall = &balls[i];

      pBall->pos_scaled.x += (long)pBall->vel_scaled.x*POS_SCALE/VEL_SCALE;
      pBall->pos_scaled.y += (long)pBall->vel_scaled.y*POS_SCALE/VEL_SCALE;

      if (pBall->pos_scaled.x < pBall->radius_scaled && pBall->vel_scaled.x < 0)
      {
         pBall->pos_scaled.x = pBall->radius_scaled;
         pBall->vel_scaled.x = -pBall->vel_scaled.x;
      }

      if (pBall->pos_scaled.x >= 640*POS_SCALE-pBall->radius_scaled && pBall->vel_scaled.x > 0)
      {
         pBall->pos_scaled.x = 640*POS_SCALE-1-pBall->radius_scaled;
         pBall->vel_scaled.x = -pBall->vel_scaled.x;

      }

      if (pBall->pos_scaled.y < pBall->radius_scaled && pBall->vel_scaled.y < 0)
      {
         pBall->pos_scaled.y = pBall->radius_scaled;
         pBall->vel_scaled.y = -pBall->vel_scaled.y;
      }

      if (pBall->pos_scaled.y >= 480*POS_SCALE-pBall->radius_scaled && pBall->vel_scaled.y > 0)
      {
         pBall->pos_scaled.y = 480*POS_SCALE-1-pBall->radius_scaled;
         pBall->vel_scaled.y = -pBall->vel_scaled.y;
      }

      for (unsigned int j=i+1; j<NUM_SPRITES; ++j)
      {
         t_ball *pOtherBall = &balls[j];

         t_longvec diff_pos_scaled;
         diff_pos_scaled.x = pOtherBall->pos_scaled.x - pBall->pos_scaled.x;
         diff_pos_scaled.y = pOtherBall->pos_scaled.y - pBall->pos_scaled.y;

         long sum_r_scaled = pBall->radius_scaled + pOtherBall->radius_scaled;

         if ((long)diff_pos_scaled.x*diff_pos_scaled.x +
             (long)diff_pos_scaled.y*diff_pos_scaled.y <
             (long)sum_r_scaled*sum_r_scaled)
         {
            // The two balls have collided
            pBall->collided = 1;
            pOtherBall->collided = 1;

            t_vec vel_scaled = calcNewVelocity(
                  pBall->     mass,
                  pOtherBall->mass,
                  pBall->     pos_scaled,
                  pOtherBall->pos_scaled,
                  pBall->     vel_scaled,
                  pOtherBall->vel_scaled);

            pOtherBall->vel_scaled = calcNewVelocity(
                  pOtherBall->mass,
                  pBall->     mass,
                  pOtherBall->pos_scaled,
                  pBall->     pos_scaled,
                  pOtherBall->vel_scaled,
                  pBall->     vel_scaled);

            pBall->vel_scaled = vel_scaled;
         }
      }
   }
} // update

static void draw()
{
   for (unsigned int i=0; i<NUM_SPRITES; ++i)
   {
      t_ball *pBall = &balls[i];

      int pos_x = pBall->pos_scaled.x/POS_SCALE - 16;
      int pos_y = pBall->pos_scaled.y/POS_SCALE - 16;

      // Configure sprite
      sprite_set_position(4+i, pos_x, pos_y);

      if (pBall->collided)
      {
         t_sprite_palette palette = sprite_palette_transparent;
         palette[1] = VGA_COLOR_WHITE;
         sprite_set_palette(4+i, palette);
      }
      else
      {
         t_sprite_palette palette = sprite_palette_transparent;
         palette[1] = balls[i].color;
         sprite_set_palette(4+i, palette);
      }
   }
} // draw

int main()
{
   MMIO(VGA_STATE) &= ~VGA_EN_HW_CURSOR; //hide cursor
   qmon_vga_cls();
   sprite_clear_all();
   printf("Bouncing balls!\n");
   printf("Press any key to stop\n");
   my_srand(MMIO(IO_CYC_LO));
   init_all_sprites();
   stat_clear();
   while (1)
   {
      // Wait until outside visible screen before updating hardware.
      while (MMIO(VGA_SCAN_LINE) < 480) {}
      draw();     // Update hardware

      update();   // Update internal state
      stat_update(MMIO(VGA_SCAN_LINE));   // Update statistics.
      if (MMIO(IO_UART_SRA) & 1)
         break;
   }
   printf("\nScanline statistics (which scanline have we reached before next draw)?\n");
   printf("Should all be below 480.\n");
   stat_show();

   qmon_gets();
   return 0;
} // main

