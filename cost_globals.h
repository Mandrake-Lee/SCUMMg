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
 
/*
 * TODO: This file holds the globals variables used for parsing the costumes
 * however the proper way should be to hold them into a structure and pass a 
 * pointer, as done in scc_parse.
 */
 
 
#ifndef COST_GLOBALS_H
#define COST_GLOBALS_H

#include <stddef.h>
#include <stdint.h>
#include "cost_parse.h"
#include "scc_fd.h"
#include "scc_param.h"

/* global variables forward declaration*/

extern cost_pic_t* cur_pic;
extern cost_pic_t* pic_list;
extern cost_limb_t limbs[];
extern cost_limb_t* cur_limb;
extern cost_anim_t anims[];
extern cost_anim_t* cur_anim;
extern cost_anim_dir_t* cur_dir;
extern unsigned pal_size;
extern uint8_t pal[];
// Default to no flip
extern unsigned cost_flags;
extern char* img_path;
extern scc_fd_t* out_fd;

extern char* cost_output;
extern char* img_path;
// Output a AKOS instead of COST
extern int akos;
// Ouput a header
extern char* symbol_prefix;
extern char* header_name;
//
extern struct dir_map dir_map[];
extern struct anim_map anim_map[];


extern scc_param_t scc_parse_params[];
 
#endif