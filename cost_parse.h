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
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "scc_fd.h"
#include "cost_lexer.h"

#define COST_ABORT(at,msg...)  { \
  printf("Line %d, column %d: ",at.first_line,at.first_column); \
  printf(msg); \
  YYABORT; \
}

#define COST_MAX_LIMBS			16
#define LIMB_MAX_PICTURES		0x70
#define COST_MAX_DIR			4
#define COST_MAX_CMD_ARG		1
#define COST_CMD_DISPLAY		0x00	/* Show a picture */
#define COST_CMD_SOUND			0x70	/* Play a sound? */
#define COST_CMD_HIDE			0x79	/* Hide the track */
#define COST_CMD_SHOW			0x7A	/* Show the track */
#define COST_CMD_NOP			0x7B	/* Display nothing */
#define COST_CMD_COUNT			0x7C	/* Increment the anim counter */
#define COST_MAX_ANIMS			0x3F
#define COST_MAX_LIMB_CMDS		0x7F
#define COST_MAX_PALETTE_SIZE	32
#define ANIM_USER_START			6

/* Forward declaration of struct's & typedef's */
typedef union cost_bison_val cost_bison_val_t;
typedef struct cost_pic cost_pic_t;
typedef struct cost_limb cost_limb_t;
typedef struct cost_cmd cost_cmd_t;
typedef struct cost_limb_anim cost_limb_anim_t;
typedef struct cost_anim_dir cost_anim_dir_t;
typedef struct cost_anim cost_anim_t;
typedef struct cost_parser cost_parser_t;
struct dir_map;
struct anim_map;

/* Prototype declaration of functions */
int cost_pic_load(cost_pic_t* pic,char* file);
int cost_get_size(int *na,unsigned* coff,unsigned* aoff,unsigned* loff);
static int cost_get_pic_limb_id(int limb_n, cost_pic_t* pic);
static int cost_create_limbs(void);
int cost_write(scc_fd_t* fd);
int akos_write(scc_fd_t* fd);
int header_write(scc_fd_t* fd,char *prefix);
int cost_parser_error(scc_lex_t *cost_lex, YYLTYPE *llocp, const char *s);
cost_pic_t* find_pic(char* name);
cost_parser_t* cost_parser_new(void);


/* Complete declaration of struct's & typedef's */
typedef union cost_bison_val {
	int integer;    // INTEGER, number
	char* str;      // STRING, ID
	int intpair[2];
	uint8_t* intlist;
	struct cost_cmd* cmd;
} cost_bison_val_t;

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

typedef struct cost_limb {
	char* name;
	unsigned num_pic;
	cost_pic_t* pic[LIMB_MAX_PICTURES];
} cost_limb_t;

struct cost_cmd {
	cost_cmd_t* next;
	unsigned type;
	union {
		unsigned     u;
		int          i;
		cost_pic_t*  pic;
	} arg[COST_MAX_CMD_ARG];
};

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

struct dir_map {
	char* name;
	unsigned id;
	};
	
struct anim_map {
	char* name;
	unsigned id;
	};

typedef struct cost_parser {
	scc_lex_t *lex;
	cost_pic_t* cur_pic;
	cost_pic_t* pic_list;
	cost_limb_t limbs[COST_MAX_LIMBS];
	cost_limb_t* cur_limb;
	cost_anim_t anims[COST_MAX_ANIMS];
	cost_anim_t* cur_anim;
	cost_anim_dir_t* cur_dir;
	unsigned pal_size;
	uint8_t pal[COST_MAX_PALETTE_SIZE];
	// Default to no flip
	unsigned cost_flags;
	scc_fd_t* out_fd;

	char* cost_output;
	char* img_path;
} cost_parser_t;

#endif