/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2024 Jorge Amorós-Argos
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */
 
#ifndef COST_PARSE_H
#define COST_PARSE_H

#include <stddef.h>
#include <cstdint.h>

#define COST_ABORT(at,msg...)  { \
  printf("Line %d, column %d: ",at.first_line,at.first_column); \
  printf(msg); \
  YYABORT; \
}

typedef union cost_bison_val cost_bison_val_t;

typedef union cost_bison_val {
	int integer;    // INTEGER, number
	char* str;      // STRING, ID
	int intpair[2];
	uint8_t* intlist;
	struct cost_cmd* cmd;
} cost_bison_val_t

typedef struct cost_pic cost_pic_t;
struct cost_pic {
	cost_pic_t* next;
	// name from the sym
	char* name;
	// number of references from limbs
	unsigned ref;
	// offset where it will be written
	unsigned offset;
	// global index for akos
	unsigned idx;
	// path/glob
	char* path;
	int is_glob;
	// params, they will be copied for globs
	int16_t rel_x,rel_y;
	int16_t move_x,move_y;

	uint16_t width,height;
	uint8_t* data;
	uint32_t data_size;
};


  static cost_pic_t* cur_pic = NULL;
  static cost_pic_t* pic_list = NULL;

#define COST_MAX_LIMBS 16
#define LIMB_MAX_PICTURES 0x70
#define COST_MAX_DIR 4

typedef struct cost_limb {
	char* name;
	unsigned num_pic;
	cost_pic_t* pic[LIMB_MAX_PICTURES];
} cost_limb_t;
  

static cost_limb_t limbs[COST_MAX_LIMBS];
static cost_limb_t* cur_limb = NULL;

#define COST_MAX_CMD_ARG 1

  // Show a picture
#define COST_CMD_DISPLAY      0x00
  // Play a sound?
#define COST_CMD_SOUND        0x70
  // Hide the track
#define COST_CMD_HIDE         0x79
  // Show the track
#define COST_CMD_SHOW         0x7A
  // Display nothing
#define COST_CMD_NOP          0x7B
  // Increment the anim counter
#define COST_CMD_COUNT        0x7C

typedef struct cost_cmd cost_cmd_t;

struct cost_cmd {
	cost_cmd_t* next;
	unsigned type;
	union {
		unsigned     u;
		int          i;
		cost_pic_t*  pic;
	} arg[COST_MAX_CMD_ARG];
};

#define COST_MAX_ANIMS 0x3F
#define COST_MAX_LIMB_CMDS 0x7F

typedef struct cost_limb_anim {
	unsigned len;
	unsigned flags;
	uint8_t cmd[COST_MAX_LIMB_CMDS];
	cost_cmd_t* cmd_list;
} cost_limb_anim_t;

typedef struct cost_anim_dir {
	unsigned limb_mask;
	cost_limb_anim_t limb[COST_MAX_LIMBS];
} cost_anim_dir_t;

typedef struct cost_anim {
	char* name;
	cost_anim_dir_t dir[COST_MAX_DIR];
} cost_anim_t;

static cost_anim_t anims[COST_MAX_ANIMS];
static cost_anim_t* cur_anim = NULL;
static cost_anim_dir_t* cur_dir = NULL;

#define COST_MAX_PALETTE_SIZE 32
static unsigned pal_size = 0;
static uint8_t pal[COST_MAX_PALETTE_SIZE];

// Default to no flip
static unsigned cost_flags = 0x80;
/*
static char* img_path = NULL;
static char* cost_output = NULL;
*/
static scc_fd_t* out_fd = NULL;
/*
// Output a AKOS instead of COST
static int akos = 0;

// Ouput a header
static char* header_name = NULL;
static char* symbol_prefix = NULL;
*/

/* prototype declaration of functions */
static int cost_pic_load(cost_pic_t* pic,char* file);

/*
	static cost_pic_t* find_pic(char* name) {
	cost_pic_t* p;
	for(p = pic_list ; p ; p = p->next)
	  if(!strcmp(name,p->name)) break;
	return p;
	}
*/
struct dir_map {
	char* name;
	unsigned id;
	} dir_map[] = {
	{ "W",   0 },
	{ "E",   1 },
	{ "S",   2 },
	{ "N",   3 },
	{ NULL,  0 }
};

struct anim_map {
	char* name;
	unsigned id;
	} anim_map[] = {
	{ "init",       1 },
	{ "walk",       2 },
	{ "stand",      3 },
	{ "talkStart",  4 },
	{ "talkStop",   5 },
	{ NULL, 0 }
};
  
#define ANIM_USER_START 6


#endif