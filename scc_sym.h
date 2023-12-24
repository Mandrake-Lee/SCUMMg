/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2024  Jorge Amorós-Argos
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
  * Declarations for the symbolic tree of the parse
  */
 #ifndef SCC_SYM_H
 #define SCC_SYM_H
 
 #include <stdint.h>
 
 typedef struct scc_symbol_st scc_symbol_t;
 typedef struct scc_sym_fix_st scc_sym_fix_t;

/// Symbol
struct scc_symbol_st {
  scc_symbol_t* next;

  /// Symbol type
  int type;
  /// Subtype, used for variable type and the like
  int subtype;
  /// Symbol name
  char* sym;
  
  /// Address, 0 for automatic allocation
  int addr;
  /// RID, used for auto-allocated address
  int rid;

  /// Child symbols for room
  scc_symbol_t* childs;
  /// Parent symbol
  scc_symbol_t* parent;

  /// Used by the linker
  char status;
};

/// Symbol fix
struct scc_sym_fix_st {
  scc_sym_fix_t* next;

  /// Offset of the code to fix
  uint32_t off;
  /// Symbol to use for the fix.
  scc_symbol_t* sym;
};
 
 
 #endif /* SCC_SYM_H */