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

#include "cost_globals.h"
#include "cost_help.h"

/* Initialization of global variables */
cost_pic_t* cur_pic = NULL;
cost_pic_t* pic_list = NULL;
cost_limb_t limbs[COST_MAX_LIMBS];
cost_limb_t* cur_limb = NULL;
cost_anim_t anims[COST_MAX_ANIMS];
cost_anim_t* cur_anim = NULL;
cost_anim_dir_t* cur_dir = NULL;
unsigned pal_size = 0;
uint8_t pal[COST_MAX_PALETTE_SIZE];
// Default to no flip
unsigned cost_flags = 0x80;
char* img_path;
scc_fd_t* out_fd = NULL;

char* cost_output = NULL;
char* img_path = NULL;
// Output a AKOS instead of COST
int akos = 0;
// Ouput a header
char* symbol_prefix = NULL;
char* header_name = NULL;

struct dir_map dir_map[] = {
	{ "W",   0 },
	{ "E",   1 },
	{ "S",   2 },
	{ "N",   3 },
	{ NULL,  0 }
};

struct anim_map anim_map[] = {
	{ "init",       1 },
	{ "walk",       2 },
	{ "stand",      3 },
	{ "talkStart",  4 },
	{ "talkStop",   5 },
	{ NULL, 0 }
};


scc_param_t scc_parse_params[] = {
	{ "o", SCC_PARAM_STR, 0, 0, &cost_output },
	{ "I", SCC_PARAM_STR, 0, 0, &img_path },
	{ "akos", SCC_PARAM_FLAG, 0, 1, &akos },
	{ "prefix", SCC_PARAM_STR, 0, 0, &symbol_prefix },
	{ "header", SCC_PARAM_STR, 0, 0, &header_name },
	{ "help", SCC_PARAM_HELP, 0, 0, &cost_help },
	{ NULL, 0, 0, 0, NULL }
};