/*
 * Copyright © 2019 rofl0r.
 *
 * MIT license as per COPYING file
 * 
 * Tweaks to work with SCUMMg by Jorge Amorós-Argos
 */

#ifndef PREPROC_H
#define PREPROC_H

#include <stdio.h>

#define SCUMM_COMMENT_LIT ";"
#define MULTILINE_COMMENT_START_LIT "/*"
#define MULTILINE_COMMENT_END_LIT "*/"
#define SCUMM_DEFINE_LIT "define"
#define SCUMM_INCLUDE_LIT "include"
#define ERROR_LIT "#error"
#define WARNING_LIT "#warning"
#define UNDEF_LIT "#undef"
#define IF_LIT "#if"
#define ELIF_LIT "#elif"
#define ELSE_LIT "#else"
#define IFDEF_LIT "#ifdef"
#define IFNDEF_LIT "#ifndef"
#define ENDIF_LIT "#endif"
#define LINE_LIT "#line"
#define PRAGMA_LIT "#pragma"

#define PATH_DELIMITER_WIN "\\"
#define PATH_DELIMITER_LINUX "/"
#define PATH_MAX 4096

struct cpp;

struct cpp *cpp_new(void);
void cpp_free(struct cpp*);
void cpp_add_includedir(struct cpp *cpp, const char* includedir);
const char* cpp_detect_includedir(const char* include_decl);
int cpp_add_define(struct cpp *cpp, const char *mdecl);
int cpp_run(struct cpp *cpp, FILE* in, FILE* out, const char* inname);

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wunknown-pragmas"
#endif
#pragma RcB2 DEP "preproc.c"

#endif

