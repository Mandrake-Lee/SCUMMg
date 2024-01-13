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

/// @defgroup scc Compiler
/**
 * @file scc_parse.h
 * @ingroup scc
 * @brief ScummC compiler
 */
 
/*
 * Hold the declarations exclusively for parsing purposes
 */
#ifndef SCC_PARSE_H
#define SCC_PARSE_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include "scc_sym.h"
#include "scc_code.h"
#include "scc_ns.h"
#include "scc_roobj.h"
#include "scc_param.h"
#include "scc_target.h"
#include "scc_lexer.h"
#include "scc_util.h"

/// @name Variable type
//@{
#define SCC_VOID        0
#define SCC_VAR_BIT     1
#define SCC_VAR_NIBBLE  2
#define SCC_VAR_BYTE    3
#define SCC_VAR_CHAR    4
#define SCC_VAR_WORD    5

#define SCC_VAR_ARRAY   0x100
//@}

/* Forward declaration of struct's & typedef's */
typedef struct scc_arg_st scc_arg_t;
typedef struct scc_verb_script_st scc_verb_script_t;
typedef struct scc_parser scc_parser_t;
typedef union scc_bison_val_s scc_bison_val_t;
typedef struct scc_parser scc_parser_t;


typedef struct scc_decl_st scc_decl_t;	/* Never in use? WOW! */



/* Prototype declaration of functions */
void scc_parser_find_res(scc_parser_t* sccpr, char** file_ptr);
void scc_parser_add_dep(scc_parser_t* sccpr, char* dep);
scc_source_t* scc_parser_parse(scc_parser_t* sccpr,char* file,char do_deps);
scc_parser_t* scc_parser_new(char** include, char** res_path,
                             int vm_version);
int scc_parser_error(scc_parser_t* sccpr,YYLTYPE *loc, const char *s);  /* Called by yyparse on error */
scc_func_t* scc_get_func(scc_parser_t* p, char* sym);
char* scc_statement_check_func(scc_call_t* c);

/* found in other modules declaration */
//int scc_parser_parse_internal(struct scc_parser *v_sccp);
//int scc_main_lexer(YYSTYPE *lvalp, YYLTYPE *llocp,scc_lex_t* lex);

/* Macros used exclusively in parse scc_parse.y file */
#define SCC_BOP(d,bop,a,cop,b) {                              \
  if(a->type == SCC_ST_VAL &&                                 \
     b->type == SCC_ST_VAL) {                                 \
    a->val.i = ((int16_t)a->val.i) bop ((int16_t)b->val.i);   \
    free(b);                                                  \
    d = a;                                                    \
  } else {                                                    \
    d = calloc(1,sizeof(scc_statement_t));                    \
    d->type = SCC_ST_OP;                                      \
    d->val.o.type = SCC_OT_BINARY;                            \
    d->val.o.op = cop;                                        \
    d->val.o.argc = 2;                                        \
    d->val.o.argv = a;                                        \
    a->next = b;                                              \
  }                                                           \
}

#define SCC_ABORT(at,msg...)  { \
  scc_log(LOG_ERR,"%s: ",scc_lex_get_file(sccp->lex));        \
  scc_log(LOG_ERR,msg); \
  YYABORT; \
}

/// Verb script
struct scc_verb_script_st {
  scc_verb_script_t* next;
  scc_symbol_t* sym;
  scc_instruct_t* inst;
};

//Only for bison YYSTYPE
typedef union scc_bison_val_s {
  int integer;
  char* str;
  char** strlist;
  scc_symbol_t* sym;
  scc_statement_t* st;
  scc_instruct_t* inst;
  scc_scr_arg_t* arg;
  scc_script_t* scr;
  scc_str_t* strvar;
  int* intlist;
  scc_verb_script_t* vscr;
} scc_bison_val_t;

typedef struct scc_parser {
  // targeted vm version
  scc_target_t* target;
  scc_lex_t* lex;
  scc_ns_t* ns;
  scc_roobj_t* roobj_list;
  scc_roobj_t* roobj;
  scc_roobj_obj_t* obj;
  int local_vars;
  int local_scr;
  int cycl;
  // resources include paths
  char** res_path;
  // deps
  char do_deps;
  int num_deps;
  char** deps;
} scc_parser_t;

#endif /* SCC_PARSE_H */