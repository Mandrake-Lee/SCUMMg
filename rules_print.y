/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */


print_options
	: /* empty */
	{
		$$ = calloc(1, sizeof(struct scc_print_statement_st));
	}
	| print_options CENTER
	{
		$$->center = 1;
	}
	| print_options LEFT
	{
		$$->left = 1;
	}
	| print_options OVERHEAD
	{
		$$->overhead = 1;
	}
	| print_options COLOR statement
	{
		$$->color = $3;
	}
	| print_options CLIPPED statement
	{
		$$->clipped = $3;
	}
	| print_options MUMBLE
	{
		$$->mumble = 1;
	}
	| print_options AT INTEGER ',' INTEGER
	{
		scc_statement_t *x, *y;
		
		x = calloc(1,sizeof(scc_statement_t));
		x->type = SCC_ST_VAL;
		x->val.i = $3;
		
		y = calloc(1,sizeof(scc_statement_t));
		y->type = SCC_ST_VAL;
		y->val.i = $5;		

		//Chain everything
		x->next = y;
		$$->posxy = x;		
	}
	| print_options str
	{
		scc_statement_t *str;
		str = calloc(1,sizeof(scc_statement_t));
		str->type = SCC_ST_STR;
		str->val.s = $2;
	
		$$->string = str;
	}
	;

print_header
	: PRINT_LINE
	{
		$$ = OP_PRINT_LINE;
	}
	| PRINT_TEXT
	{
		$$ = PRINT_TEXT;
	}	
	| PRINT_DEBUG
	{
		$$ = OP_PRINT_DEBUG;
	}
	| PRINT_SYSTEM
	{
		$$ = OP_PRINT_SYSTEM;
	}
	;

sayline_header
	: SAY_LINE
	{
		$$ = NULL;
	}
	| SAY_LINE SYM
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
	;

print_statement
	: print_header print_options
	{
		$$ = scc_statement_build_print(sccp, $1, $2);
		free($2);
	}
	;

sayline_statement
	: sayline_header print_options
	{
		$2->actor = $1;
	
		$$ = scc_statement_build_print(sccp, OP_SAY_LINE, $2);
		free($2);		
	}
	;