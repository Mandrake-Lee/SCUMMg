/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */

scripts_statement
	: START_SCRIPT scripts_opt SYM space_args
	{
		scc_statement_t *flag, *scr, *list;
		scc_symbol_t* s;
		
		s = scc_ns_get_sym(sccp->ns,NULL,$3);
		if(!s || (s->type != SCC_RES_SCR && s->type != SCC_RES_LSCR))
			SCC_ABORT(@1,"'%s' is not a known script.\n",$3);
		
		if(!s->rid) scc_ns_get_rid(sccp->ns,s);

		// create the statement for sym
		scr = calloc(1,sizeof(scc_statement_t));
		scr->type = SCC_ST_RES;
		scr->val.r = s;
		
		//Create statement for flag
		flag = calloc(1,sizeof(scc_statement_t));
		flag->type = SCC_ST_VAL;
		flag->val.i = $2;
		
		//Last statements need to be transformed to a list
		list = calloc(1,sizeof(scc_statement_t));
		list->type = SCC_ST_LIST;
		list->val.l = $4;
		
		//Chain statements in order
		flag->next = scr;
		scr->next = list;
		
		$$ = scc_instruction_call(sccp,"_startScript", flag);		
	}
	;

scripts_opt
	: /*empty*/
	{
		$$ = 0;
	}
	| REK
	{
		$$ = FLAG_REK;
	}
	| BAK
	{
		$$ = FLAG_BAK;
	}
	;
