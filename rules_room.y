/* SPDX-License-Identifier: GPL-2.0-or-later */

/* ScummC
 * Copyright (C) 2004-2006  Alban Bedel
 *
 * SCUMMg
 * Copyright (C) 2023-2026 Jorge Amorós-Argos
 */
 
room_statement
	: SET_SCREEN statement TO statement
	{
		$2->next = $4;
		$$ = scc_instruction_call(sccp, "_setScreen", $2);	
	}
	;