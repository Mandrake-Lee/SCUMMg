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
//Hack! We will create a phantom global room for better storage of global scripts
int scc_parser_addglobalroom(scc_parser_t* sccp)
{
	scc_symbol_t* sym;
	const int location = -1;

	//Sanity check
	if(!sccp->ns || !sccp)
		return -1;
		
	sym = scc_ns_decl(sccp->ns,NULL,"-GLOBAL-",SCC_RES_ROOM,0, location);
	scc_ns_get_rid(sccp->ns,sym);
	scc_ns_push(sccp->ns,sym);
	sccp->local_scr = sccp->target->max_global_scr;
	memset(&sccp->ns->as[SCC_RES_LSCR],0,0x10000/8);
	scc_ns_pop(sccp->ns);
	
	//Create room object and link to the list
	sccp->roobj = scc_roobj_new(sccp->target,sym);	
	sccp->roobj->next = sccp->roobj_list;
	sccp->roobj_list = sccp->roobj;
	sccp->roobj = NULL;
	
	return 0;
}


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
	
	//Add global room by default
	scc_parser_addglobalroom(sccp);

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

//Goes through all the possible options of the verb statement and build the code
scc_statement_t* scc_statement_build_verb(scc_parser_t* sccp, scc_symbol_t* vsym, scc_verb_statement_t* vst)
{
	scc_func_t* f;
	scc_statement_t *verbcode=NULL, *last=NULL, *stmnt, *a;
	char* err = NULL;

	//Sanity check
	if (!vsym || !vst)
		return NULL;
	
	//Always set current verb in stack
	//Create assignment of symbol
	a = calloc(1,sizeof(scc_statement_t));
	a->type = SCC_ST_RES;
	a->val.r = vsym;
	//Create proper call to function
	stmnt = calloc(1,sizeof(scc_statement_t));
	stmnt->type = SCC_ST_CALL;
	stmnt->val.c.func = scc_get_func(sccp,"_setCurrentVerb");
	stmnt->val.c.user_script = 0;
	stmnt->val.c.argv = a;
	stmnt->val.c.argc = 1;

	SCC_LIST_ADD(verbcode, last, stmnt);	

	if(vst->new)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_initVerb");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	
	if (vst->name)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbName");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->name;
		
		for(a = vst->name ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);
printf("NAME found in verb '%s'\n", vst->name->val.s->str);	//MAN
		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->posxy)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbXY");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->posxy;
		
		for(a = vst->posxy ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}	
	if (vst->color)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->color;
		
		for(a = vst->color ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->hicolor)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbHiColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->hicolor;
		
		for(a = vst->hicolor ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->dimcolor)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbDimColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->dimcolor;
		
		for(a = vst->dimcolor ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->bakcolor)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbBackColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->bakcolor;
		
		for(a = vst->bakcolor ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}		
	if (vst->key)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbKey");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->key;
		
		for(a = vst->key ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->state)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		switch(vst->state)
		{
			case VERB_ON:
				stmnt->val.c.func = scc_get_func(sccp,"_setVerbOn");
				break;
			case VERB_OFF:
				stmnt->val.c.func = scc_get_func(sccp,"_setVerbOff");
				break;			
			case VERB_DIM:
				stmnt->val.c.func = scc_get_func(sccp,"_verbDim");
				break;
			default:
				scc_log(LOG_ERR,"verb state unknown %d",vst->state);
		}
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		
		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	if (vst->image)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setVerbImage");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = vst->image;
		
		for(a = vst->image ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(verbcode, last, stmnt);
	}
	
	return verbcode;
}

//Goes through all the possible options of the actor statement and build the code
scc_statement_t* scc_statement_build_actor(scc_parser_t* sccp, scc_symbol_t* asym, scc_actor_statement_t* ast)
{
	scc_func_t* f;
	scc_statement_t *actorcode=NULL, *last=NULL, *stmnt, *a;
	char* err = NULL;

	//Sanity check
	if (!asym || !ast)
		return NULL;
	
	//Always set current actor in stack
	//Create assignment of symbol
	a = calloc(1,sizeof(scc_statement_t));
	a->type = SCC_ST_RES;
	a->val.r = asym;
	//Create proper call to function
	stmnt = calloc(1,sizeof(scc_statement_t));
	stmnt->type = SCC_ST_CALL;
	stmnt->val.c.func = scc_get_func(sccp,"_setCurrentActor");
	stmnt->val.c.user_script = 0;
	stmnt->val.c.argv = a;
	stmnt->val.c.argc = 1;

	SCC_LIST_ADD(actorcode, last, stmnt);	

	if(ast->name)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorName");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->name;
		
		for(a = ast->name ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);
		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->stepdistxy)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorTalkPos");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->stepdistxy;
		
		for(a = ast->stepdistxy ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->textoffsetxy)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorAnimVar");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->textoffsetxy;
		
		for(a = ast->textoffsetxy ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}	
	if(ast->costsym)
	{
		//Create assignment of symbol
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = ast->costsym;		
		
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorCostume");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = a;
		stmnt->val.c.argc = 1;		

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->isdefault)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_initActor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;
		
		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
		/*		
			Sets the actor command back to the system defaults. This should
			be used every time a character is inited to prevent attributes from the last
			character that used that actor number from showing up.
			These system defaults are:
			talk-color white
			elevation 0
			walk-animation 2
			stand-animation 3
			talk-animation 4, 5
			init-animation 1
			animation-speed 0
			scale 255
			step-dist 8,2
			width 16
			follow-boxes
			text-offset 0,-80
		*/
		
	}
	if(ast->talkcolor)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorTalkColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->talkcolor;
		
		for(a = ast->talkcolor ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->animdefault)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorDefaultFrames");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->walkanimation)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorWalkScript");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->walkanimation;
		
		for(a = ast->walkanimation ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->standanimation)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorStanding");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->standanimation;
		
		for(a = ast->standanimation ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->talkanimation)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorTalkScript");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->talkanimation;
		
		for(a = ast->talkanimation ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->initanimation)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorInitFrame");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->initanimation;
		
		for(a = ast->initanimation ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->animationspeed)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorAnimSpeed");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->animationspeed;
		
		for(a = ast->animationspeed ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->scale)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorScale");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->scale;
		
		for(a = ast->scale ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->zclip)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorZClip");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->zclip;
		
		for(a = ast->zclip ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->stateboxes)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		switch (ast->stateboxes)
		{
			case ACTOR_IGNOREBOXES:
				stmnt->val.c.func = scc_get_func(sccp,"_setActorIgnoreBoxes");
				break;
			case ACTOR_FOLLOWBOXES:
				stmnt->val.c.func = scc_get_func(sccp,"_setActorFollowBoxes");
				break;
			default:
			/* here should go an error */
		}
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->width)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorWidth");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->width;
		
		for(a = ast->width ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->talkcolor)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorTalkColor");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->talkcolor;
		
		for(a = ast->talkcolor ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->specialdraw)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorShadowMode");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->specialdraw;
		
		for(a = ast->specialdraw ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->stop)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorStanding");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;
		
		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->walkpause)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		switch (ast->walkpause)
		{
			case ACTOR_WALKPAUSE:
					stmnt->val.c.func = scc_get_func(sccp,"_actorFreeze");			
					break;
			case ACTOR_WALKRESUME:
					stmnt->val.c.func = scc_get_func(sccp,"_actorUnfreeze");			
					break;
			default:
			//Trigger an error here
		}
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = NULL;
		stmnt->val.c.argc = 0;
		
		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}	
	if(ast->turn)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_actorTurnToDirection");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->turn;
		
		for(a = ast->turn ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->face)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorDirection");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->face;
		
		for(a = ast->face ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}
	if(ast->volume|| ast->frequency || ast->pan)
	{
		stmnt = calloc(1,sizeof(scc_statement_t));		
		stmnt->type = SCC_ST_CALL;
		stmnt->val.c.func = scc_get_func(sccp,"_setActorSounds");
		stmnt->val.c.user_script = 0;
		stmnt->val.c.argv = ast->volume;
		
		//TODO
		//Need here to compose an iMUSE cmd
		
		for(a = ast->volume ; a ; a = a->next)
			stmnt->val.c.argc++;

		err = scc_statement_check_func(&stmnt->val.c);
		if(err)
			scc_log(LOG_ERR,"%s",err);

		SCC_LIST_ADD(actorcode, last, stmnt);
	}	
	return actorcode;
}