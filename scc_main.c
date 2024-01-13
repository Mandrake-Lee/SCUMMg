/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2024 Jorge Amorós-Argos
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <string.h>
#include "scc_lex_bison.h"
#include "scc_parse.h"
//#include "scc_parse_api.h"
#include "scc_help.h"
static char* scc_output = NULL;
static char** scc_include = NULL;
static char** scc_res_path = NULL;
static int scc_do_deps = 0;
static int scc_vm_version = 6;

static scc_param_t scc_parse_params[] = {
  { "o", SCC_PARAM_STR, 0, 0, &scc_output },
  { "I", SCC_PARAM_STR_LIST, 0, 0, &scc_include },
  { "R", SCC_PARAM_STR_LIST, 0, 0, &scc_res_path },
  { "d", SCC_PARAM_FLAG, 0, 1, &scc_do_deps },
  { "v", SCC_PARAM_FLAG, LOG_MSG, LOG_V, &scc_log_level },
  { "vv", SCC_PARAM_FLAG, LOG_MSG, LOG_DBG, &scc_log_level },
  { "V", SCC_PARAM_INT, 6, 7, &scc_vm_version },
  { "help", SCC_PARAM_HELP, 0, 0, &scc_help },
  { NULL, 0, 0, 0, NULL }
};


int main (int argc, char** argv) {
  scc_cl_arg_t* files,*f;
  scc_parser_t* sccp;
  char* out;
  scc_source_t *src,*srcs = NULL;
  scc_roobj_t* scc_roobj;
  scc_fd_t* out_fd;
  int i;

  files = scc_param_parse_argv(scc_parse_params,argc-1,&argv[1]);

  if(!files) scc_print_help(&scc_help,1);

  sccp = scc_parser_new(scc_include,scc_res_path,scc_vm_version);

  for(f = files ; f ; f = f->next) {
    src = scc_parser_parse(sccp,f->val,scc_do_deps);
    if(!src) return 1;
    src->next = srcs;
    srcs = src;
  }

  out = scc_output ? scc_output : "output.roobj";
  out_fd = new_scc_fd(out,O_WRONLY|O_CREAT|O_TRUNC,0);
  if(!out_fd) {
    scc_log(LOG_ERR,"Failed to open output file %s.\n",out);
    return -1;
  }    

  if(scc_do_deps) {
    for(src = srcs ; src ; src = src->next) {
      char* pt = strrchr(src->file,'.');
      char* start = strrchr(src->file,'/');
      if(pt) pt[0] = '\0';
      if(start) start++;
      else start = src->file;
      scc_fd_printf(out_fd,"%s.roobj:",start);
      for(i = 0 ; i < src->num_deps ; i++)
        scc_fd_printf(out_fd," %s",src->deps[i]);
        scc_fd_printf(out_fd,"\n");
    }
    scc_fd_close(out_fd);
    return 0;
  }

  for(src = srcs ; src ; src = src->next) {
    for(scc_roobj = src->roobj_list ; scc_roobj ; 
        scc_roobj = scc_roobj->next) {
      if(!scc_roobj_write(scc_roobj,src->ns,out_fd)) {
        scc_log(LOG_ERR,"Failed to write ROOM????\n");
        return 1;
      }
    }
  }

  scc_fd_close(out_fd);

  return 0;
}