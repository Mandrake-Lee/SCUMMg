/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */


/*
	Just for the verb statement, this is trickier since verbs can be created.
	This means that no forward declaration is needed.
	Therefore just collect all symbols and we will see later if "new" is needed
*/
verb_symbols2
	: SYM
	{
		char** array;

		//Create a NULL terminated array of symbol pointers
		array = malloc(2*sizeof(char*));
		array[0] = $1;
		array[1] = NULL;
		$$ = array;
	}
	| verb_symbols2 SYM
	{
		int l;
		
		//Append to array
		for (l=0;$1[l];l++);	//Find length

		$$=realloc($1, (l+2)*sizeof(char*));
		$$[l] = $2;
		$$[l+1] = NULL;
	}
	;

verb_header: VERB verb_symbols2
	{
		$$ = $2;
	}
	;

verb_options
	: /* empty */
	{
		$$ = calloc(1, sizeof(scc_verb_statement_t));
	}
	| verb_options NEW
	{
		$$=$1;
		$$->new = 1;

	}
	| verb_options AT cargs
	{
		$$ = $1;
		$$->posxy = $3;

	}
	| verb_options NAME statement
	{
		$$ = $1;	
		$$->name = $3;

	}	
	| verb_options COLOR statement
	{
		$$=$1;	
		$$->color = $3;

	}
	| verb_options HICOLOR statement
	{
		$$=$1;	
		$$->hicolor = $3;

	}
	| verb_options DIMCOLOR statement
	{
		$$=$1;	
		$$->hicolor = $3;

	}	
	| verb_options BAKCOLOR statement
	{
		$$=$1;	
		$$->bakcolor = $3;

	}
	| verb_options KEY statement
	{
		$$=$1;	
		$$->key = $3;

	}	
	| verb_options verb_visualoptions
	{
		$$=$1;	
		$$->state = $2;
	}
	| verb_options IMAGE statement
	{
		$$=$1;	
		$$->key = $3;
	}	
	;

verb_visualoptions
	: ON
	{
		$$ = VERB_ON;
	}
	| OFF
	{
		$$ = VERB_OFF;
	}
	| DIM
	{
		$$ = VERB_DIM;
	}
	;
	
verb_statement
	: verb_header verb_options
	{
		//Here we will join all the different opcodes for the verb statement
		scc_symbol_t *v, *l, *cur;
		scc_instruct_t *src=NULL, *last=NULL, *inst;
		scc_verb_statement_t* verbst=$2;
		scc_func_t* f;
		char** array = $1;
		char* verbsym;
		
		//First check that symbols are already created or "new" option enabled
		for (array=$1;*array;array++)
		{
			verbsym = *array;
			v = scc_ns_get_sym(sccp->ns,NULL,verbsym);

			if(!v)
			{
				if(!verbst->new)
					{SCC_ABORT(@1,"'%s' is not a declared verb.\n",verbsym);}
				else
				{	
					//This is a hack to set true global symbols
					cur = sccp->ns->cur;
					sccp->ns->cur = NULL;
					v = scc_ns_decl(sccp->ns, NULL, verbsym, SCC_RES_VERB, 0, -1);
					sccp->ns->cur = cur;
				}
			}
			if(v->type != SCC_RES_VERB)
				SCC_ABORT(@1,"%s is not a verb in the current context.\n",verbsym);

			// allocate an rid
			if(!v->rid) scc_ns_get_rid(sccp->ns,v);
		}
		
		//Now that we're sure all verbs are valid, compose code
		for (array=$1;*array;array++)
		{
			verbsym = *array;

			v = scc_ns_get_sym(sccp->ns,NULL,verbsym);		
			inst = scc_statement_build_verb(sccp, v, verbst);

			if(!inst)
				SCC_ABORT(@1, "Why this is null?");

			SCC_LIST_ADD(src, last, inst);
		}
	
		$$ = src;
		
		//Free memory
		if (!verbst)
			free(verbst);
		for (array=$1;*array;free(*array),array++);
		free($1);
	}
	;