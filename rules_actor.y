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
		scc_statement_t *st = NULL;
		scc_actor_statement_t *actorop = $2;
		scc_symbol_t* actorsym = $1;

		st = scc_statement_build_actor(sccp, actorsym, actorop);

		if(!st)
			SCC_ABORT(@1, "Why this is null?");

		$$ = st;

		//Free memory
		free($2);		
	}