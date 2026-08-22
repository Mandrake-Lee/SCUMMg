/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */
 
 
cursor_statement:
	CURSOR SYM statement
	{
		scc_symbol_t* sym = NULL;
		scc_statement_t* a;
		
		sym = scc_ns_get_sym(sccp->ns,NULL,$2);
		if(!sym)
			SCC_ABORT(@2,"'%s' is not a predeclared object.\n",$2);
		if(sym->type != SCC_RES_OBJ)
			SCC_ABORT(@2,"'%s' is not an object.\n",sym->sym);

		a = calloc(1,sizeof(scc_statement_t));
		a->type = SCC_ST_RES;
		a->val.r = sym;

		a->next = $2;

		$$ = scc_instruction_call(sccp,"_setCursorImage", a);	
	
	}
	| CURSOR TRANSPARENT statement
	{
		$$ = scc_instruction_call(sccp, "_setCursorTransparency", $3);
	}
	| CURSOR HOTSPOT statement ',' statement
	{
		$3->next = $5;
		$$ = scc_instruction_call(sccp, "_setCursorHotspot", $3);	
	}
	| CURSOR ON
	{
		$$ = scc_instruction_call(sccp, "_cursorOn", NULL);
	}
	| CURSOR OFF
	{
		$$ = scc_instruction_call(sccp, "_cursorOff", NULL);
	}
	| CURSOR SOFT_ON
	{
		$$ = scc_instruction_call(sccp,"_softCursorOn", NULL);
	}
	| CURSOR SOFT_OFF
	{
		$$ = scc_instruction_call(sccp,"_softCursorOff", NULL);	
	}
	;
	
userput_statement
	: USERPUT ON
	{
		$$ = scc_instruction_call(sccp,"_userPutOn", NULL);
	}
	| USERPUT OFF
	{
		$$ = scc_instruction_call(sccp,"_userPutOff", NULL);
	}
	| USERPUT SOFT_ON
	{
		$$ = scc_instruction_call(sccp,"_softUserPutOn", NULL);
	}
	| USERPUT SOFT_OFF
	{
		$$ = scc_instruction_call(sccp,"_softUserPutOff", NULL);	
	}
	;


	
cursor_image
	:/*empty*/
	{
	}
	| IMAGE statement
	{
		$$=$2;
	}
	;