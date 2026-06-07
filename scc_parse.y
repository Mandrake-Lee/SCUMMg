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

/**
 * @file scc_parse.y
 * @ingroup scc
 * @brief ScummC compiler
 */
%output "scc_parse_bison.c"
%defines "scc_lex_bison.h"
%define api.pure full
%parse-param {struct scc_parser *v_sccp}
%lex-param {scc_parser_t *YYLEX_PARAM}
%define parse.error verbose

%code requires {
#define YYSTYPE scc_bison_val_t

/* Forward declaration that will be completed with its related parse file .h */
typedef union scc_bison_val_s scc_bison_val_t;
}

%code provides{

}

%code {
//#define SCC_BUILD
#include "config.h"
#include "scc_parse.h"
#include "scc_code.h"
#include "scc_ns.h"
#include "scc_lexer.h"


#define YYERROR_VERBOSE 1

#define sccp ((scc_parser_t*)v_sccp)
#define YYLEX_PARAM sccp->lex

// redefined the function names
#define yyparse scc_parser_parse_internal
#define yylex scc_lex_lex
#define yyerror(loc,sccp,msg) scc_parser_error(sccp,loc,msg)
}

// Operators, the order is defining the priority.

%token NEWLINE	//Acts as separator

%token AADD
%token ASUB
%token AMUL
%token ADIV
%token AAND
%token AOR
%token INC
%token DEC
%token ISOLATED_INC		//MAN
%token ISOLATED_DEC
%token PREINC
%token POSTINC
%token PREDEC
%token POSTDEC

%right <integer> ASSIGN
%right <integer> '?' ':'
%left <integer>  LOR
%left <integer>  LAND
%nonassoc <integer> IS
%left <integer>  '|'
%left <integer>  '&'
%left <integer>  NEQ EQ
%left <integer>  '>' GE
%left <integer>  '<' LE

%left <integer>  '-' '+'
%left <integer> '*' '/'
%right <integer> NEG
%right <integer> '!'
%nonassoc <integer> SUFFIX
%right PREFIX
%left POSTFIX

%token <integer> INTEGER
%token <integer> RESTYPE
%token <str> STRING
%token <strvar> STRVAR
%token <str> SYM
%token <integer> TYPE
%token <integer> NUL

%token <integer> BRANCH RETURN

%token ROOM
%token ENTER		//enter script in a room
%token EXIT			//exit script in a room
%token OBJECT
%token NS
%token SCRIPT
%token VERB
%token ACTOR
%token COSTUMES		//SCUMM
%token SOUNDS		//SCUMM
%token VOICE
%token CYCL

%token FLEM			//Extended SCUMM language to fit room command lines

%token NAME		//Used for objects
/* This chunk below for verb options */
%token NEW
%token COLOR
%token DIMCOLOR
%token HICOLOR
%token BAKCOLOR
%token AT
%token KEY
%token <integer> ON
%token <integer> OFF
%token <integer> DIM
%token CENTER
%token IMAGE

/* This chunk for actor options */
%token COSTUME
%token TALK_COLOR
%token STEP_DIST
%token TEXT_OFFSET
%token ELEVATION
%token ANIMATION
%token WALK_ANIMATION
%token TALK_ANIMATION
%token STAND_ANIMATION
%token INIT_ANIMATION
%token ANIMATION_SPEED
%token SCALE
%token ZCLIP
%token IGNORE_BOXES
%token FOLLOW_BOXES
%token WIDTH
%token SPECIAL_DRAW
%token STOP
%token TURN
%token FACE
%token WALK_PAUSE
%token WALK_RESUME
%token VOLUME
%token FREQUENCY
%token PAN

%nonassoc <integer> IF
%nonassoc ELSE
%nonassoc FOR
%nonassoc TO
%nonassoc <integer> WHILE
%nonassoc DO
%nonassoc SWITCH
%nonassoc CASE
%nonassoc DEFAULT
%nonassoc CUTSCENE
%nonassoc CLASS
%nonassoc TRY
%nonassoc OVERRIDE

%token <integer> SCRTYPE

%token ERROR

%type <strvar> str
%type <strvar> string
%type <integer> location
%type <st> dval

%type <st> cargs
%type <st> var
%type <st> call

%type <st> isargs
%type <st> isarglist
%type <st> isarg

%type <sym> vdecl

%type <st> statement
%type <st> restricted_statement
%type <verbst> verb_options
%type <st> statements
%type <st> opt_statements
%type <inst> verb_statement
%type <inst> instruct
%type <inst> ifblock
%type <integer> for_ops		//Actually returning INC or DEC
%type <st> caseval
%type <st> caseblock
%type <inst> switchblock
%type <inst> switchblock2
%type <st> caseheader
%type <inst> loopblock
%type <inst> cutsceneblock
%type <inst> block
%type <inst> instructions
%type <inst> oneinstruct
%type <inst> dobody
%type <inst> body
%type <inst> loophead
%type <str> label
%type <inst> dohead
%type <inst> switchhead
%type <scr> scriptbody
%type <inst> verbcode
%type <sym> verbentry
%type <vscr> verbsblock
%type <vscr> verb_open_block
%type <symlist> verb_symbols
%type <strlist> verb_symbols2
%type <strlist> verb_header
%type <sym> actor_header
%type <actorst> actor_options
%type <inst> actor_statement
%type <sympath> sympath sympath_list
%type <integer> gvardecl
%type <integer> gresdecl
%type <integer> groomresdecl
%type <integer> globalres
%type <integer> roomres
%type <integer> resdecl
%type <integer> verb_visualoptions
%type <str> resdef
%type <integer> scripttype

%type <arg> scriptargs
%type <arg> scriptargs_explicit
%type <arg> scriptargs_loose
%type <arg> scriptargs_all
%type <arg> globalscrdecl2
%type <arg> symlist_commasep
%type <sym> roomscrdecl
%type <sym> roomscrdecl2
%type <sym> enterscr_header
%type <sym> exitscr_header
%type <sym> globalscrdecl
%type <sym> globalscr_openblk
%type <sym> roomobjdecl
%type <sym> roomobjdecl2
%type <sym> cycledecl
%type <sym> voicedecl
%type <strlist> zbufs
%type <intlist> synclist		//comma separated integer list
%type <intlist> integerlist		//space separated integer list
%type <integer> typemod
%type <integer> natural

%type <box> box_declaration box_single box_list box_points
%type <scal> scal_declaration scal_single scal_list
%type <intpair> numberpair
%type <integer> number
%%

/*
srcfile: %empty
| srcs
;
*/

/*
srcfile: %empty
	| srcfile srcs		//Meaningful blocks are separated with NEWLINE
;
*/

srcfile
	: %empty
	| NEWLINE
	| srcfile src2
	;

//srcs: src
srcs: %empty
| NEWLINE			//Let's consider a block of NEWLINE's
| src NEWLINE
//| srcs src
;

src: room2
	| gdecl
	| globalscript
;

src2
	: room2
	| globalscript
	| gdecl NEWLINE
	;


//gdecl: gvardecl ';'
gdecl: gvardecl
{}
| gresdecl //';'
{}
| groomresdecl //';'
{}
| groomdecl //';'
/*
| globalscrdecl
{
	scc_ns_clear(sccp->ns,SCC_RES_LVAR);
	scc_ns_pop(sccp->ns);
}
*/
| globalscrdecl2
{
	scc_scr_arg_t *argAux, *script = $1;
	scc_symbol_t *s, *a;

	//First check that script is not already defined
	s = scc_ns_get_sym(sccp->ns,"-GLOBAL-", script->sym);
	
	if (s)
	{
		//If this is a declaration, then we're already in double decl error
		//If this is a definition then it is a must
		
		a = s->childs;
		argAux = script->next;
		while(argAux && a)
		{
			if (strcmp(a->sym, argAux->sym))
			{
				SCC_LIST_FREE(script, argAux);
				SCC_ABORT(@1, "Global script \'%s\' double declaration mismatch arguments",s->sym);
			}
			a = a->next;
			argAux = argAux->next;
		}
		
		SCC_LIST_FREE(script, argAux);
		SCC_ABORT(@1, "Global script \'%s\' double declaration", s->sym);
		//At the same room?
		//Same arguments?
	}
	else	//At this branch, we create the global script
	{
		scc_symbol_t *roomg;

		s = scc_ns_decl(sccp->ns,"-GLOBAL-",script->sym,SCC_RES_SCR,0,-1);  
		if(!s)
			SCC_ABORT(@1,"Failed to declare global script \'%s\'.\n",script->sym);

		roomg = scc_ns_get_sym(sccp->ns, NULL, "-GLOBAL-");
		
		if (!roomg)
			SCC_ABORT(@1, "Room global not found!");
			
		//Go to global room and allocate script
		scc_ns_push(sccp->ns,roomg);
		scc_ns_push(sccp->ns,s);	//This pushes the scope of the variables

		// declare the arguments
		sccp->local_vars = 0;		//I'm not sure about this line. MAN
		argAux = script->next;
		while(argAux)
		{
			scc_ns_decl(sccp->ns,NULL,argAux->sym,SCC_RES_LVAR,argAux->type,sccp->local_vars);
			sccp->local_vars++;
			argAux = argAux->next;
		}
		
		SCC_LIST_FREE(script, argAux);
		
		//Return to root level
		/** missing remove lvar? */
		scc_ns_clear(sccp->ns,SCC_RES_LVAR);

		scc_ns_pop(sccp->ns);
		scc_ns_pop(sccp->ns);
		
//		$$ = s;	
	}

}
;

gvardecl: TYPE typemod SYM location
{
	scc_symbol_t* rr;

	if($1 == SCC_VAR_BIT && !$2)
		scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_BVAR,$1,$4);
//	else
//	{
		rr = scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_VAR,$1 | $2,$4);
//		if (!rr)
//			printf("I'm returning NULL for %s \n", $3);
//	}

	$$ = $1;
}
| gvardecl typemod SYM location
{
	if($1 == SCC_VAR_BIT && !$2)
		scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_BVAR,$1,$4);
	else
		scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_VAR,$1 | $2,$4);

	$$ = $1;
}
| gvardecl ',' typemod SYM location
{
  if($1 == SCC_VAR_BIT && !$3)
    scc_ns_decl(sccp->ns,NULL,$4,SCC_RES_BVAR,$1,$5);
  else
    scc_ns_decl(sccp->ns,NULL,$4,SCC_RES_VAR,$1 | $3,$5);

  $$ = $1;
}
;

typemod: /* nothing */
{
  $$ = 0;
}
| '*'
{
  $$ = SCC_VAR_ARRAY;
}
;

// room must be put outside of globalres
// otherwise it conflict with roombdecl
groomdecl: ROOM SYM location
{
  scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_ROOM,0,$3);
}
| groomdecl ',' SYM location
{
  scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_ROOM,0,$4);
}
;

gresdecl: globalres SYM location
{
  scc_ns_decl(sccp->ns,NULL,$2,$1,0,$3);
}
| gresdecl ',' SYM location
{
  scc_ns_decl(sccp->ns,NULL,$3,$1,0,$4);
}
| costumes_gdecl
{}
| sounds_gdecl
{}
;

globalres: ACTOR
{ 
  $$ = SCC_RES_ACTOR;
}
| VERB
{ 
  $$ = SCC_RES_VERB;
}
| CLASS
{ 
  $$ = SCC_RES_CLASS;
}
| SCRIPT
{ 
  $$ = SCC_RES_SCR;
}
;

// cost, sound, chset, object, script, voice, cycl
groomresdecl: roomres SYM NS SYM location
{
  scc_ns_decl(sccp->ns,$2,$4,$1,0,$5);
  $$ = $1; // hack to propagte the type
}
| groomresdecl ',' SYM NS SYM location
{
  scc_ns_decl(sccp->ns,$3,$5,$1,0,$6);
}
;

roomres: RESTYPE
| OBJECT
{ 
  $$ = SCC_RES_OBJ;
}
| SCRIPT
{ 
  $$ = SCC_RES_SCR;
}
| VOICE
{ 
  $$ = SCC_RES_VOICE;
}
| CYCL
{ 
  $$ = SCC_RES_CYCL;
}
;

/* Before we go farther, we will give some flexilibity to the braces */
open_block: '{' NEWLINE
	;

close_block: '}' NEWLINE
	;


// This allow us to have the room declared before we parse the body.
// At this point the roobj object is created.
roombdecl: ROOM SYM location
{
  scc_symbol_t* sym = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_ROOM,0,$3);
  scc_ns_get_rid(sccp->ns,sym);
  scc_ns_push(sccp->ns,sym);
  sccp->roobj = scc_roobj_new(sccp->target,sym);
}
;

// This allow us to have the room declared before we parse the body.
// At this point the roobj object is created.
// Make it SCUMM compatible
// room "room-filename" room-name {}
roombdecl2
	: ROOM STRING SYM 
	{
	  scc_symbol_t* sym = scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_ROOM,0,-1);
	  scc_ns_get_rid(sccp->ns,sym);
	  scc_ns_push(sccp->ns,sym);
	  sccp->roobj = scc_roobj_new(sccp->target,sym);
	  sccp->roobj->filename = $2;
	}
	;

/*
// Here we should have the whole room.
room: roombdecl roombody
{
  scc_log(LOG_DBG,"Room done :)\n");
  sccp->local_scr = sccp->target->max_global_scr;
  memset(&sccp->ns->as[SCC_RES_LSCR],0,0x10000/8);
  sccp->cycl = 1;
  scc_ns_clear(sccp->ns,SCC_RES_CYCL);
  scc_ns_pop(sccp->ns);

  if(!sccp->roobj->scr &&
     !sccp->roobj->lscr &&
     !sccp->roobj->obj &&
     !sccp->roobj->res &&
     !sccp->roobj->cycl &&
     !sccp->roobj->image) {
    scc_log(LOG_DBG,"Room is empty, only declarations.\n");
    scc_roobj_free(sccp->roobj);
  } else {
    sccp->roobj->next = sccp->roobj_list;
    sccp->roobj_list = sccp->roobj;
  }
  sccp->roobj = NULL;
}
;
*/


// Here we should have the whole room.
room2: roombdecl2 open_block roombody2 close_block
{
  scc_log(LOG_DBG,"Room done :)\n");
  sccp->local_scr = sccp->target->max_global_scr;
  memset(&sccp->ns->as[SCC_RES_LSCR],0,0x10000/8);
  sccp->cycl = 1;
  scc_ns_clear(sccp->ns,SCC_RES_CYCL);
  scc_ns_pop(sccp->ns);

  if(!sccp->roobj->scr &&
     !sccp->roobj->lscr &&
     !sccp->roobj->obj &&
     !sccp->roobj->res &&
     !sccp->roobj->cycl &&
     !sccp->roobj->image &&
	 !sccp->roobj->enterscr &&
	 !sccp->roobj->exitscr
	 ) {
    scc_log(LOG_DBG,"Room is empty, only declarations.\n");
    scc_roobj_free(sccp->roobj);
  } else {
    sccp->roobj->next = sccp->roobj_list;
    sccp->roobj_list = sccp->roobj;
  }
  sccp->roobj = NULL;
}
;

/*
roombody: '{' '}'
| '{' roombodyentries '}'
//| '{' roomdecls '}'
| '{' roomdecls roombodyentries '}'
;
*/

roombody2
	: /*empty*/
	| roombodyentries2
	//| '{' roomdecls '}'
	| roomdecls roombodyentries2
	;

/*
roombodyentries: roombodyentry
| roombodyentries roombodyentry
;
*/
roombodyentries2
	: roombodyentry2
	| roombodyentries2 roombodyentry2
	;

/*
// scripts, both local and global
roombodyentry: roomscrdecl '{' scriptbody '}'
{
  if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
  if($3) {
    $3->sym = $1;
    scc_roobj_add_scr(sccp->roobj,$3);
  }

  scc_ns_clear(sccp->ns,SCC_RES_LVAR);
  scc_ns_pop(sccp->ns);
}
// forward declaration
| roomscrdecl ';'
{
  // well :)
  scc_ns_clear(sccp->ns,SCC_RES_LVAR);
  scc_ns_pop(sccp->ns);
}
// objects
| roomobjdecl '{' objectparams objectverbs '}'
{

  if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
  // add the obj to the room
  scc_roobj_add_obj(sccp->roobj,sccp->obj);
  sccp->obj = NULL;
}
// forward declaration
| roomobjdecl ';'
{
  scc_roobj_obj_free(sccp->obj);
  sccp->obj = NULL;
}
| voicedef ';'
{}
| voicedecl ';'
{}
| cycledef ';'
{}
| cycledecl ';'
{}
| resdecl ';'
{}
| gvardecl ';'
{}
;
*/

enterscr_header
	: ENTER
	{
		scc_symbol_t* s;
		char* roomname = sccp->roobj->sym->sym;
		
		//Only 1 enter script can exist
		if (sccp->roobj->enterscr)
			SCC_ABORT(@1, "enter script is already defined in room '%s'.\n", sccp->roobj->sym->sym);
	
		s = scc_ns_decl(sccp->ns,roomname,"enter",SCC_RES_LSCR,0,-1);
		if(!s) SCC_ABORT(@1,"Failed to declare 'enter' script.\n");

		if(s->addr < 0)
			if(!scc_ns_alloc_sym_addr(sccp->ns,s,&sccp->local_scr))
				SCC_ABORT(@1,"Failed to allocate 'enter' script address.\n");

		scc_ns_push(sccp->ns,s);
		sccp->local_vars = 0;
		$$ = s;
	}
	;

exitscr_header
	: EXIT
	{
		scc_symbol_t* s;
		char* roomname = sccp->roobj->sym->sym;
		
		//Only 1 enter script can exist
		if (sccp->roobj->exitscr)
			SCC_ABORT(@1, "exit script is already defined in room '%s'.\n", sccp->roobj->sym->sym);
	
		s = scc_ns_decl(sccp->ns,roomname,"exit",SCC_RES_LSCR,0,-1);
		if(!s) SCC_ABORT(@1,"Failed to declare 'exit' script.\n");

		if(s->addr < 0)
			if(!scc_ns_alloc_sym_addr(sccp->ns,s,&sccp->local_scr))
				SCC_ABORT(@1,"Failed to allocate 'exit' script address.\n");

		scc_ns_push(sccp->ns,s);
		sccp->local_vars = 0;
		$$ = s;
	}
	;


// scripts, local
//roombodyentry2: roomscrdecl '{' scriptbody '}'
roombodyentry2
	:roomscrdecl2 open_block scriptbody close_block
	{
		if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
		if($3) {
			$3->sym = $1;
			scc_roobj_add_scr(sccp->roobj,$3);
		}
		scc_ns_clear(sccp->ns,SCC_RES_LVAR);
		scc_ns_pop(sccp->ns);
	}
	| enterscr_header open_block scriptbody close_block
	{
		if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
		if($3) {
			$3->sym = $1;
			sccp->roobj->enterscr = $3;
		}
		scc_ns_clear(sccp->ns,SCC_RES_LVAR);
		scc_ns_pop(sccp->ns);
	}
	| exitscr_header open_block scriptbody close_block
	{
		if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
		if($3) {
			$3->sym = $1;
			sccp->roobj->exitscr = $3;
		}
		scc_ns_clear(sccp->ns,SCC_RES_LVAR);
		scc_ns_pop(sccp->ns);	
	}
	| roomobjdecl2 open_block objectparams2 close_block
	{
		if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
		// add the obj to the room
		scc_roobj_add_obj(sccp->roobj,sccp->obj);
		sccp->obj = NULL;
	}
	| flem_block
	{}
	| costumes_block
	{}
	| sounds_block
	{}
	;

/*	
// forward declaration
| roomscrdecl ';'
{
  // well :)
  scc_ns_clear(sccp->ns,SCC_RES_LVAR);
  scc_ns_pop(sccp->ns);
}
// objects
| roomobjdecl '{' objectparams objectverbs '}'
{

  if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);
  // add the obj to the room
  scc_roobj_add_obj(sccp->roobj,sccp->obj);
  sccp->obj = NULL;
}
// forward declaration
| roomobjdecl ';'
{
  scc_roobj_obj_free(sccp->obj);
  sccp->obj = NULL;
}
| voicedef ';'
{}
| voicedecl ';'
{}
| cycledef ';'
{}
| cycledecl ';'
{}
| resdecl ';'
{}
| gvardecl ';'
{}
;
*/


//globalscript: globalscrdecl '{' scriptbody '}'
//globalscript: globalscrdecl2 open_block scriptbody close_block
globalscript: globalscr_openblk scriptbody close_block
{
	scc_symbol_t *roomg;
	scc_roobj_t *cur, *next;
	
	roomg = scc_ns_get_sym(sccp->ns, NULL, "-GLOBAL-");
	if (!roomg)
		SCC_ABORT(@1, "Room global not found!");

	//We need to find roobj for global
	cur = sccp->roobj_list;

	while(cur)
	{
		if (cur->sym == roomg)
			break;
		cur = cur->next;
	}

	if(!cur)
		SCC_ABORT(@1, "Global room object not created");

	if($2) {
		$2->sym = $1;
		scc_roobj_add_scr(cur,$2);
	}

	scc_ns_clear(sccp->ns,SCC_RES_LVAR);
	scc_ns_pop(sccp->ns);
	scc_ns_pop(sccp->ns);
}
;

globalscrdecl2: SCRIPT SYM scriptargs_all
{

	/*	The script pre-declaration will return the symbols for the function and
		the arguments.
		We will abuse a bit of the args struct.
	*/
	scc_scr_arg_t* args = $3;
	scc_scr_arg_t* script;

	script = calloc(1, sizeof(scc_scr_arg_t));

	//Dump script name data and link
	script->type = SCC_RES_SCR;
	script->sym = $2;
	script->next = args;

	$$ = script;
}
;

globalscr_openblk: globalscrdecl2 open_block
	{
	scc_scr_arg_t *argAux, *script = $1;
	scc_symbol_t *s, *a;
	scc_symbol_t *roomg;
	char auxsym[64];

	//First check that script is already declared
	s = scc_ns_get_sym(sccp->ns,"-GLOBAL-", script->sym);
	
	if (s)
	{
		//If this is a declaration, then we're already in double decl error
		//If this is a definition then it is a must
		
		a = s->childs;
		argAux = script->next;
		while(argAux && a)
		{
			if (strcmp(a->sym, argAux->sym))
			{
				SCC_LIST_FREE(script, argAux);
				SCC_ABORT(@1, "Global script \'%s\' double declaration mismatch arguments",s->sym);
			}
			a = a->next;
			argAux = argAux->next;
		}
	}
	else
	{
		strncpy(auxsym, script->sym, 63);
		auxsym[63]='\0';
		SCC_LIST_FREE(script, argAux);
		SCC_ABORT(@1, "Global script \'%s\' has no forward declaration",auxsym);	
	}

/*	
	sccp->local_vars = 0;
	for (a=s->childs;a;a=a->next)
		{sccp->local_vars++;}
	printf("local_vars = %d\n", sccp->local_vars);	//DEBUG
*/
	SCC_LIST_FREE(script, argAux);

	roomg = scc_ns_get_sym(sccp->ns, NULL, "-GLOBAL-");
	if (!roomg)
		SCC_ABORT(@1, "Room global not found!");

	if(!roomg->rid) scc_ns_get_rid(sccp->ns,roomg);
	if (!scc_ns_push(sccp->ns, roomg))
		SCC_ABORT(@1, "Push level not worked for room %s", roomg->sym);
	if (!scc_ns_push(sccp->ns, s))
		SCC_ABORT(@1, "Push level not worked for global script %s", s->sym);

	//We need to find roobj for global
	scc_roobj_t *cur, *next;
	cur = sccp->roobj_list;
	while(cur)
	{
		if (cur->sym == roomg)
			break;
		cur = cur->next;
	}

	if(!cur)
		SCC_ABORT(@1, "Global room object not created");	
	
	//Add arguments of the function as first local variables
	sccp->local_vars = 0;
	while(a)
	{
		scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_LVAR,a->type,sccp->local_vars);
		sccp->local_vars++;
		a = a->next;
	}
	
//	sccp->roobj = cur;
	
//	printf("Current push level symbol is '%s'\n", sccp->ns->cur->sym);	//MAN
	a=scc_ns_get_sym_at(sccp->ns, SCC_RES_LVAR, 0x4000);
	if(a)
		printf("Found symbol at address 0 named '%s'\n", a->sym);	//MAN
	
	
	$$ = s;
	}
	;



//Global script declaration, always out of any room{}
globalscrdecl: SCRIPT SYM scriptargs_all
{

	/*	The script pre-declaration will return the symbols for the function and
		the arguments.
		We will abuse a bit of the args struct.
	*/
	scc_scr_arg_t* args = $3;
	scc_scr_arg_t* script;

	script = calloc(1, sizeof(scc_scr_arg_t));

	script->type = SCC_RES_SCR;
	script->sym = $2;
	script->next = args;

	$$ = script;

	scc_scr_arg_t* a = $3;
	scc_symbol_t *s, *roomg;

	int type = SCC_RES_SCR;
	int address = -1;

	s = scc_ns_decl(sccp->ns,"-GLOBAL-",$2,type,0,address);  
	if(!s)
		SCC_ABORT(@3,"Failed to declare global script \'%s\'.\n",$2);

	roomg = scc_ns_get_sym(sccp->ns, NULL, "-GLOBAL-");
	
	if (!roomg)
		SCC_ABORT(@3, "Room global not found!");
		
	//Go to global room and allocate script
	scc_ns_push(sccp->ns,roomg);
	scc_ns_push(sccp->ns,s);	//This pushes the scope of the variables

	// declare the arguments
	sccp->local_vars = 0;
	while(a)
	{
		scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_LVAR,a->type,sccp->local_vars);
		sccp->local_vars++;
		a = a->next;
	}
	
	//Return to root level
	/** missing remove lvar? */
	scc_ns_pop(sccp->ns);
	scc_ns_pop(sccp->ns);
	
	$$ = s;
}
;


roomscrdecl: scripttype SCRIPT SYM  '(' scriptargs ')' location
{
  scc_scr_arg_t* a = $5;
  scc_symbol_t* s;

  s = scc_ns_decl(sccp->ns,NULL,$3,$1,0,$7);
  if(!s) SCC_ABORT(@3,"Failed to declare script %s.\n",$3);

  if($1 == SCC_RES_LSCR && s->addr < 0 &&
     strcmp($3,"entry") && strcmp($3,"exit"))
    if(!scc_ns_alloc_sym_addr(sccp->ns,s,&sccp->local_scr))
      SCC_ABORT(@3,"Failed to allocate local script address.\n");

  scc_ns_push(sccp->ns,s);

  // declare the arguments
  sccp->local_vars = 0;
  while(a) {
    scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_LVAR,a->type,sccp->local_vars);
    sccp->local_vars++;
    a = a->next;
  }
  
  $$ = s;
}
;

roomscrdecl2
	: SCRIPT SYM scriptargs_all
	{
		scc_scr_arg_t* a = $3;
		scc_symbol_t* s;

		s = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_LSCR,0,-1);
		if(!s) SCC_ABORT(@3,"Failed to declare script %s.\n",$2);

//		if($1 == SCC_RES_LSCR && s->addr < 0 &&
//			strcmp($3,"entry") && strcmp($3,"exit"))
		if(!scc_ns_alloc_sym_addr(sccp->ns,s,&sccp->local_scr))
			SCC_ABORT(@3,"Failed to allocate local script address.\n");

		scc_ns_push(sccp->ns,s);

		// declare the arguments
		sccp->local_vars = 0;
		while(a) {
			scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_LVAR,a->type,sccp->local_vars);
			sccp->local_vars++;
			a = a->next;
		}

		$$ = s;
	}
	;


roomobjdecl: OBJECT SYM location
{
  scc_symbol_t* sym;

  if(sccp->obj)
    SCC_ABORT(@1,"Something went wrong with object declarations.\n");


  sym = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_OBJ,0,$3);
  if(!sym) SCC_ABORT(@1,"Failed to declare object %s.\n",$2);
  
  sccp->obj = scc_roobj_obj_new(sym);
  $$ = sym;
}
;

roomobjdecl2
	: OBJECT SYM
	{
		scc_symbol_t* sym;

		if(sccp->obj)
			SCC_ABORT(@1,"Something went wrong with object declarations.\n");

		sym = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_OBJ,0,-1);
		if(!sym)
			SCC_ABORT(@1,"Failed to declare object %s.\n",$2);

		sccp->obj = scc_roobj_obj_new(sym);
		$$ = sym;
	}
	;


flem_header
	: FLEM open_block
	;

flem_block
	: flem_header flemdecls close_block
	;

flemdecls
	: flemdecl NEWLINE
	| flemdecls flemdecl NEWLINE

flemdecl
	: IMAGE ASSIGN STRING
	{
		if($2 != '=')
			SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

		scc_parser_find_res(sccp,&$3);
		
		if(!scc_roobj_set_param(sccp->roobj,sccp->ns,"image",$3))
			SCC_ABORT(@1,"Failed to set room %s.\n","image");

		// add dep
		if(sccp->do_deps) scc_parser_add_dep(sccp,$3);
		//Clean
		free($3);
	}	
	| SYM ASSIGN '{' zbufs '}'
	{
		int i;
		if($2 != '=')
			SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

		for(i = 0 ; $4[i] ; i++) {
			if($4[i][0] == '\0')
				continue;
			if(!scc_roobj_set_zplane(sccp->roobj,i+1,$4[i]))
				SCC_ABORT(@1,"Failed to set room zplane %d.\n",i+1);
		}
		for(i=0;$4[i] ; i++)
			free($4[i]);
		free($4);
	}
	| SYM ASSIGN INTEGER
	{
		if($2 != '=')
			SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

		if(strcmp($1,"trans"))
			SCC_ABORT(@1,"Rooms have no parameter named %s.\n",$1);

		if($3 < 0 || $3 > 255)
			SCC_ABORT(@3,"Invalid transparent color index: %d\n",$3);

		sccp->roobj->trans = $3;
	}
	| SYM ASSIGN box_declaration
	{
		scc_box_t *box = $3, *next=NULL;
		uint8_t* boxm;
		int len;
		
		if($2 != '=')
			SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

		if(sccp->roobj->boxd)
			SCC_ABORT(@2,"Double declaration of 'box'.\n");

		scc_boxes_arrangedata(box);
		scc_roobj_create_boxd(sccp->roobj, box);
		
		//Now create boxm & attach to room
		len = scc_box_get_matrix(box, &boxm);
		sccp->roobj->boxmrawsize = scc_boxm_size_from_matrix(boxm, len);

		//Hack: null terminate the boxm array
		boxm = realloc(boxm, (len*len +1)*sizeof(uint8_t));
		boxm[len*len]=NULL;
		sccp->roobj->boxmrawdata = boxm;

		//Clean
		SCC_LIST_FREE(box, next);
	}
	| SCALE ASSIGN scal_declaration
	{
		scc_scale_slot_t* scaleslot = $3;
		int i=0;
		
//		for(i=0; scaleslot->next; scaleslot = scaleslot->next,i++);
//		printf ("Found %d scales\n", i+1);

		sccp->roobj->scalelist = $3;
	}
	;

flemdecls_obj
	: flemdecl_obj NEWLINE
	| flemdecls_obj flemdecl_obj NEWLINE

box_declaration
	:box_single
	{
		$$ = $1;
	}
	| '{' box_list '}'
	{
		$$ = $2;
	}
	;

box_list
	: box_single
	{
		$$=$1;
	}
	| box_list ',' box_single
	{
		$3->next = $1;
		$$ = $3;
	}

/* A boxd has points + mask + flags + scale */
box_single: '{' box_points ',' INTEGER ',' INTEGER ',' INTEGER'}'
	{
		$$ = $2;
		$$->mask = $4;
		$$->flags = $6;
		$$->scale = $8;
	}
	;

box_points
	: /* empty */
	{
		$$ = calloc(1, sizeof(scc_box_t));
	}
	| box_points numberpair
	{
//		scc_box_t *box;
//		box = calloc(1, sizeof(scc_box_t));
		scc_box_add_pts ($1, $2[0], $2[1]);
		$$ = $1;
	}
	| box_points ',' numberpair
	{
		scc_box_t *box = $1;
		scc_box_add_pts (box, $3[0], $3[1]);
		$$ = box;
	}
	;

numberpair: '{' number ',' number '}'
	{
		$$[0] = $2;
		$$[1] = $4;
	}
	;

number: INTEGER
	| '-' INTEGER
	{
		$$ = - $2;
	}
	| '+' INTEGER
	{
		$$ = $2;
	}
	;

scal_declaration
	: scal_single
	{
		$$ = $1;
	}
	| '{' scal_list '}'
	{
		$$ = $2;
	}
	;

scal_single
	: '{' INTEGER ',' INTEGER ',' INTEGER ',' INTEGER '}'
	{
		scc_scale_slot_t* scaleslot;
	
		scaleslot = calloc(1, sizeof(scc_scale_slot_t));
		scaleslot->s1 = $2;
		scaleslot->y1 = $4;
		scaleslot->s2 = $6;
		scaleslot->y2 = $8;
		
		$$ = scaleslot;
	}
	;

scal_list
	: scal_single
	{
		$$ = $1;
	}
	| scal_list ',' scal_single
	{
		scc_scale_slot_t* scaleslot, next;	
		int i=2;
		for (scaleslot=$1;scaleslot->next;scaleslot = scaleslot->next,i++);

		if (i>SCC_NUM_SCALE_SLOT)
			SCC_ABORT(@2, "Exceeded max. %d values of scale slots.", SCC_NUM_SCALE_SLOT);

		scaleslot->next = $3;	//Append to the end
	
		$$=$1;
	}
	;

// the basic room parameters such as image, box, zplanes, etc
roomdecls: roomdecl
| roomdecls roomdecl
;

roomdecl: SYM ASSIGN STRING ';'
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  scc_parser_find_res(sccp,&$3);
  if(!scc_roobj_set_param(sccp->roobj,sccp->ns,$1,$3))
    SCC_ABORT(@1,"Failed to set room %s.\n",$1);

  // add dep
  if(sccp->do_deps) scc_parser_add_dep(sccp,$3);
}
| SYM ASSIGN '{' zbufs '}' ';'
{
  int i;
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  for(i = 0 ; $4[i] ; i++) {
    if($4[i][0] == '\0') continue;
    if(!scc_roobj_set_zplane(sccp->roobj,i+1,$4[i]))
      SCC_ABORT(@1,"Failed to set room zplane %d.\n",i+1);
  }
}
| SYM ASSIGN INTEGER ';'
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  if(strcmp($1,"trans"))
    SCC_ABORT(@1,"Rooms have no parameter named %s.\n",$1);

  if($3 < 0 || $3 > 255)
    SCC_ABORT(@3,"Invalid transparent color index: %d\n",$3);

  sccp->roobj->trans = $3;
}
;

// The optional room resources like cycle, voice, charset, etc
cycledef: cycledecl ASSIGN '{' INTEGER ',' INTEGER ',' INTEGER ',' INTEGER '}'
{
  if($2 != '=')
    SCC_ABORT(@3,"Invalid operator for cycle declaration.\n");

  if(!scc_roobj_add_cycl(sccp->roobj,$1,$4,$6,$8,$10))
    SCC_ABORT(@1,"Failed to add cycl.\n");
}
;

cycledecl: CYCL SYM location
{
  $$ = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_CYCL,0,$3);
  if(!$$) SCC_ABORT(@1,"Cycl declaration failed.\n");
  if($$->addr < 0 && !scc_ns_alloc_sym_addr(sccp->ns,$$,&sccp->cycl))
      SCC_ABORT(@1,"Failed to allocate cycle address.\n");
}
;

voicedef: voicedecl ASSIGN '{' STRING ',' synclist '}'
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for voice declaration.\n");

  if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);

  scc_parser_find_res(sccp,&$4);
  if(!scc_roobj_add_voice(sccp->roobj,$1,$4,$6[0],$6+1))
    SCC_ABORT(@1,"Failed to add voice.");

  if(sccp->do_deps) scc_parser_add_dep(sccp,$4);

  free($6);
}
| voicedecl ASSIGN '{' STRING '}'
{
  if($2 != '=')
    SCC_ABORT(@3,"Invalid operator for voice declaration.\n");

  if(!$1->rid) scc_ns_get_rid(sccp->ns,$1);

  scc_parser_find_res(sccp,&$4);
  if(!scc_roobj_add_voice(sccp->roobj,$1,$4,0,NULL))
    SCC_ABORT(@1,"Failed to add voice.");

  if(sccp->do_deps) scc_parser_add_dep(sccp,$4);
}
;

voicedecl: VOICE SYM
{
  $$ = scc_ns_decl(sccp->ns,NULL,$2,SCC_RES_VOICE,0,-1);
  if(!$$) SCC_ABORT(@1,"Declaration failed.\n");
}
;

synclist: INTEGER
{
  $$ = malloc(2*sizeof(int));
  $$[0] = 1;
  $$[1] = $1;
}
| synclist ',' INTEGER
{
  int l = $1[0]+1;
  $$ = realloc($1,(l+1)*sizeof(int));
  $$[l] = $3;
  $$[0] = l;
}
;

integerlist
	: INTEGER
	{
		$$ = malloc(2*sizeof(int));
		$$[0] = 1;
		$$[1] = $1;
	}
	| integerlist INTEGER
	{
		int l = $1[0]+1;
		$$ = realloc($1,(l+1)*sizeof(int));
		$$[l] = $2;
		$$[0] = l;
	}
	;


// generic resource declaration/definition
resdecl: RESTYPE SYM location resdef
{
  scc_symbol_t* r = scc_ns_decl(sccp->ns,NULL,$2,$1,0,$3);
  
  if($4) {
    scc_parser_find_res(sccp,&$4);
    // then we need to add that to the roobj
    if(!sccp->do_deps && !scc_roobj_add_res(sccp->roobj,r,$4))
      SCC_ABORT(@2,"Failed to declare %s.\n",$2);
    if(sccp->do_deps) scc_parser_add_dep(sccp,$4);

    if(!r->rid) scc_ns_get_rid(sccp->ns,r);
  }
  $$ = $1; // propagate type  
}
| resdecl ',' SYM location resdef
{
  scc_symbol_t* r = scc_ns_decl(sccp->ns,NULL,$3,$1,0,$4);
  
  if($5) {
    scc_parser_find_res(sccp,&$5);
    // then we need to add that to the roobj
    if(!sccp->do_deps && !scc_roobj_add_res(sccp->roobj,r,$5))
      SCC_ABORT(@3,"Failed to declare %s.\n",$3);
    if(sccp->do_deps) scc_parser_add_dep(sccp,$5);

    if(!r->rid) scc_ns_get_rid(sccp->ns,r);
  }
  $$ = $1; // propagate type
}
;

resdef: /* NOTHING */
{
  $$ = NULL;
}
| ASSIGN STRING
{
  if($1 != '=')
    SCC_ABORT(@1,"Invalid operator for resource definition.\n");
  $$ = $2;
}
;

costumes_gdecl
	: COSTUMES symlist_commasep
	{
		scc_scr_arg_t* a;
		scc_symbol_t* sym;
		for (a=$2;a;a=a->next)
		{
			sym=scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_COST,0,-1);
			
			if(!sym)
				SCC_ABORT(@2, "Symbol '%s' couldn't be created.\n", a->sym);
			
			//Clean
			free(a->sym);
		}
		
		//Clean
		SCC_LIST_FREE($2, a);
	}
	;

sounds_gdecl
	: SOUNDS symlist_commasep
	{
		scc_scr_arg_t* a;
		scc_symbol_t* sym;
		for (a=$2;a;a=a->next)
		{
			sym=scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_SOUND,0,-1);
			
			if(!sym)
				SCC_ABORT(@2, "Symbol '%s' couldn't be created.\n", a->sym);
			
			//Clean
			free(a->sym);
		}
		
		//Clean
		SCC_LIST_FREE($2, a);
	}
	;


costumes_block
	: COSTUMES open_block sympath_list close_block
	{
		scc_sympath_t* s;
		scc_symbol_t* r;

		for(s=$3;s;s=s->next)
		{
			//Get symbol
			r = scc_ns_get_sym(sccp->ns, NULL, s->sym);
			if (!r)
				SCC_ABORT(@2, "costume '%s' not defined.\n", s->sym);
			if (r->type != SCC_RES_COST)
				SCC_ABORT(@2, "symbol '%s' not defined as costume.\n", s->sym);
				
			//Get resource data
			scc_parser_find_res(sccp, &s->path);
			// Attach both
//			if(!sccp->do_deps && !scc_roobj_add_res(sccp->roobj,r,s->path));
			if(!scc_roobj_add_res(sccp->roobj,r,s->path))
				SCC_ABORT(@2,"Failed to add costume resource '%s'.\n",s->sym);
//			if(sccp->do_deps) scc_parser_add_dep(sccp,s->path);
			
			if(!r->rid) scc_ns_get_rid(sccp->ns,r);
			
			//Clean data once used
			free(s->path);
			free(s->sym);
		}
		
		//Clean memory
		SCC_LIST_FREE($3, s);
	}
	;

sounds_block
	: SOUNDS open_block sympath_list close_block
	{
		scc_sympath_t* s;
		scc_symbol_t* r;

		for(s=$3;s;s=s->next)
		{
			//Get symbol
			r = scc_ns_get_sym(sccp->ns, NULL, s->sym);
			if (!r)
				SCC_ABORT(@2, "sounds '%s' not defined.\n", s->sym);
			if (r->type != SCC_RES_SOUND)
				SCC_ABORT(@2, "symbol '%s' not defined as sound.\n", s->sym);
				
			//Get resource data
			scc_parser_find_res(sccp, &s->path);
			// Attach both
//			if(!sccp->do_deps && !scc_roobj_add_res(sccp->roobj,r,s->path));
//			if(!scc_roobj_add_res(sccp->roobj,r,s->path))
			if(!scc_roobj_add_soundfile(sccp->roobj, r, s->path, 0, NULL, sccp->target->version))
				SCC_ABORT(@2,"Failed to add sound resource '%s'.\n",s->sym);
//			if(sccp->do_deps) scc_parser_add_dep(sccp,s->path);
			
			if(!r->rid) scc_ns_get_rid(sccp->ns,r);
			
			//Clean data once used
			free(s->path);
			free(s->sym);
		}
		
		//Clean memory
		SCC_LIST_FREE($3, s);
	}
	;


sympath_list
	: sympath
	{
		$$ = $1;
	}
	| sympath_list sympath
	{
		scc_sympath_t* s;
		
		for(s=$1;s->next;s=s->next);
		s->next = $2;
		$$= $1;
	}
	;
	
sympath
	: STRING SYM NEWLINE
	{
		scc_sympath_t* sympath = calloc(1, sizeof(scc_sympath_t));
		sympath->sym = $2;
		sympath->path = $1;
		$$ = sympath;
	}
	;


/*
// params chain, we can't use the same as the room
// bcs we don't want ressource declaration here
objectparams: objectparam ';'
| objectparams objectparam ';'
;
*/

objectparams2
	: objectparam2
	| objectparams2 objectparam2
	;

objectparam2
	: NAME IS STRING NEWLINE
	{
	if(!scc_roobj_obj_set_param(sccp->obj, "name",$3))
		SCC_ABORT(@1,"Failed to set object parameter.\n");
	}
	| CLASS IS integerlist NEWLINE
	{
		int i, length= $3[0];
		for (i=0;i<length;i++)
			scc_roobj_obj_set_classpos(sccp->obj, $3[i]);
	}
	| flem_header flemdecls_obj close_block
	{
	}
	| objectverbs2
	{
	}
	;
	


// used by objects
//objectparam: SYM ASSIGN STRING
flemdecl_obj: SYM ASSIGN STRING
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  if(!scc_roobj_obj_set_param(sccp->obj,$1,$3))
    SCC_ABORT(@1,"Failed to set object parameter.\n");
}
| SYM ASSIGN natural
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  if(!scc_roobj_obj_set_int_param(sccp->obj,$1,$3))
    SCC_ABORT(@1,"Failed to set object parameter.\n");

}
| SYM ASSIGN '{' imgdecls '}'
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");
  // bitch on the keyword
  if(strcmp($1,"states"))
    SCC_ABORT(@1,"Expected \"images\".\n");
}
| SYM ASSIGN SYM
{
  scc_symbol_t* sym;

  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");

  if(!strcmp($1,"owner")) {
    sym = scc_ns_get_sym(sccp->ns,NULL,$3);
    if(!sym)
      SCC_ABORT(@3,"%s is not a declared actor.\n",$3);
    if(sym->type != SCC_RES_ACTOR)
      SCC_ABORT(@3,"%s is not an actor.\n",sym->sym);
  
    sccp->obj->owner = sym;

  } else if(!strcmp($1,"parent")) {
    sym = scc_ns_get_sym(sccp->ns,NULL,$3);
    if(!sym)
      SCC_ABORT(@3,"%s is not a declared object.\n",$3);
    if(sym->type != SCC_RES_OBJ)
      SCC_ABORT(@3,"%s is not an object.\n",sym->sym);
    if(sym->parent != sccp->roobj->sym)
      SCC_ABORT(@3,"%s doesn't belong to room %s.\n",sym->sym,sccp->roobj->sym->sym);

    sccp->obj->parent = sym;
  } else
    SCC_ABORT(@1,"Expected 'owner' or 'parent'.\n");
    
}
| CLASS ASSIGN '{' classlist '}'
{
  if($2 != '=')
    SCC_ABORT(@2,"Invalid operator for parameter setting.\n");
}
;




classlist: SYM
{
  scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$1);

  if(!sym)
    SCC_ABORT(@1,"%s is not a declared class.\n",$1);

  if(sym->type != SCC_RES_CLASS)
    SCC_ABORT(@1,"%s is not a class in the current context.\n",$1);

  // allocate an rid
  if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);

  if(!scc_roobj_obj_set_class(sccp->obj,sym))
    SCC_ABORT(@1,"Failed to set object class.\n");

}
| classlist ',' SYM
{
  scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$3);

  if(!sym)
    SCC_ABORT(@3,"%s is not a declared class.\n",$3);

  if(sym->type != SCC_RES_CLASS)
    SCC_ABORT(@3,"%s is not a class in the current context.\n",$3);

  // allocate an rid
  if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);

  if(!scc_roobj_obj_set_class(sccp->obj,sym))
    SCC_ABORT(@3,"Failed to set object class.\n");
}
;

imgdecls: imgdecl
| imgdecls ',' imgdecl
;

imgdecl: '{' natural ',' natural ',' STRING '}'
{
  scc_parser_find_res(sccp,&$6);
  if(!scc_roobj_obj_add_state(sccp->obj,$2,$4,$6,NULL))
    SCC_ABORT(@1,"Failed to add room state\n");
  if(sccp->do_deps) scc_parser_add_dep(sccp,$6);
}
| '{' natural ',' natural ',' STRING ',' '{' zbufs '}' '}'
{
  scc_parser_find_res(sccp,&$6);
  if(!scc_roobj_obj_add_state(sccp->obj,$2,$4,$6,$9))
    SCC_ABORT(@2,"Failed to add room state.\n");
  if(sccp->do_deps) scc_parser_add_dep(sccp,$6);
}
;

zbufs: STRING
{
  scc_parser_find_res(sccp,&$1);
  scc_parser_add_dep(sccp,$1);
  $$ = malloc(2*sizeof(char*));
  $$[0] = $1;
  $$[1] = NULL;
}
| zbufs ',' STRING
{
  int l;
  scc_parser_find_res(sccp,&$3);
  scc_parser_add_dep(sccp,$3);
  for(l = 0 ; $1[l] ; l++);
  $$ = realloc($1,(l+2)*sizeof(char*));
  $$[l] = $3;
  $$[l+1] = NULL;
}
;

objectverbs: /* nothing */
{
}
| verbentrydecl '{' vardecl verbsblock '}'
{
  scc_verb_script_t* v,*l;
  scc_script_t* scr;

  for(v = $4 ; v ; l = v, v = v->next,free(l) ) {
    if(!sccp->do_deps && v->inst)
      scr = scc_script_new(sccp->ns,v->inst,SCC_OP_VERB_RET,v->next ? 0 : 1);
    else
      scr = calloc(1,sizeof(scc_script_t));
    scr->sym = v->sym;
    if(!scc_roobj_obj_add_verb(sccp->obj,scr))
      SCC_ABORT(@1,"Failed to add verb %s.\n",v->sym ? v->sym->sym : "default");
  }    
  scc_ns_clear(sccp->ns,SCC_RES_LVAR);
  scc_ns_pop(sccp->ns);
}
;

objectverbs2
	: /* nothing */
	{
	}
//	| verb_open_block scriptbody close_block
	| verb_open_block instructions close_block
	{
		scc_verb_script_t* v,*l;
		scc_script_t* scr;

		//scriptbody should be added to the last verb entry, walk the list
		for (v=$1;v->next;v=v->next);
		v->inst = $2;

		for(v = $1 ; v ; l = v, v = v->next,free(l) ) {
			if(!sccp->do_deps && v->inst)
				scr = scc_script_new(sccp->ns,v->inst,SCC_OP_VERB_RET,v->next ? 0 : 1);
			else
				scr = calloc(1,sizeof(scc_script_t));
			
			scr->sym = v->sym;
			if(!scc_roobj_obj_add_verb(sccp->obj,scr))
				SCC_ABORT(@1,"Failed to add verb %s.\n",v->sym ? v->sym->sym : "default");
		}
//		scc_ns_clear(sccp->ns,SCC_RES_LVAR);
//		scc_ns_pop(sccp->ns);
	}
	;

verb_open_block
	: VERB verb_symbols open_block
	{
		scc_symbol_t **array, *a;
		scc_verb_script_t *objverbList=NULL, *last=NULL, *vscr;
		int i,l;
		
		for(i=0;$2[i];i++)
		{
			vscr = calloc(1,sizeof(scc_verb_script_t));
			vscr->sym = $2[i];
			vscr->inst = NULL;
			SCC_LIST_ADD(objverbList, last, vscr);
		}
	
		free($2);
		
		$$ = objverbList;
	}
	;

verb_symbols
	: SYM
	{
		scc_symbol_t** array;
		scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$1);
		if(!sym)
			SCC_ABORT(@1,"%s is not a declared verb.\n",$1);	
	
		if(sym->type != SCC_RES_VERB)
			SCC_ABORT(@1,"%s is not a verb in the current context.\n",$1);

		// allocate an rid
		if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);

		//Create a NULL terminated array of symbol pointers
		array = malloc(2*sizeof(scc_symbol_t**));
		array[0] = sym;
		array[1] = NULL;
		$$ = array;
	}
	| verb_symbols SYM
	{
		scc_symbol_t *sym;
		int l;
		
		sym = scc_ns_get_sym(sccp->ns,NULL,$2);
		if(!sym)
			SCC_ABORT(@1,"%s is not a declared verb.\n",$2);	
	
		if(sym->type != SCC_RES_VERB)
			SCC_ABORT(@1,"%s is not a verb in the current context.\n",$2);

		// allocate an rid
		if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);

		//Append to array
		for (l=0;$1[l];l++);	//Find length
		$$=realloc($1, (l+2)*sizeof(scc_symbol_t**));
		$$[l] = sym;
		$$[l+1] = NULL;
	}
	;


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


	
verbentrydecl: VERB '(' scriptargs ')'
{
  scc_scr_arg_t* a = $3;
  // push the obj for the local vars
  scc_ns_push(sccp->ns,sccp->obj->sym);

  // declare the arguments
  sccp->local_vars = 0;
  while(a) {
    scc_ns_decl(sccp->ns,NULL,a->sym,SCC_RES_LVAR,a->type,sccp->local_vars);
    sccp->local_vars++;
    a = a->next;
  }
}
;

verbsblock: verbentry verbcode
{
  $$ = calloc(1,sizeof(scc_verb_script_t));
  $$->sym = $1;
  $$->inst = $2;
}

| verbsblock verbentry verbcode
{
  $$ = $1;
  for(; $1 ; $1 = $1->next) {
    if($1->sym == $2)
      SCC_ABORT(@2,"Verb %s is already defined.\n",
                $2 ? $2->sym : "default");
    if(!$1->next) break;
  }
  $1->next = calloc(1,sizeof(scc_verb_script_t));
  $1 = $1->next;
  $1->sym = $2;
  $1->inst = $3;
}
;

verbcode: /* nothing */
{
  $$ = NULL;
}
| instructions
;

verbentry: CASE SYM ':'
{
  scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$2);
  if(!sym)
    SCC_ABORT(@1,"%s is not a declared verb.\n",$2);
  
  if(sym->type != SCC_RES_VERB)
    SCC_ABORT(@1,"%s is not a verb in the current context.\n",$2);

  // allocate an rid
  if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);

  $$ = sym;
}
| DEFAULT ':'
{
  $$ = NULL;
}
;

// script can be local or global. Dunno yet what will be default,
// probably global.
scripttype: /* empty */
{
  $$ = SCC_RES_SCR;
}
| SCRTYPE
{
  $$ = $1;
}
;

scriptargs: /* */
{
  $$ = NULL;
}
| TYPE typemod SYM
{
  //if($1 == SCC_VAR_BIT)
  //  SCC_ABORT(@1,"Script argument can't be of bit type.\n");

  $$ = malloc(sizeof(scc_scr_arg_t));
  $$->next = NULL;
  $$->type = $1 | $2;
  $$->sym = $3;
}
| scriptargs ',' TYPE typemod SYM
{
  scc_scr_arg_t *i,*a = malloc(sizeof(scc_scr_arg_t));
  a->next = NULL;
  a->type = $3 | $4;
  a->sym = $5;

  for(i = $1 ; i->next ; i = i->next);
  i->next = a;
  $$ = $1;
}
;

/* When scriptargs are clearly coded as C e.g. function(arg1, arg2, ...) */
scriptargs_explicit: '(' ')'
	{
		$$=NULL;
	}
	| '(' symlist_commasep ')'
	{
		$$=$2;
	}
	;

/* When scriptargs are loose separated with spaces e.g. arg1 arg2 ... */
scriptargs_loose: /* empty */
	{
		$$=NULL;	/* nothing that follows... no arguments*/
	}
	| SYM
	{
		$$ = malloc(sizeof(scc_scr_arg_t));
		$$->next = NULL;
		$$->type = SCC_RES_LVAR;
		$$->sym = $1;
	}
	| scriptargs_loose SYM
	{
		scc_scr_arg_t *i,*a;
		a = malloc(sizeof(scc_scr_arg_t));
		a->next = NULL;
		a->type = SCC_RES_LVAR;
		a->sym = $2;

		/* Sanity check, we can't duplicate symbols of arguments */
		i=$1;
		while(i)
		{
			if (!strcmp(a->sym, i->sym))
				SCC_ABORT(@1, "Illegal duplication of argument \'%s\'\n", a->sym);
			i = i->next;
		}

		for(i = $1 ; i->next ; i = i->next);	//Find the end of the list
		i->next = a;
		$$ = $1;
	}
	;

scriptargs_all: /*empty*/
	| scriptargs_explicit
	{
		$$= $1;
	}
	| scriptargs_loose
	{
		$$ = $1;
	}
	;

symlist_commasep: /* empty */
	| SYM
	{
		$$ = malloc(sizeof(scc_scr_arg_t));
		$$->next = NULL;
		$$->type = SCC_RES_LVAR;
		$$->sym = $1;
	}
	| symlist_commasep ',' SYM
	{
		scc_scr_arg_t *i,*a;
		a = malloc(sizeof(scc_scr_arg_t));
		a->next = NULL;
		a->type = SCC_RES_LVAR;
		a->sym = $3;

		/* Sanity check, we can't duplicate symbols of arguments */
		i=$1;
		while(i)
		{
			if (!strcmp(a->sym, i->sym))
				SCC_ABORT(@1, "Illegal duplication of argument \'%s\'\n", a->sym);
			i = i->next;
		}

		for(i = $1 ; i->next ; i = i->next);	//Find the end of the list
		i->next = a;
		$$ = $1;
	}
	;


location: /* empty */
{
  $$ = -1;
}
| '@' INTEGER
{
  $$ = $2;
}
;

scriptbody:  /* empty */
{
  $$ = NULL;
}

| vardecl instructions
{
  if(sccp->do_deps)
    $$ = NULL;
  else {
    $$ = scc_script_new(sccp->ns,$2,SCC_OP_SCR_RET,1);
    if(!$$)
      SCC_ABORT(@1,"Code generation failed.\n");
  }
}
;


// bit, nibble, char, byte, int
vardecl: /* empty */
| vardec
;

vardec: vdecl NEWLINE //';'
{
}
| vardec vdecl NEWLINE //';'
;

/// this will only decl local vars
vdecl: TYPE typemod SYM
{
  //if($1 == SCC_VAR_BIT)
  //  SCC_ABORT(@1,"Local bit variable are not possible.\n");
//	printf("declare symbol '%s'at local_vars = %d\n",$3, sccp->local_vars);	//MAN 

  $$ = scc_ns_decl(sccp->ns,NULL,$3,SCC_RES_LVAR,$1 | $2,sccp->local_vars);
  if(!$$) SCC_ABORT(@1,"Declaration failed for \'%s\'.\n", $3);
  sccp->local_vars++;
}

| vdecl ',' typemod SYM
{
  $$ = scc_ns_decl(sccp->ns,NULL,$4,SCC_RES_LVAR,$1->subtype | $3,sccp->local_vars);
  if(!$$) SCC_ABORT(@4,"Declaration failed for \'%s\'.\n", $4);
  sccp->local_vars++;
  $$ = $1;
};


body: instruct
{
  $$ = $1;
}

//| '{' instructions '}'
| open_block instructions close_block
{
  $$ = $2;
}
| open_block close_block
{
	$$ = NULL;		//TODO: If we tolerate empty block of instructions
}
;


instructions: instruct
{
  $$ = $1;
}

| instructions instruct
{
  scc_instruct_t* i;
  for(i = $1 ; i->next ; i = i->next);
  i->next = $2;
}
;

instruct: oneinstruct NEWLINE //';'
| block
;

oneinstruct: statements
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_ST;
  $$->pre = $1;
}

| BRANCH
{
  scc_loop_t* l = scc_loop_get($1,NULL);
  if(!l)
    SCC_ABORT(@1,"Invalid branch instruction.\n");
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_BRANCH;
  $$->subtype = $1;
}

| BRANCH SYM
{
  scc_loop_t* l = scc_loop_get($1,$2);
  if(!l)
    SCC_ABORT(@1,"Invalid branch instruction.\n");
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_BRANCH;
  $$->subtype = $1;
  $$->sym = $2;
}

| RETURN
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_BRANCH;
  $$->subtype = $1;
}

| RETURN statements
{
  if($1 != SCC_BRANCH_RETURN) {
    scc_loop_t* l = scc_loop_get($1,NULL);
    if(!l)
      SCC_ABORT(@1,"Invalid branch instruction.\n");
  }
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_BRANCH;
  $$->subtype = $1;
  $$->pre = $2;
}
	| verb_statement
	{
		$$ = $1;
	}
	| actor_statement
	{
		$$ = $1;
	}	
	;


dobody: oneinstruct
{
  $$ = $1;
}

| '{' instructions '}'
{
  $$ = $2;
}
;

block: ifblock
{
  $$ = $1;
}
| cutsceneblock

| loopblock
{
  $$ = $1;
}
;

loopblock: loophead body
{
  $$ = $1;
  $$->body = $2;
  free(scc_loop_pop());
}
| dohead dobody WHILE '(' statements ')' ';'
{
  $$ = $1;
  $$->subtype = $3;
  $$->cond = $5;
  $$->body = $2;
  free(scc_loop_pop());
}
// SCUMM: do {} until ()
| dohead open_block instructions '}' WHILE '(' statements ')' NEWLINE
{
  $$ = $1;
  $$->subtype = $5;
  $$->cond = $7;
  $$->body = $3;
  free(scc_loop_pop());
}
// SCUMM: do {} note:infinite loop
| dohead open_block instructions close_block
{
	scc_statement_t* cond;

	$$ = $1;
	$$->subtype = WHILE;
	$$->body = $3;

	cond = calloc(1, sizeof(scc_statement_t));
	cond->type = SCC_ST_VAL;
	cond->val.i = 1;	//Always true
	$$->cond = cond;

	free(scc_loop_pop());
}

//| switchhead  '{' switchblock  '}'
| switchhead  open_block switchblock2  close_block
{
  $$ = $1;
  $$->body = $3;
  free(scc_loop_pop());
}
;

for_ops: ISOLATED_INC
	{
		$$=ISOLATED_INC;
	}
	| ISOLATED_DEC
	{
		$$=ISOLATED_DEC;
	}
	;

loophead: label FOR '(' opt_statements ';' statements ';' opt_statements ')'
{
	$$ = calloc(1,sizeof(scc_instruct_t));
	$$->type = SCC_INST_FOR;
	$$->sym = $1;
	$$->pre = $4;
	$$->cond = $6;
	$$->post = $8;
	scc_loop_push($$->type,$$->sym);
}
| label FOR statements TO restricted_statement for_ops		//SCUMM
{
	scc_statement_t *post;
	$$ = calloc(1,sizeof(scc_instruct_t));
	$$->type = SCC_INST_FOR;
	$$->sym = $1;
	$$->pre = $3;

	//Check that $5->type = SCC_ST_VAL;

	//  SCC_BOP($$,<,$1,$2,$3);
	SCC_BOP($$->cond,<,$3->val.o.argv,'<',$5);
//	$$->cond = $5;	//TODO: instruction must be created
	
	post = calloc(1,sizeof(scc_statement_t));
	post->type = SCC_ST_OP;
	post->val.o.type = SCC_OT_UNARY;
	post->val.o.op = ($6 == ISOLATED_INC) ? POSTINC : POSTDEC;
	post->val.o.argc = 1;
	post->val.o.argv = $3->val.o.argv;
	$$->post = post;

//printf("Inside SCUMM for loop header\n");	//MAN

//	$$->cond = $5;	//TODO: instruction must be created
//	$$->post = $6;	//TODO: instruction must be created
	scc_loop_push($$->type,$$->sym);
}
| label WHILE '(' statements ')'
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_WHILE;
  $$->sym = $1;
  $$->subtype = $2;
  $$->cond = $4;
  scc_loop_push($$->type,$$->sym);
}
;

dohead: label DO
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_DO;
  $$->sym = $1;
  scc_loop_push($$->type,$$->sym);
}
;

switchhead: label SWITCH '(' statements ')'
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_SWITCH;
  $$->sym = $1;
  $$->cond = $4;
  scc_loop_push($$->type,$$->sym);
}
| label SWITCH statements		//In SCUMMM, parenthesis are optional
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_SWITCH;
  $$->sym = $1;
  $$->cond = $3;
  scc_loop_push($$->type,$$->sym);
}
;

label: /* nothing */
{
  $$ = NULL;
}
| SYM ':'
{
  $$ = $1;
}
;

cutsceneblock: CUTSCENE '(' cargs ')' body
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_CUTSCENE;
  $$->cond = $3;
  $$->body = $5;
}

| TRY body
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_OVERRIDE;
  $$->body = $2;
}

| TRY body OVERRIDE body
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_OVERRIDE;
  $$->body = $2;
  $$->body2 = $4;
}
;


//This is experimental
switchblock2
	: caseheader open_block instructions close_block
	{
		$$ = calloc(1,sizeof(scc_instruct_t));
		$$->type = SCC_INST_CASE;
		$$->cond = $1;
		$$->body = $3; 
	}
	| switchblock2 caseheader open_block instructions close_block
	{
		scc_instruct_t *n,*i;

		for(i = $1 ; i->next ; i = i->next);
		if(!i->cond)
			SCC_ABORT(@2,"Case statements can't be added after a default.\n");

		n = calloc(1,sizeof(scc_instruct_t));
		n->type = SCC_INST_CASE;
		n->cond = $2;
		n->body = $4;

		i->next = n;

		$$ = $1;
	}
	;

caseheader
	: CASE statement
	{
		$$ = $2;
	}
	| DEFAULT
	{
		$$ = NULL;
	}
	;



switchblock: caseblock instructions
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_CASE;
  $$->cond = $1;
  $$->body = $2; 
}

| switchblock caseblock instructions
{
  scc_instruct_t *n,*i;

  for(i = $1 ; i->next ; i = i->next);
  if(!i->cond)
    SCC_ABORT(@2,"Case statements can't be added after a default.\n");

  n = calloc(1,sizeof(scc_instruct_t));
  n->type = SCC_INST_CASE;
  n->cond = $2;
  n->body = $3;

  i->next = n;
  
  $$ = $1;
}
;

caseblock: caseval
{
  $$ = $1;
}

| DEFAULT ':'
{
  $$ = NULL;
};

caseval: CASE statement ':'
{
  $$ = $2;
}

| caseval CASE statement ':'
{
  scc_statement_t* a;
  for(a = $1 ; a->next ; a = a->next);
  a->next = $3;
  $$ = $1;
}
;

ifblock: IF '(' statements ')' body
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_IF;
  $$->subtype = $1;
  $$->cond = $3;
  $$->body = $5;
}

| IF '(' statements ')' body ELSE body
{
  $$ = calloc(1,sizeof(scc_instruct_t));
  $$->type = SCC_INST_IF;
  $$->subtype = $1;
  $$->cond = $3;
  $$->body = $5;
  $$->body2 = $7;
};


// statement chain
statements: statement
{
  // single statement stay as-is
  $$ = $1;
}
| statements ',' statement
{
  scc_statement_t* i;

  // no chain yet, create it
  if($1->type != SCC_ST_CHAIN) {
    $$ = calloc(1,sizeof(scc_statement_t));
    $$->type = SCC_ST_CHAIN;
    // init the chain
    $$->val.l = $1;
  } else
    $$ = $1;

  // append the new element
  for(i = $$->val.l ; i->next ; i = i->next);
  i->next = $3;
}
;

// optional statements
opt_statements: /* NOTHING */
{
  $$ = NULL;
}
| statements
{
  $$ = $1;
}
;

/*
for_cond_statement
	: var ASSIGN dval
	{
		$$ = calloc(1,sizeof(scc_statement_t));
		$$->type = SCC_ST_OP;
		$$->val.o.type = SCC_OT_ASSIGN;
		$$->val.o.op = $2;
		$$->val.o.argc = 2;
		$$->val.o.argv = $1;
		$1->next = $3;
	}
	;
*/
//ATTENTION: This rule is created just because of the for loop
//Second term needs a statement with no var++ or var-- as this created conflict
restricted_statement: dval
{
  $$ = $1;
}

| var
{
  $$ = $1;
}

| var '[' restricted_statement ']'
{
  scc_symbol_t* v;

  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"%s is not a variable, so it can't be subscripted.\n",
	      $1->val.r->sym);
  v = $1->val.v.r;
  if(!(v->subtype & SCC_VAR_ARRAY))
    SCC_ABORT(@1,"%s is not an array variable, so it can't be subscripted.\n",v->sym);
  $$ = $1;
  $$->val.v.y = $3;
}

| var '[' restricted_statement ',' restricted_statement ']'
{
  scc_symbol_t* v;

  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"%s is not a variable, so it can't be subscripted.\n",
	      $1->val.r->sym);
  v = $1->val.v.r;
  if(!(v->subtype & SCC_VAR_ARRAY))
    SCC_ABORT(@1,"%s is not an array variable, so it can't be subscripted.\n",v->sym);
  $$ = $1;
  $$->val.v.x = $3;
  $$->val.v.y = $5;
}

| call
{
  $$ = $1;
}

| '[' cargs ']'
{
  scc_statement_t* a;
  
  for(a = $2 ; a ; a = a->next) {
    if(a->type == SCC_ST_STR ||
       a->type == SCC_ST_LIST)
      SCC_ABORT(@2,"Strings and lists can't be used inside a list.\n");
  }

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_LIST;
  $$->val.l = $2;
}

| restricted_statement ASSIGN restricted_statement
{
  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"rvalue is not a variable, so it can't be assigned.\n");

  if(!($1->val.v.r->subtype & SCC_VAR_ARRAY) &&
     ($3->type == SCC_ST_STR ||
      $3->type == SCC_ST_LIST))
      SCC_ABORT(@1,"list and strings can only be assigned to "
                "array variables.\n");

  if($1->val.v.x && $3->type == SCC_ST_STR)
    SCC_ABORT(@1,"Strings can't be assigned to 2-dim arrays.\n");

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_ASSIGN;
  $$->val.o.op = $2;
  $$->val.o.argc = 2;
  $$->val.o.argv = $1;
  $1->next = $3;
}

| restricted_statement '?' restricted_statement ':' restricted_statement
{
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_TERNARY;
  $$->val.o.op = $2;
  $$->val.o.argc = 3;
  $$->val.o.argv = $1;
  $1->next = $3;
  $3->next = $5;
}

| restricted_statement LOR restricted_statement
{
  SCC_BOP($$,||,$1,$2,$3);
}

| restricted_statement LAND restricted_statement
{
  SCC_BOP($$,&&,$1,$2,$3);
}

| restricted_statement IS isargs
{
  scc_func_t* f;
  scc_statement_t *a,*list;
  char* err;
  
  f = scc_get_func(sccp,"isObjectOfClass");
  if(!f)
    SCC_ABORT(@1,"Internal error: isObjectOfClass not found.\n");
  
  // create the arguments
  list = calloc(1,sizeof(scc_statement_t));
  list->type = SCC_ST_LIST;
  list->val.l = $3;
  
  $1->next = list;
  
  // create the call
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_CALL;
  
  $$->val.c.func = f;
  $$->val.c.argv = $1;
  
  for(a = $1 ; a ; a = a->next)
    $$->val.c.argc++;
  
  err = scc_statement_check_func(&$$->val.c);
  if(err)
    SCC_ABORT(@1,"%s",err);
}

| restricted_statement '|' restricted_statement
{
  SCC_BOP($$,|,$1,$2,$3);
}

| restricted_statement '&' restricted_statement
{
  SCC_BOP($$,&,$1,$2,$3);
}

| restricted_statement NEQ restricted_statement
{
  SCC_BOP($$,!=,$1,$2,$3);
}

| restricted_statement EQ restricted_statement
{
  SCC_BOP($$,==,$1,$2,$3);
}

| restricted_statement GE restricted_statement
{
  SCC_BOP($$,>=,$1,$2,$3);
}

| restricted_statement '>' restricted_statement
{
  SCC_BOP($$,>,$1,$2,$3);
}

| restricted_statement LE restricted_statement
{
  SCC_BOP($$,<=,$1,$2,$3);
}

| restricted_statement '<' restricted_statement
{
  SCC_BOP($$,<,$1,$2,$3);
}

| restricted_statement '-' restricted_statement
{
  SCC_BOP($$,-,$1,$2,$3);
}

| restricted_statement '+' restricted_statement
{
  SCC_BOP($$,+,$1,$2,$3);
}

| restricted_statement '/' restricted_statement
{
  SCC_BOP($$,/,$1,$2,$3);
}

| restricted_statement '*' restricted_statement
{
  SCC_BOP($$,*,$1,$2,$3);
}

| '-' restricted_statement %prec NEG
{
   if($2->type == SCC_ST_VAL) {
    $2->val.i = -$2->val.i;
    $$ = $2;
  } else { 
    $$ = calloc(1,sizeof(scc_statement_t));
    $$->type = SCC_ST_OP;
    $$->val.o.type = SCC_OT_UNARY;
    $$->val.o.op = $1;
    $$->val.o.argc = 1;
    $$->val.o.argv = $2;
  }
}

| '!' restricted_statement
{
  if($2->type == SCC_ST_VAL) {
    $2->val.i = ! $2->val.i;
    $$ = $2;
  } else { // we call not
    $$ = calloc(1,sizeof(scc_statement_t));
    $$->type = SCC_ST_OP;
    $$->val.o.type = SCC_OT_UNARY;
    $$->val.o.op = $1;
    $$->val.o.argc = 1;
    $$->val.o.argv = $2;
  }
}
| '(' restricted_statement ')'
{
  $$ = $2;
}
;


statement: dval
{
  $$ = $1;
}

| var
{
  $$ = $1;
}

| var '[' statement ']'
{
  scc_symbol_t* v;

  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"%s is not a variable, so it can't be subscripted.\n",
	      $1->val.r->sym);
  v = $1->val.v.r;
  if(!(v->subtype & SCC_VAR_ARRAY))
    SCC_ABORT(@1,"%s is not an array variable, so it can't be subscripted.\n",v->sym);
  $$ = $1;
  $$->val.v.y = $3;
}

| var '[' statement ',' statement ']'
{
  scc_symbol_t* v;

  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"%s is not a variable, so it can't be subscripted.\n",
	      $1->val.r->sym);
  v = $1->val.v.r;
  if(!(v->subtype & SCC_VAR_ARRAY))
    SCC_ABORT(@1,"%s is not an array variable, so it can't be subscripted.\n",v->sym);
  $$ = $1;
  $$->val.v.x = $3;
  $$->val.v.y = $5;
}

| call
{
  $$ = $1;
}

| '[' cargs ']'
{
  scc_statement_t* a;
  
  for(a = $2 ; a ; a = a->next) {
    if(a->type == SCC_ST_STR ||
       a->type == SCC_ST_LIST)
      SCC_ABORT(@2,"Strings and lists can't be used inside a list.\n");
  }

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_LIST;
  $$->val.l = $2;
}

| statement ASSIGN statement
{
  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"rvalue is not a variable, so it can't be assigned.\n");

  if(!($1->val.v.r->subtype & SCC_VAR_ARRAY) &&
     ($3->type == SCC_ST_STR ||
      $3->type == SCC_ST_LIST))
      SCC_ABORT(@1,"list and strings can only be assigned to "
                "array variables.\n");

  if($1->val.v.x && $3->type == SCC_ST_STR)
    SCC_ABORT(@1,"Strings can't be assigned to 2-dim arrays.\n");

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_ASSIGN;
  $$->val.o.op = $2;
  $$->val.o.argc = 2;
  $$->val.o.argv = $1;
  $1->next = $3;
}

| statement '?' statement ':' statement
{
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_TERNARY;
  $$->val.o.op = $2;
  $$->val.o.argc = 3;
  $$->val.o.argv = $1;
  $1->next = $3;
  $3->next = $5;
}

| statement LOR statement
{
  SCC_BOP($$,||,$1,$2,$3);
}

| statement LAND statement
{
  SCC_BOP($$,&&,$1,$2,$3);
}

| statement IS isargs
{
  scc_func_t* f;
  scc_statement_t *a,*list;
  char* err;
  
  f = scc_get_func(sccp,"isObjectOfClass");
  if(!f)
    SCC_ABORT(@1,"Internal error: isObjectOfClass not found.\n");
  
  // create the arguments
  list = calloc(1,sizeof(scc_statement_t));
  list->type = SCC_ST_LIST;
  list->val.l = $3;
  
  $1->next = list;
  
  // create the call
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_CALL;
  
  $$->val.c.func = f;
  $$->val.c.argv = $1;
  
  for(a = $1 ; a ; a = a->next)
    $$->val.c.argc++;
  
  err = scc_statement_check_func(&$$->val.c);
  if(err)
    SCC_ABORT(@1,"%s",err);
}

| statement '|' statement
{
  SCC_BOP($$,|,$1,$2,$3);
}

| statement '&' statement
{
  SCC_BOP($$,&,$1,$2,$3);
}

| statement NEQ statement
{
  SCC_BOP($$,!=,$1,$2,$3);
}

| statement EQ statement
{
  SCC_BOP($$,==,$1,$2,$3);
}

| statement GE statement
{
  SCC_BOP($$,>=,$1,$2,$3);
}

| statement '>' statement
{
  SCC_BOP($$,>,$1,$2,$3);
}

| statement LE statement
{
  SCC_BOP($$,<=,$1,$2,$3);
}

| statement '<' statement
{
  SCC_BOP($$,<,$1,$2,$3);
}

| statement '-' statement
{
  SCC_BOP($$,-,$1,$2,$3);
}

| statement '+' statement
{
  SCC_BOP($$,+,$1,$2,$3);
}

| statement '/' statement
{
  SCC_BOP($$,/,$1,$2,$3);
}

| statement '*' statement
{
  SCC_BOP($$,*,$1,$2,$3);
}

| '-' statement %prec NEG
{
   if($2->type == SCC_ST_VAL) {
    $2->val.i = -$2->val.i;
    $$ = $2;
  } else { 
    $$ = calloc(1,sizeof(scc_statement_t));
    $$->type = SCC_ST_OP;
    $$->val.o.type = SCC_OT_UNARY;
    $$->val.o.op = $1;
    $$->val.o.argc = 1;
    $$->val.o.argv = $2;
  }
}

| '!' statement
{
  if($2->type == SCC_ST_VAL) {
    $2->val.i = ! $2->val.i;
    $$ = $2;
  } else { // we call not
    $$ = calloc(1,sizeof(scc_statement_t));
    $$->type = SCC_ST_OP;
    $$->val.o.type = SCC_OT_UNARY;
    $$->val.o.op = $1;
    $$->val.o.argc = 1;
    $$->val.o.argv = $2;
  }
}

| SUFFIX statement %prec PREFIX
{
  if($2->type != SCC_ST_VAR)
    SCC_ABORT(@1,"Suffix operators can only be used on variables.\n");

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_UNARY;
  $$->val.o.op = ($1 == INC ? PREINC : PREDEC);
  $$->val.o.argc = 1;
  $$->val.o.argv = $2;
}

| statement SUFFIX %prec POSTFIX
{
  if($1->type != SCC_ST_VAR)
    SCC_ABORT(@1,"Suffix operators can only be used on variables.\n");

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_OP;
  $$->val.o.type = SCC_OT_UNARY;
  $$->val.o.op = ($2 == INC) ? POSTINC : POSTDEC;
  $$->val.o.argc = 1;
  $$->val.o.argv = $1;
}

| '(' statements ')'
{
  $$ = $2;
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


var: SYM
{
  scc_symbol_t* v = scc_ns_get_sym(sccp->ns,NULL,$1);

  if(sccp->do_deps && !v)
    v = scc_ns_decl(sccp->ns,NULL,$1,SCC_RES_VAR,SCC_VAR_WORD,-1);

  if(!v)
    SCC_ABORT(@1,"%s is not a declared resource.\n",$1);

  $$ = calloc(1,sizeof(scc_statement_t));
  if(scc_sym_is_var(v->type)) {
    $$->type = SCC_ST_VAR;
    $$->val.v.r = v;
  } else {
    $$->type = SCC_ST_RES;
    $$->val.r = v;
  }
  // allocate rid
  if(!v->rid) scc_ns_get_rid(sccp->ns,v);
}
| SYM NS SYM
{
  scc_symbol_t* v = scc_ns_get_sym(sccp->ns,$1,$3);

  if(sccp->do_deps && !v)
    v = scc_ns_decl(sccp->ns,$1,$3,SCC_RES_VAR,SCC_VAR_WORD,-1);

  if(!v)
    SCC_ABORT(@1,"%s::%s is not a declared resource.\n",$1,$3);

  $$ = calloc(1,sizeof(scc_statement_t));
  if(scc_sym_is_var(v->type)) {
    $$->type = SCC_ST_VAR;
    $$->val.v.r = v;
  } else {
    $$->type = SCC_ST_RES;
    $$->val.r = v;
  }
  // allocate rid
  if(!v->rid) scc_ns_get_rid(sccp->ns,v);

}
;

call: SYM '(' cargs ')'
{
  scc_statement_t *a,*scr,*list;
  scc_func_t* f;
  scc_symbol_t* s;
  char* err;
  int user_script = 0;

  f = scc_get_func(sccp,$1);
  if(!f) {
    s = scc_ns_get_sym(sccp->ns,NULL,$1);
    if(!s || (s->type != SCC_RES_SCR && s->type != SCC_RES_LSCR))
      SCC_ABORT(@1,"%s is not a known function or script.\n",$1);

    f = scc_get_func(sccp,"startScript0");
    if(!f)
      SCC_ABORT(@1,"Internal error: startScriptQuick not found.\n");

    if(!s->rid) scc_ns_get_rid(sccp->ns,s);

    // create the arguments
    scr = calloc(1,sizeof(scc_statement_t));
    scr->type = SCC_ST_RES;
    scr->val.r = s;

    list = calloc(1,sizeof(scc_statement_t));
    list->type = SCC_ST_LIST;
    list->val.l = $3;

    scr->next = list;

    $3 = scr;
    user_script = 1;
  }

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_CALL;

  $$->val.c.func = f;
  $$->val.c.user_script = user_script;
  $$->val.c.argv = $3;

  for(a = $3 ; a ; a = a->next)
    $$->val.c.argc++;

  err = scc_statement_check_func(&$$->val.c);
  if(err)
    SCC_ABORT(@1,"%s",err);
}

| SYM NS SYM '(' cargs ')'
{
  scc_statement_t *scr,*list;
  scc_func_t* f;
  scc_symbol_t* s;

  s = scc_ns_get_sym(sccp->ns,$1,$3);
  if(!s || (s->type != SCC_RES_SCR && s->type != SCC_RES_LSCR))
    SCC_ABORT(@1,"%s::%s is not a known function or script.\n",$1,$3);

  if(s->type == SCC_RES_LSCR &&
     s->parent != sccp->roobj->sym)
    SCC_ABORT(@1,"%s is a local script and %s is not the current room.\n",
              $3,$1);

  f = scc_get_func(sccp,"startScript0");
  if(!f)
    SCC_ABORT(@1,"Internal error: startScript0 not found.\n");

  if(!s->rid) scc_ns_get_rid(sccp->ns,s);

  // create the arguments
  scr = calloc(1,sizeof(scc_statement_t));
  scr->type = SCC_ST_RES;
  scr->val.r = s;
  
  list = calloc(1,sizeof(scc_statement_t));
  list->type = SCC_ST_LIST;
  list->val.l = $5;
  
  scr->next = list;

  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_CALL;

  $$->val.c.func = f;
  $$->val.c.user_script = 1;
  $$->val.c.argv = scr;
  $$->val.c.argc = 2;
}
;

cargs: 
/* empty */
{
  $$ = NULL;
}

| statement
{
  $$ = $1;
}

| cargs ',' statement
{
  scc_statement_t* i;

  $$ = $1;

  for(i = $$ ; i->next ; i = i->next);

  i->next = $3;
};

isargs: isarg
{
  $$ = $1;
}

| '[' isarglist ']'
{
  $$ = $2;
}
;

isarglist: isarg
{
  $$ = $1;
}

| isarglist ',' isarg
{
  scc_statement_t* i;
  
  $$ = $1;
  for(i = $$ ; i->next ; i = i->next);
  
  i->next = $3;
}
;

isarg: SYM
{
  scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$1);
  scc_statement_t *clsid, *bit;
  
  if(!sym)
    SCC_ABORT(@1,"%s is not a declared class.\n",$1);
  
  if(sym->type != SCC_RES_CLASS)
    SCC_ABORT(@1,"%s is not a class in the current context.\n",$1);
  
  // allocate rid
  if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);
  
  // the arg is the class id + 0x80
  clsid = calloc(1,sizeof(scc_statement_t));
  clsid->type = SCC_ST_RES;
  clsid->val.r = sym;
  
  bit = calloc(1,sizeof(scc_statement_t));
  bit->type = SCC_ST_VAL;
  bit->val.i = 0x80;
  
  SCC_BOP($$,+,clsid,'+',bit);
}

| '!' SYM
{
  scc_symbol_t* sym = scc_ns_get_sym(sccp->ns,NULL,$2);
  
  if(!sym)
    SCC_ABORT(@1,"%s is not a declared class.\n",$2);
  
  if(sym->type != SCC_RES_CLASS)
    SCC_ABORT(@1,"%s is not a class in the current context.\n",$2);
  
  // allocate rid
  if(!sym->rid) scc_ns_get_rid(sccp->ns,sym);
  
  // the arg is simply the class id
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_RES;
  $$->val.r = sym;
}
;

dval: INTEGER
{
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_VAL;
  $$->val.i = $1;
}

| string
{
  $$ = calloc(1,sizeof(scc_statement_t));
  $$->type = SCC_ST_STR;
  $$->val.s = $1;
};

string: str
{
  $$ = $1;
}
| string str
{
  scc_str_t* s;
  for(s = $1 ; s->next ; s = s->next);
  s->next = $2;
  $$ = $1;
}
;

str: STRING
{
  $$ = calloc(1,sizeof(scc_str_t));
  $$->type = SCC_STR_CHAR;
  $$->str = $1;
}
| STRVAR
{
  $$ = $1;
  // for color we have a raw value in str
  if($$->type != SCC_STR_COLOR) {
    $$->sym = scc_ns_get_sym(sccp->ns,NULL,$$->str);
    if(!$$->sym) // fix me we leak str      
      SCC_ABORT(@1,"%s is not a declared variable.\n",$$->str);

    free($$->str);
    $$->str = NULL;

    switch($$->type) {
    case SCC_STR_VERB:
    case SCC_STR_NAME:
      if($$->sym->type != SCC_RES_VAR &&
         $$->sym->type != SCC_RES_LVAR)
        SCC_ABORT(@1,"%s is not a variable",$$->sym->sym);
      break;
    case SCC_STR_VOICE:
      if($$->sym->type != SCC_RES_VOICE)
        SCC_ABORT(@1,"%s is not a voice",$$->sym->sym);
      break;
    case SCC_STR_FONT:
      if($$->sym->type != SCC_RES_CHSET)
        SCC_ABORT(@1,"%s is not a charset",$$->sym->sym);
      break;
    }
    // allocate rid
    if(!$$->sym->rid) scc_ns_get_rid(sccp->ns,$$->sym);
  }
}
;

natural: INTEGER
{
  $$ = $1;
}
| '-' INTEGER
{
  $$ = -$2;
}
;

%%

#undef yyparse
#undef yylex
#undef yyerror
#undef sccp


