/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
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
 
 #include "scc_sym.h"
 #include "scc_code.h"
 
//Compares 2 symbols that hold global scripts
int scc_sym_scriptcmp(scc_symbol_t *symA, scc_symbol_t *symB)
{
	scc_scr_arg_t *argA, *argB;
	int szA, szB;
	
	//Check type of sym
	if (symA->type != symB->type)
		return SCRIPTCMP_NTYPE;

	//Check number of arguments
	for (argA = symA->args, szA=0;argA;szA++,argA=argA->next);
	for (argB = symB->args, szB=0;argB;szB++,argB=argB->next);
	
	if (szA != szB)
		return SCRIPTCMP_NLEN;
		
	//Check arguments and its type
	argA = symA->args;
	argB = symB->args;

	while(argA && argB)
	{
		if (strcmp(argA->sym, argB->sym))
			return SCRIPTCMP_NARGNAME;
		if (argA->type != argB->type)
			return SCRIPTCMP_NARGTYPE;			
		argA = argA->next;
		argB = argB->next;
	}

	return SCRIPTCMP_EQ;
}