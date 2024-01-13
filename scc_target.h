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
 * Holds definitions for the compilation target
 * This is the outcome of the parsing
*/


#ifndef SCC_TARGET_H
#define SCC_TARGET_H

#include "scc_sym.h"
#include "scc_code.h"
#include "scc_func.h"
#include <stddef.h>
#include <stdint.h>

/* Global variables */
/*
extern const int scc_addr_max_v6[];
extern const int scc_addr_min_v6[];
extern const int scc_addr_max_v7[];
extern const int scc_addr_min_v7[];
extern const scc_target_t target_list[];
*/

scc_target_t* scc_get_target(int version);


#endif