/* ScummC
 * Copyright (C) 2005-2006  Alban Bedel
 *
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
 * @file cost_parse.y
 * @ingroup scumm
 * @brief Costume compiler
 */

%output "cost_parse_bison.c"
%defines "cost_lex_bison.h"
%define api.pure full
%parse-param {cost_parser_t *v_costp}
%lex-param {cost_parser_t *YYLEX_PARAM}

%code requires {
#define YYSTYPE cost_bison_val_t
#include <stdlib.h>
#include <string.h>
#include "config.h"


/* Forward declaration of typedef's */
typedef struct cost_parser cost_parser_t;
typedef struct scc_lex scc_lex_t;
typedef union cost_bison_val cost_bison_val_t;
}

%code provides{
/*
#include "cost_parse.h"
#include "cost_globals.h"
#include "cost_help.h"
*/
}

%{
/*
#include "cost_lex_bison.h"
*/
#include "cost_parse.h"
#include "cost_globals.h"
/*
#include "config.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include <errno.h>
*/
#ifndef IS_MINGW
#include <glob.h>
#endif

/*
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "scc_fd.h"
#include "scc_util.h"
#include "scc_param.h"
#include "scc_img.h"
//#include "cost_parse.tab.h"
//#include "scc_lex.h"
//#include "cost_help.h"
//#include "cost_lexer.h"
*/

#define YYERROR_VERBOSE 1
#define costp ((cost_parser_t*)v_costp)
#define YYLEX_PARAM costp->lex

/* Redefine function names */
#define yyparse cost_parser_parse_internal
//#define yylex cost_main_lexer
#define yylex scc_lex_lex
#define yyerror(loc,sccp,msg) cost_parser_error(sccp,loc,msg)

/*
typedef struct scc_lex scc_lex_t;

extern scc_lex_t* cost_lex;
*/
%}

%token PALETTE
%token FLAGS
%token LOOP FLIP
%token PICTURE
%token LIMB
%token ANIM
%token <integer> INTEGER
%token <str> STRING
%token <str> SYM
%token PATH GLOB
%token POSITION
%token MOVE
%token SHOW HIDE NOP COUNT SOUND
%token ERROR

%type <integer> number location
%type <intpair> numberpair
%type <intlist> intlist intlistitem
%type <cmd>     cmdlist cmdlistitem
%type <intpair> limbanimflags flaglist flag flagvalue

%%

srcfile: /* empty */
| costume
;

// the palette declaration is requiered and must be
// first.
costume: palette costflags statementlist
;

statementlist: ';'
| statement ';'
| statementlist statement ';'
;

statement: dec
| picture
| anim
;

dec: picturedec
{
  cur_pic = NULL;
}
| limbdec
{
  cur_limb = NULL;
}
| animdec
{
  cur_anim = NULL;
}
;

picture: picturedec '=' '{' picparamlist '}'
{
  // check that the pic have an image
  if(!cur_pic->path)
    COST_ABORT(@1,"Picture %s has no path defined.\n",
               cur_pic->name);
  
  if(cur_pic->is_glob) {
    glob_t gl;
    int n,nlen = strlen(cur_pic->name);
    char name[nlen+16];
    cost_pic_t* p;
    
    // expand the glob
    if(glob(cur_pic->path,0,NULL,&gl))
      COST_ABORT(@1,"Glob pattern error: %s\n",cur_pic->path);
    if(!gl.gl_pathc)
      COST_ABORT(@1,"Glob pattern didn't match anything: %s\n",cur_pic->path);
    
    // detach the current pic from the list
    if(pic_list == cur_pic)
      pic_list = cur_pic->next;
    else {
      for(p = pic_list ; p && p->next != cur_pic ; p = p->next);
      if(!p) COST_ABORT(@1,"Internal error: failed to find current pic in pic list.\n");
      p->next = cur_pic->next;
    }
    cur_pic->next = NULL;
    
    // create the new pictures
    for(n = 0 ; n < gl.gl_pathc ; n++) {
      sprintf(name,"%s%02d",cur_pic->name,n);
      p = find_pic(name);
      if(p) {
        if(p->path)
          COST_ABORT(@1,"Glob expansion failed: %s is already defined\n",name);
      } else {
        p = calloc(1,sizeof(cost_pic_t));
        p->name = strdup(name);
      }
      // load it up
      p->path = strdup(gl.gl_pathv[n]);
      if(!cost_pic_load(p,p->path))
        COST_ABORT(@1,"Failed to load %s.\n",p->path);
      // copy the position, etc
      p->rel_x = cur_pic->rel_x;
      p->rel_y = cur_pic->rel_y;
      p->move_x = cur_pic->move_x;
      p->move_y = cur_pic->move_y;
      
      // append it to the list
      p->next = pic_list;
      pic_list = p;
    }
    
    // free the cur_pic
    free(cur_pic->name);
    free(cur_pic->path);
    free(cur_pic);
    globfree(&gl);
  } else {  
    // load it up
    if(!cost_pic_load(cur_pic,cur_pic->path))
      COST_ABORT(@1,"Failed to load %s.\n",cur_pic->path);
  }

  cur_pic = NULL;
}
;

picturedec: PICTURE SYM
{
  cost_pic_t* p = find_pic($2);

  // alloc the pic
  if(!p) {
    p = calloc(1,sizeof(cost_pic_t));
    p->name = $2;
    p->next = pic_list;
    pic_list = p;
  } else
    free($2);
  // set it as the current pic
  cur_pic = p;
}
;

picparamlist: picparam
| picparamlist ',' picparam
;

picparam: PATH '=' STRING
{
  if(cur_pic->path)
    COST_ABORT(@1,"This picture already has a path defined.\n");

  if(img_path)
    asprintf(&cur_pic->path,"%s/%s",img_path,$3);
  else
    cur_pic->path = $3;
}
| GLOB '=' STRING
{
  if(cur_pic->path)
    COST_ABORT(@1,"This picture already has a path defined.\n");

  if(cur_pic->ref)
    COST_ABORT(@1,"This picture has already been referenced, we can't expand it to a glob anymore.\n");

  if(img_path)
    asprintf(&cur_pic->path,"%s/%s",img_path,$3);
  else
    cur_pic->path = $3;
  cur_pic->is_glob = 1;
}
| POSITION '=' numberpair
{
  cur_pic->rel_x = $3[0];
  cur_pic->rel_y = $3[1];
}
| MOVE '=' numberpair
{
  cur_pic->move_x = $3[0];
  cur_pic->move_y = $3[1];
}
;

limbdec: LIMB SYM location
{
  int n;

  if($3 >= 0) {
    // valid index ??
    if($3 >= COST_MAX_LIMBS)
      COST_ABORT(@3,"Limb index %d is invalid. Costumes can only have up to %d limbs.\n",
                 $3,COST_MAX_LIMBS);
    n = $3;
    // name mismatch ???
    if(limbs[n].name && strcmp(limbs[n].name,$2))
       COST_ABORT(@3,"Limb %d is already defined with the name %s.\n",
                  n,limbs[n].name);
  } else {
    // look if there a limb with that name
    for(n = 0 ; n < COST_MAX_LIMBS ; n++) {
      if(!limbs[n].name) continue;
      if(!strcmp(limbs[n].name,$2)) break;
    }
    // no limb with that name then look for a free index
    if(n == COST_MAX_LIMBS) {
      for(n = 0 ; n < COST_MAX_LIMBS ; n++)
        if(!limbs[n].name) break;
      if(n == COST_MAX_LIMBS)
        COST_ABORT(@1,"Too many limbs defined. Costumes can only have up to %d limbs.\n",
                   COST_MAX_LIMBS);
    }
  }

  // alloc it
  if(!limbs[n].name)
    limbs[n].name = strdup($2);
}
;

anim: animdec '=' '{' animdirlist '}'
{
  cur_anim = NULL;
}
;

animdec: ANIM SYM location
{
  int n;

  if($3 >= 0) {
    // valid index ??
    if($3 >= COST_MAX_ANIMS)
      COST_ABORT(@3,"Anim index %d is invalid. Costumes can only have up to %d anims.\n",
                 $3,COST_MAX_ANIMS);
    n = $3;
    // name mismatch ???
    if(anims[n].name && strcmp(anims[n].name,$2))
       COST_ABORT(@3,"Anim %d is already defined with the name %s.\n",
                  n,anims[n].name);
  } else {
    // look if there a anim with that name
    for(n = 0 ; n < COST_MAX_ANIMS ; n++) {
      if(!anims[n].name) continue;
      if(!strcmp(anims[n].name,$2)) break;
    }
    // no anim with that name then look for a free index
    if(n == COST_MAX_ANIMS) {
      // look if it's a predefined name
      for(n = 0 ; anim_map[n].name ; n++)
        if(!strcmp(anim_map[n].name,$2)) break;

      if(anim_map[n].name) n = anim_map[n].id;
      else {
        for(n = ANIM_USER_START ; n < COST_MAX_ANIMS ; n++)
          if(!anims[n].name) break;
        if(n == COST_MAX_ANIMS)
          COST_ABORT(@1,"Too many anims defined. Costumes can only have up to %d anims.\n",
                     COST_MAX_ANIMS);
      }
    }
  }

  // alloc it
  if(!anims[n].name)
    anims[n].name = strdup($2);

  cur_anim = &anims[n];

}
;

animdirlist: animdir ';'
| animdirlist animdir ';'
;

animdir: animdirname '=' '{' limbanimlist  '}'
;

animdirname: SYM
{
  int n;
  for(n = 0 ; dir_map[n].name ; n++)
    if(!strcmp(dir_map[n].name,$1)) break;

  if(!dir_map[n].name)
    COST_ABORT(@1,"Bad direction name.\n");

  cur_dir = cur_anim->dir+dir_map[n].id;
}
;

limbanimlist: limbanim
| limbanimlist ',' limbanim
;

limbanim: SYM '(' cmdlist ')' limbanimflags
{
  int n;
  // find the limb
  for(n = 0 ; n < COST_MAX_LIMBS ; n++)
    if(limbs[n].name && !strcmp(limbs[n].name,$1)) break;
  if(n == COST_MAX_LIMBS)
    COST_ABORT(@1,"There is no limb named %s.\n",$1);

  if(cur_dir->limb_mask & (1 << n))
    COST_ABORT(@1,"Anim for limb %s is already defined.\n",
               limbs[n].name);

  cur_dir->limb_mask |= (1 << n);
  cur_dir->limb[n].flags |=  $5[0];
  cur_dir->limb[n].flags &= ~$5[1];
  cur_dir->limb[n].cmd_list = $3;
}
| SYM '(' ')' limbanimflags
{
  int n;
  // find the limb
  for(n = 0 ; n < COST_MAX_LIMBS ; n++)
    if(limbs[n].name && !strcmp(limbs[n].name,$1)) break;
  if(n == COST_MAX_LIMBS)
    COST_ABORT(@1,"There is no limb named %s.\n",$1);

  if(cur_dir->limb_mask & (1 << n))
    COST_ABORT(@1,"Anim for limb %s is already defined.\n",
               limbs[n].name);
  cur_dir->limb_mask |= (1 << n);
  cur_dir->limb[n].flags |=  $4[0];
  cur_dir->limb[n].flags &= ~$4[1];
}
;

cmdlist: cmdlistitem
| cmdlist ',' cmdlistitem
{
  cost_cmd_t* cmd = $1;
  while(cmd->next) cmd = cmd->next;
  cmd->next = $3;
  $$ = $1;
}
;

cmdlistitem: SYM
{
  cost_pic_t* p = find_pic($1);

  if(!p)
    COST_ABORT(@1,"There is no picture named %s.\n",$1);

  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_DISPLAY;
  $$->arg[0].pic = p;
  p->ref++;
}
| SHOW
{
  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_SHOW;
}
| HIDE
{
  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_HIDE;
}
| NOP
{
  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_NOP;
}
| COUNT
{
  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_COUNT;
}
| SOUND '(' INTEGER ')'
{
  if($3 < 1 || $3 > 8)
    COST_ABORT(@3,"Invalid costume sound index: %d.\n",$3);

  $$ = calloc(1,sizeof(cost_cmd_t));
  $$->type = COST_CMD_SOUND;
  $$->arg[0].i = $3;
}
;

palette: PALETTE '(' intlist ')' ';'
{
  if($3[0] != 16 &&
     $3[0] != 32)
    COST_ABORT(@1,"Invalid palette size. Must be 16 or 32.\n");
  pal_size = $3[0];
  memcpy(pal,$3+1,pal_size);
  free($3);
}
;

intlist: intlistitem
| intlist ',' intlistitem
{
  int l = $1[0] + $3[0];

  $$ = realloc($1,l+1);
  memcpy($$+$$[0]+1,$3+1,$3[0]);
  $$[0] = l;
  free($3);
}
;

intlistitem: INTEGER
{
  if($1 < 0 || $1 > 255)
    COST_ABORT(@1,"List items can't be greater than 255.\n");

  $$ = malloc(2);
  $$[0] = 1;
  $$[1] = $1;
}
| '[' INTEGER '-' INTEGER ']'
{
  int i,s,l = $4-$2+1;

  if($2 < 0 || $2 > 255)
    COST_ABORT(@2,"List items can't be greater than 255.\n");
  if($4 < 0 || $4 > 255)
    COST_ABORT(@4,"List items can't be greater than 255.\n");

  if($4 >= $2)
    l = $4-$2+1, s = 1;
  else
    l = $2-$4+1, s = -1;
    
  $$ = malloc(l+1);
  $$[0] = l;
  for(i = 0 ; i < l ; i++)
    $$[i+1] = $2+s*i;
}
;

costflags: /* empty */
| FLAGS '=' flaglist ';'
{
  cost_flags |=  $3[0];
  cost_flags &= ~$3[1];
}
;

limbanimflags: /* empty */
{
  $$[0] = 0;
  $$[1] = 0;
}
| flaglist
;

flaglist: flag
| flaglist ',' flag
{
  $$[0] |= $3[0];
  $$[1] |= $3[1];
}
;

flag: flagvalue
{
  $$[0] = $1[0];
  $$[1] = $1[1];
}
| '!' flagvalue
{
  $$[0] = $2[1];
  $$[1] = $2[0];
}
;

flagvalue: FLIP
{
  $$[0] = 0;
  $$[1] = 0x80;
}
| LOOP
{
  $$[0] = 0;
  $$[1] = 0x80;
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

location: /* empty */
{
  $$ = -1;
}
| '@' INTEGER
{
  $$ = $2;
}
;

%%

/*
	static scc_lex_t* cost_lex;
	extern int cost_main_lexer(YYSTYPE *lvalp, YYLTYPE *llocp,scc_lex_t* lex);

	static void set_start_pos(YYLTYPE *llocp,int line,int column) {
	  llocp->first_line = line+1;
	  llocp->first_column = column;
	}

	static void set_end_pos(YYLTYPE *llocp,int line,int column) {
	  llocp->last_line = line+1;
	  llocp->last_column = column;
	}

	int yylex(void) {
	  return scc_lex_lex(&yylval,&yylloc,cost_lex);
	}
*/

