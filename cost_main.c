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
#include "cost_parse_bison.h"
#include <stddef.h>
#include <stdio.h>
#include <string.h>

static char* cost_output = NULL;
static char* img_path = NULL;
// Output a AKOS instead of COST
static int akos = 0;
// Ouput a header
static char* symbol_prefix = NULL;
static char* header_name = NULL;

static scc_param_t scc_parse_params[] = {
	{ "o", SCC_PARAM_STR, 0, 0, &cost_output },
	{ "I", SCC_PARAM_STR, 0, 0, &img_path },
	{ "akos", SCC_PARAM_FLAG, 0, 1, &akos },
	{ "prefix", SCC_PARAM_STR, 0, 0, &symbol_prefix },
	{ "header", SCC_PARAM_STR, 0, 0, &header_name },
	{ "help", SCC_PARAM_HELP, 0, 0, &cost_help },
	{ NULL, 0, 0, 0, NULL }
};

int main (int argc, char** argv) {
  scc_cl_arg_t* files;
  char* out;

  files = scc_param_parse_argv(scc_parse_params,argc-1,&argv[1]);

  if(!files) scc_print_help(&cost_help,1);

  out = cost_output ? cost_output : "output.cost";
  out_fd = new_scc_fd(out,O_WRONLY|O_CREAT|O_TRUNC,0);
  if(!out_fd) {
	printf("Failed to open output file %s.\n",out);
	return -1;
  }

  cost_lex = scc_lex_new(cost_main_lexer,set_start_pos,set_end_pos,NULL);
  if(!scc_lex_push_buffer(cost_lex,files->val)) return -1;

  if(yyparse()) return -1;

  if(akos)
	akos_write(out_fd);
  else
	cost_write(out_fd);

  scc_fd_close(out_fd);

  if(header_name) {
	out_fd = new_scc_fd(header_name,O_WRONLY|O_CREAT|O_TRUNC,0);
	if(!out_fd) {
	  printf("Failed to open output file %s.\n",out);
	  return -1;
	}
	header_write(out_fd,symbol_prefix);
	scc_fd_close(out_fd);
  }

  return 0;
}
