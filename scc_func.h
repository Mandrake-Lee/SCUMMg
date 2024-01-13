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

/**
 * @file scc_func.h
 * @ingroup scc
 * @brief ScummC builtin functions
 */
#ifndef SCC_FUNC_H
#define SCC_FUNC_H


#include <stddef.h>
#include "scc_sym.h"
#include "scc_code.h"

// A define for the various print function families

#define PRINT(name,op) {                         \
    name "At", 0x##op##41, 0, 2, 0,      \
    { SCC_FA_VAL, SCC_FA_VAL}                    \
  },{                                            \
    name "Color", 0x##op##42, 0, 1, 0,   \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Clipped", 0x##op##43, 0, 1, 0, \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Center", 0x##op##45, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name "Left", 0x##op##47, 0, 0, 0,    \
    {}                                           \
  },{                                            \
    name "Overhead", 0x##op##48, 0, 0, 0,\
    {}                                           \
  },{                                            \
    name "Mumble", 0x##op##4A, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name , 0x##op##4B, 0, 1, 0,          \
    { SCC_FA_STR }                               \
  },{                                            \
    name "Begin", 0x##op##FE, 0, 0, 0,   \
    {}                                           \
  },{                                            \
    name "End", 0x##op##FF, 0, 0, 0,     \
    {} \
  }

#define PRINT2(name,op) {                        \
    name "At", 0x##op##41, 0, 2, 0,      \
    { SCC_FA_VAL, SCC_FA_VAL}                    \
  },{                                            \
    name "Color", 0x##op##42, 0, 1, 0,   \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Clipped", 0x##op##43, 0, 1, 0, \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Center", 0x##op##45, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name "Left", 0x##op##47, 0, 0, 0,    \
    {}                                           \
  },{                                            \
    name "Overhead", 0x##op##48, 0, 0, 0,\
    {}                                           \
  },{                                            \
    name "Mumble", 0x##op##4A, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name , 0x##op##4B, 0, 1, 0,          \
    { SCC_FA_STR }                               \
  },{                                            \
    name "Begin", 0x##op##FE, 0, 1, 0,   \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "End", 0x##op##FF, 0, 0, 0,     \
    {} \
  }

#define PRINT3(name,op) {                        \
    name "At", 0x##op##41, 0, 2, 0,      \
    { SCC_FA_VAL, SCC_FA_VAL}                    \
  },{                                            \
    name "Color", 0x##op##42, 0, 1, 0,   \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Clipped", 0x##op##43, 0, 1, 0, \
    { SCC_FA_VAL }                               \
  },{                                            \
    name "Center", 0x##op##45, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name "Left", 0x##op##47, 0, 0, 0,    \
    {}                                           \
  },{                                            \
    name "Overhead", 0x##op##48, 0, 0, 0,\
    {}                                           \
  },{                                            \
    name "Mumble", 0x##op##4A, 0, 0, 0,  \
    {}                                           \
  },{                                            \
    name , 0x##op##4B, 0, 1, 0,          \
    { SCC_FA_STR }                               \
  },{                                            \
    name "End", 0x##op##FF, 0, 0, 0,     \
    {} \
  }




/* Global variables */
extern const scc_func_t* scc_func_v6[];
extern const scc_func_t* scc_func_v7[];


#endif