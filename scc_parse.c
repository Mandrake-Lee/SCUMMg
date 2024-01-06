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
 
#include "scc_parse.h"

/*
// Already included in scc_lex.h
void set_start_pos(YYLTYPE *llocp,int line,int column) {
  llocp->first_line = line+1;
  llocp->first_column = column;
}

void set_end_pos(YYLTYPE *llocp,int line,int column) {
  llocp->last_line = line+1;
  llocp->last_column = column;
}
*/
// WARNING: This function realloc the file to fit the new path in
void scc_parser_find_res(scc_parser_t* sccp, char** file_ptr) {
  int i;
  char* file;
  
  if(!file_ptr || !file_ptr[0]) return;
  file = file_ptr[0];
  
  if(sccp->res_path) {
    int file_len = strlen(file);
    struct stat st;
    for(i = 0 ; sccp->res_path[i] ; i++) {
      int path_len = strlen(sccp->res_path[i]) + 1 + file_len + 1;
      char path[path_len];
      sprintf(path,"%s/%s",sccp->res_path[i],file);
      if(stat(path,&st) || !S_ISREG(st.st_mode)) continue;
      file_ptr[0] = realloc(file,path_len);
      strcpy(file_ptr[0],path);
      return;
    }
  }
}

void scc_parser_add_dep(scc_parser_t* sccp, char* dep) {
  int i;
  if(!sccp->num_deps)
    sccp->deps = malloc(sizeof(char*));
  else {
    for(i = 0 ; i < sccp->num_deps ; i++)
      if(!strcmp(sccp->deps[i],dep)) return;
    sccp->deps = realloc(sccp->deps,(sccp->num_deps+1)*sizeof(char*));
  }
  sccp->deps[sccp->num_deps] = strdup(dep);
  sccp->num_deps++;
}

scc_source_t* scc_parser_parse(scc_parser_t* sccp,char* file,char do_deps) {
  scc_source_t* src;

  if(do_deps) {
      sccp->lex->opened = (scc_lexer_opened_f)scc_parser_add_dep;
      sccp->lex->ignore_missing_include = 1;
  } else {
      sccp->lex->opened = NULL;
      sccp->lex->ignore_missing_include = 0;
  }

  if(!scc_lex_push_buffer(sccp->lex,file)) return NULL;

  sccp->ns = scc_ns_new(sccp->target);
  sccp->roobj_list = NULL;
  sccp->roobj = NULL;
  sccp->obj = NULL;
  sccp->local_vars = 0;
  sccp->local_scr = sccp->target->max_global_scr;
  sccp->cycl = 1;
  sccp->do_deps = do_deps;

  if(scc_parser_parse_internal(sccp)) return NULL;

  if(sccp->lex->error) {
    scc_log(LOG_ERR,"%s: %s\n",scc_lex_get_file(sccp->lex),sccp->lex->error);
    return NULL;
  }

  src = calloc(1,sizeof(scc_source_t));
  src->ns = sccp->ns;
  src->roobj_list = sccp->roobj_list;
  src->file = file;
  if(sccp->do_deps) {
    src->num_deps = sccp->num_deps;
    src->deps = sccp->deps;
    sccp->num_deps = 0;
    sccp->deps = NULL;
  }
  return src;
}

scc_parser_t* scc_parser_new(char** include, char** res_path,
                             int vm_version) {
  scc_target_t* target = scc_get_target(vm_version);
  scc_parser_t* p;

  if(!target) return NULL;

  p = calloc(1,sizeof(scc_parser_t));
  p->target = target;
  p->lex = scc_lex_new(scc_main_lexer,set_start_pos,set_end_pos,include);
  p->lex->userdata = p;
  p->res_path = res_path;
  return p;
}

int scc_parser_error(scc_parser_t* sccp,YYLTYPE *loc, const char *s)  /* Called by yyparse on error */
{
  scc_log(LOG_ERR,"%s: %s\n",scc_lex_get_file(sccp->lex),
          sccp->lex->error ? sccp->lex->error : s);
  return 0;
}

scc_func_t* scc_get_func(scc_parser_t* p, char* sym) {
	int i,j;

	if(!sym) return NULL;

	for(i = 0 ; p->target->func_list[i] ; i++) {
		scc_func_t* list = p->target->func_list[i];
		for(j = 0 ; list[j].sym ; j++) {
			if(strcmp(sym,list[j].sym)) continue;
			return &list[j];
		}
	}
	return NULL;
}

char* scc_statement_check_func(scc_call_t* c) {
	int n,min_argc = c->func->argc;
	scc_statement_t* a;
	// should be big enough
	static char func_err[2048];

	while(min_argc > 0 && (c->func->argt[min_argc-1] & SCC_FA_DEFAULT))
		min_argc--;

	if(c->argc > c->func->argc || c->argc < min_argc) {
		sprintf(func_err,"Function %s needs %d args, %d found.\n",
		c->func->sym,c->func->argc,c->argc);
		return func_err;
	}
  
	for(n = 0, a = c->argv ; a ; n++, a = a->next) {
		if(c->func->argt[n] == SCC_FA_VAL) {
			if(a->type == SCC_ST_STR ||
				a->type == SCC_ST_LIST) {
					sprintf(func_err,"Argument %d of call to %s is of the wrong type.\n",
						n+1,c->func->sym);
					return func_err;
			}
		} else if(c->func->argt[n] == SCC_FA_ARRAY) {
			if(a->type != SCC_ST_VAR ||	!(a->val.v.r->subtype & SCC_VAR_ARRAY)) {
				sprintf(func_err,"Argument %d of call to %s must be an array variable.\n",
				n+1,c->func->sym);
				return func_err;
			}

		} else if(c->func->argt[n] == SCC_FA_LIST &&
			a->type != SCC_ST_LIST) {
			sprintf(func_err,"Argument %d of %s must be a list.\n",
			n+1,c->func->sym);
			return func_err;
		} else if(c->func->argt[n] == SCC_FA_STR &&
			a->type != SCC_ST_STR) {
			sprintf(func_err,"Argument %d of %s must be a string.\n",
			n+1,c->func->sym);
			return func_err;
		}

	}

    return NULL;
}