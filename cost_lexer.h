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
 
#ifndef COST_LEXER_H
#define COST_LEXER_H
 
#include "config.h"

#include <stdlib.h>
#include <inttypes.h>
#include <string.h>

#include "scc_util.h"
#include "cost_lex_bison.h"
#include "cost_parse.h"
#include "scc_lex.h"

/* Macro below is redundant at scc_lexer; could be moved to scc_util.h */
#define CHECK_EOF(lx,ch)                               \
		if(ch == 0) {                                  \
			if(!lx->error)                             \
				scc_lex_error(lx,"Unexpected eof.");   \
			return 0;                                  \
		}

/* Function prototypes */
int cost_main_lexer(YYSTYPE *lvalp, YYLTYPE *llocp, scc_lex_t* lex);
void set_start_pos(YYLTYPE *llocp,int line,int column);
void set_end_pos(YYLTYPE *llocp,int line,int column);
  
 
 #endif