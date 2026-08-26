/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */
 
/* Here comes actor statement */

// This rule here is active only inside scripts, so no collision with global declaration rule
actor_header
	: ACTOR SYM
	{
		/* Verify that symbol is of class actor, it has to be predeclared */
		scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$2);
		
		if(!sym)
			SCC_ABORT(@2,"'%s' is not a predeclared actor.\n",$2);
		if(sym->type != SCC_RES_ACTOR)
			SCC_ABORT(@2,"'%s' is not an actor.\n",sym->sym);

		// allocate an rid
		if(!sym->rid)
			scc_ns_get_rid(sccp->ns, sym);

		$$ = sym;
	}
	;

actor_options
	: /* empty */
	{
		$$ = calloc(1, sizeof(scc_actor_statement_t));
	}
	| actor_options COSTUME SYM
	{
		scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$3);
		if(!sym)
			SCC_ABORT(@2,"'%s' is not an predeclared costume.\n",sym->sym);
		if(sym->type != SCC_RES_COST)
			SCC_ABORT(@2,"'%s' is not a costume.\n",sym->sym);

		$$ = $1;
		$$->costsym = sym;
	}
	| actor_options DEFAULT
	{
		//This is to be defined. MAN
		$$ = $1;
		$$->isdefault = 1;
	}
	| actor_options TALK_COLOR statement
	{
		$$=$1;	
		$$->talkcolor = $3;	
	}
	| actor_options STEP_DIST cargs
	{
		$$=$1;	
		$$->stepdistxy = $3;		
	}
	| actor_options TEXT_OFFSET cargs
	{
		$$=$1;	
		$$->textoffsetxy = $3;		
	}
	| actor_options ELEVATION statement
	{
		$$=$1;	
		$$->elevation = $3;		
	}
	| actor_options ANIMATION DEFAULT
	{
		$$=$1;	
		$$->animdefault = 1;		
	}
	| actor_options WALK_ANIMATION statement
	{
		$$=$1;	
		$$->walkanimation = $3;		
	}
	| actor_options STAND_ANIMATION statement
	{
		$$=$1;	
		$$->standanimation = $3;		
	}
	| actor_options TALK_ANIMATION statement
	{
		$$=$1;	
		$$->talkanimation = $3;		
	}	
	| actor_options INIT_ANIMATION statement
	{
		$$=$1;	
		$$->initanimation = $3;		
	}
	| actor_options ANIMATION_SPEED statement
	{
		$$=$1;	
		$$->animationspeed = $3;		
	}		
	| actor_options SCALE statement
	{
		$$=$1;	
		$$->scale = $3;		
	}
	| actor_options ZCLIP statement
	{
		$$=$1;	
		$$->zclip = $3;		
	}
	| actor_options IGNORE_BOXES
	{
		$$=$1;	
		$$->stateboxes = 0;
	}
	| actor_options FOLLOW_BOXES
	{
		$$=$1;	
		$$->stateboxes = 1;
	}
	| actor_options NAME statement
	{
		$$=$1;	
		$$->name = $3;		
	}
	| actor_options WIDTH statement
	{
		$$=$1;	
		$$->name = $3;		
	}
	| actor_options COLOR statement IS statement
	{
		$$=$1;	
		$$->oldcolor = $3;
		$$->newcolor = $5;
	}		
	| actor_options SPECIAL_DRAW statement
	{
		$$=$1;	
		$$->specialdraw = $3;		
	}
	| actor_options STOP
	{
		$$=$1;	
		$$->stop = 1;		
	}
	| actor_options TURN statement
	{
		$$=$1;	
		$$->turn = $3;		
	}	
	| actor_options FACE statement
	{
		$$=$1;	
		$$->face = $3;		
	}
	| actor_options WALK_PAUSE
	{
		$$=$1;	
		$$->walkpause = ACTOR_WALKPAUSE;		
	}
	| actor_options WALK_RESUME
	{
		$$=$1;	
		$$->walkpause = ACTOR_WALKRESUME;		
	}		
	| actor_options VOLUME statement
	{
		$$=$1;	
		$$->volume = $3;		
	}
	| actor_options FREQUENCY statement
	{
		$$=$1;	
		$$->frequency = $3;		
	}
	| actor_options PAN statement
	{
		$$=$1;	
		$$->pan = $3;		
	}
	;
	
actor_statement
	: actor_header actor_options
	{
		scc_instruct_t *inst = NULL;
		scc_actor_statement_t *actorop = $2;
		scc_symbol_t* actorsym = $1;

		inst = scc_statement_build_actor(sccp, actorsym, actorop);

		if(!inst)
			SCC_ABORT(@1, "Why this is null?");

		$$ = inst;

		//Free memory
		free($2);		
	}

putactor_header
	: PUT_ACTOR SYM
	{
		scc_statement_t *a;
		scc_symbol_t* actorsym;
		char* error = NULL;

		scc_fetch_sym(sccp, $2, SCC_RES_ACTOR, &actorsym, &error);

		if(error)
			SCC_ABORT(@2,"%s",error);	//Here there will be a memory leak
		
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = actorsym;
		
		$$ = a;
	}	


putactor_options
	: /*empty*/
	{
		scc_statement_t *a;
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_VAL;
		a->val.i = 0xFF;		//This is special code for "in the same room"
		
		$$ = a;
	}
	| IN_ROOM SYM
	{
		scc_statement_t *a;
		scc_symbol_t* roomsym;
		char* error = NULL;

		scc_fetch_sym(sccp, $2, SCC_RES_ROOM, &roomsym, &error);

		if(error)
			SCC_ABORT(@2,"%s",error);	//Here there will be a memory leak
		
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = roomsym;
		
		$$ = a;
	}
	;


putactor_statement
	: putactor_header AT INTEGER ',' INTEGER putactor_options
	{
		scc_statement_t *x, *y;
		
		x = calloc(1,sizeof(scc_statement_t));
		x->type = SCC_ST_VAL;
		x->val.i = $3;
		
		y = calloc(1,sizeof(scc_statement_t));
		y->type = SCC_ST_VAL;
		y->val.i = $5;		

		//Chain everything
		$1->next = x;
		x->next = y;
		y->next = $6;
		
		$$ = scc_instruction_call(sccp, "_putActorAt", $1);
	}
	| putactor_header AT SYM putactor_options
	{
		scc_statement_t *a;
		scc_symbol_t* objsym;
		char* error = NULL;

		scc_fetch_sym(sccp, $3, SCC_RES_OBJ, &objsym, &error);
		
		if(error)
			SCC_ABORT(@2,"%s",error);	//Here there will be a memory leak
		
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = objsym;
		
		//Chain everything
		a->next = $4;
		$1->next = a;
		
		$$ = scc_instruction_call(sccp, "_putActorAtObject", $1);		
	}
	| putactor_header IN_THE_VOID
	{
		scc_statement_t *a, *x, *y;
		
		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_VAL;
		a->val.i = 0x00;		//This is the actual room id for "the-void"	
		
		x = calloc(1,sizeof(scc_statement_t));
		x->type = SCC_ST_VAL;
		x->val.i = 0;
		
		y = calloc(1,sizeof(scc_statement_t));
		y->type = SCC_ST_VAL;
		y->val.i = 0;		
	
		//Chain everything
		x->next = y;
		y->next = a;
		$1->next = x;
		
		$$ = scc_instruction_call(sccp, "_putActorAt", $1);		
	}
	;