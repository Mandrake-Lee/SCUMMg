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

//Create an instruction that acts as wrapper of a SCUMM function call
scc_instruct_t* scc_instruction_call(scc_parser_t* sccp, char* fname, scc_statement_t* args)
{
	scc_instruct_t *inst;
	scc_statement_t *stmnt, *a;
	char* err = NULL;
	
	//Sanity check
	if (!fname)
		return NULL;
	
	//Create proper call to function
	stmnt = calloc(1,sizeof(scc_statement_t));
	stmnt->type = SCC_ST_CALL;
	stmnt->val.c.func = scc_get_func(sccp, fname);
	stmnt->val.c.user_script = 0;
	stmnt->val.c.argv = args;
	for(a = args ; a ; a = a->next)
		stmnt->val.c.argc++;

	err = scc_statement_check_func(&stmnt->val.c);
	if(err)
		scc_log(LOG_ERR,"%s",err);

	//Create proper instruct as a wrapper
	inst = calloc(1,sizeof(scc_instruct_t));
	inst->type = SCC_INST_ST;
	inst->pre = stmnt;
	
	return inst;
}

//Goes through all the possible options of the verb statement and build the code
scc_instruct_t* scc_statement_build_verb(scc_parser_t* sccp, scc_symbol_t* vsym, scc_verb_statement_t* vst)
{
	scc_instruct_t *verbcode=NULL, *last=NULL, *inst;
	scc_statement_t *a;
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
	inst = scc_instruction_call(sccp, "_setCurrentVerb", a);
	SCC_LIST_ADD(verbcode, last, inst);	

	if(vst->new)
	{
		inst = scc_instruction_call(sccp, "_initVerb", NULL);
		SCC_LIST_ADD(verbcode, last, inst);			
	}
	if (vst->name)
	{
		inst = scc_instruction_call(sccp, "_setVerbName", vst->name);
		SCC_LIST_ADD(verbcode, last, inst);	
	}
	if (vst->posxy)
	{
		inst = scc_instruction_call(sccp, "_setVerbXY", vst->posxy);
		SCC_LIST_ADD(verbcode, last, inst);	
	}
	if (vst->color)
	{
		inst = scc_instruction_call(sccp, "_setVerbColor", vst->color);
		SCC_LIST_ADD(verbcode, last, inst);
	}
	if (vst->hicolor)
	{
		inst = scc_instruction_call(sccp, "_setVerbHiColor", vst->hicolor);
		SCC_LIST_ADD(verbcode, last, inst);
	}
	if (vst->dimcolor)
	{
		inst = scc_instruction_call(sccp, "_setVerbDimColor", vst->dimcolor);
		SCC_LIST_ADD(verbcode, last, inst);		
	}
	if (vst->bakcolor)
	{
		inst = scc_instruction_call(sccp, "_setVerbBackColor", vst->bakcolor);
		SCC_LIST_ADD(verbcode, last, inst);
	}
	if (vst->key)
	{
		inst = scc_instruction_call(sccp, "_setVerbKey", vst->key);
		SCC_LIST_ADD(verbcode, last, inst);
	}
	if (vst->state)
	{
		switch(vst->state)
		{
			case VERB_ON:
				inst = scc_instruction_call(sccp, "_setVerbOn", NULL);
				break;
			case VERB_OFF:
				inst = scc_instruction_call(sccp, "_setVerbOff", NULL);
				break;			
			case VERB_DIM:
				inst = scc_instruction_call(sccp, "_verbDim", NULL);
				break;
			default:
				scc_log(LOG_ERR,"verb state unknown %d",vst->state);
		}
		SCC_LIST_ADD(verbcode, last, inst);
	}
	if (vst->image)
	{
		inst = scc_instruction_call(sccp, "_setVerbImage", vst->image);
		SCC_LIST_ADD(verbcode, last, inst);
	}
	
	return verbcode;
}

//Goes through all the possible options of the actor statement and build the code
scc_instruct_t* scc_statement_build_actor(scc_parser_t* sccp, scc_symbol_t* asym, scc_actor_statement_t* ast)
{
	scc_statement_t  *stmnt, *a;
	scc_instruct_t *actorcode=NULL, *last=NULL, *inst;
	char* err = NULL;

	//Sanity check
	if (!asym || !ast)
		return NULL;
	
	//Always set current actor in stack
	//Create assignment of symbol
	a = calloc(1,sizeof(scc_statement_t));
	a->type = SCC_ST_RES;
	a->val.r = asym;

	inst = scc_instruction_call(sccp, "_setCurrentActor", a);
	SCC_LIST_ADD(actorcode, last, inst);	

	if(ast->name)
	{
		inst = scc_instruction_call(sccp, "_setActorName", ast->name);
		SCC_LIST_ADD(actorcode, last, inst);	
	}
	if(ast->stepdistxy)
	{
		inst = scc_instruction_call(sccp, "_setActorTalkPos", ast->stepdistxy);
		SCC_LIST_ADD(actorcode, last, inst);			
	}
	if(ast->textoffsetxy)
	{
		inst = scc_instruction_call(sccp, "_setActorAnimVar", ast->textoffsetxy);
		SCC_LIST_ADD(actorcode, last, inst);		
	}	
	if(ast->costsym)
	{
		//Create assignment of symbol
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = ast->costsym;		

		inst = scc_instruction_call(sccp, "_setActorCostume", a);
		SCC_LIST_ADD(actorcode, last, inst);
	}
	if(ast->isdefault)
	{
		inst = scc_instruction_call(sccp, "_initActor", NULL);
		SCC_LIST_ADD(actorcode, last, inst);
				
		// Sets the actor command back to the system defaults. This should
		// be used every time a character is inited to prevent attributes from the last
		// character that used that actor number from showing up.
		// These system defaults are:
		// talk-color white
		// elevation 0
		// walk-animation 2
		// stand-animation 3
		// talk-animation 4, 5
		// init-animation 1
		// animation-speed 0
		// scale 255
		// step-dist 8,2
		// width 16
		// follow-boxes
		// text-offset 0,-80
	}
	if(ast->talkcolor)
	{
		inst = scc_instruction_call(sccp, "_setActorTalkColor", ast->talkcolor);
		SCC_LIST_ADD(actorcode, last, inst);
	}
	if(ast->animdefault)
	{
		inst = scc_instruction_call(sccp, "_setActorDefaultFrames", ast->animdefault);
		SCC_LIST_ADD(actorcode, last, inst);		
	}
	if(ast->walkanimation)
	{
		inst = scc_instruction_call(sccp, "_setActorWalkScript", ast->walkanimation);
		SCC_LIST_ADD(actorcode, last, inst);
	}
	if(ast->standanimation)
	{
		inst = scc_instruction_call(sccp, "_setActorStanding", ast->standanimation);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->talkanimation)
	{
		inst = scc_instruction_call(sccp, "_setActorTalkScript", ast->talkanimation);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->initanimation)
	{
		inst = scc_instruction_call(sccp, "_setActorInitFrame", ast->initanimation);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->animationspeed)
	{
		inst = scc_instruction_call(sccp, "_setActorAnimSpeed", ast->animationspeed);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->scale)
	{
		inst = scc_instruction_call(sccp, "_setActorScale", ast->scale);
		SCC_LIST_ADD( actorcode, last, inst);		
	}
	if(ast->zclip)
	{
		inst = scc_instruction_call(sccp, "_setActorZClip", ast->zclip);
		SCC_LIST_ADD( actorcode, last, inst);	
	}
	if(ast->stateboxes)
	{
		switch (ast->stateboxes)
		{
			case ACTOR_IGNOREBOXES:
				inst = scc_instruction_call(sccp, "_setActorIgnoreBoxes", NULL);
				break;
			case ACTOR_FOLLOWBOXES:
				inst = scc_instruction_call(sccp, "_setActorFollowBoxes", NULL);			
				break;
			default:
			// here should go an error
		}
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->width)
	{
		inst = scc_instruction_call(sccp, "_setActorWidth", ast->width);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->talkcolor)
	{
		inst = scc_instruction_call(sccp, "_setActorTalkColor", ast->talkcolor);
		SCC_LIST_ADD( actorcode, last, inst);		
	}
	if(ast->specialdraw)
	{
		inst = scc_instruction_call(sccp, "_setActorShadowMode", ast->specialdraw);
		SCC_LIST_ADD( actorcode, last, inst);			
	}
	if(ast->stop)
	{
		inst = scc_instruction_call(sccp, "_setActorStanding", NULL);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->walkpause)
	{
		switch (ast->walkpause)
		{
			case ACTOR_WALKPAUSE:
					inst = scc_instruction_call(sccp, "_actorFreeze", NULL);
					break;
			case ACTOR_WALKRESUME:
					inst = scc_instruction_call(sccp, "_actorUnfreeze", NULL);			
					break;
			default:
			//Trigger an error here
		}
		SCC_LIST_ADD( actorcode, last, inst);
	}	
	if(ast->turn)
	{
		inst = scc_instruction_call(sccp, "_actorTurnToDirection", ast->turn);
		SCC_LIST_ADD( actorcode, last, inst);
	}
	if(ast->face)
	{
		inst = scc_instruction_call(sccp, "_setActorDirection", ast->face);
		SCC_LIST_ADD( actorcode, last, inst);		
	}
	if(ast->volume|| ast->frequency || ast->pan)
	{

		a = calloc(1,sizeof(scc_statement_t));
		//Here compose the binary string with iMUSE commands
		//TODO
		inst = scc_instruction_call(sccp, "_setActorSounds", a);
		SCC_LIST_ADD( actorcode, last, inst);
	}	
	return actorcode;
}