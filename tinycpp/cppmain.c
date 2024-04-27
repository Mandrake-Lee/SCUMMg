#include "preproc.h"
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

static int usage(char *a0) {
	fprintf(stderr,
			"example preprocessor\n"
			"usage: %s [-I includedir...] [-D define] file\n"
			"if no filename or '-' is passed, stdin is used.\n"
			, a0);
	return 1;
}

int main(int argc, char** argv) {
	int c; char* tmp;
	struct cpp* cpp = cpp_new();
	while ((c = getopt(argc, argv, "D:I:")) != EOF) switch(c) {
	case 'I': cpp_add_includedir(cpp, optarg); break;
	case 'D':
		if((tmp = strchr(optarg, '='))) *tmp = ' ';
		cpp_add_define(cpp, optarg);
		break;
	default: return usage(argv[0]);
	}
	char *fn = "stdin";
	char launchpath[PATH_MAX], *basepath;
	FILE *in = stdin;
	if(argv[optind] && strcmp(argv[optind], "-")) {
		fn = argv[optind];
		in = fopen(fn, "r");
		if(!in) {
			perror("fopen");
			return 1;
		}
	}

	/* Store where we kick the compiler */
	getcwd(launchpath, PATH_MAX);
	printf("Current directory:\t%s\n", launchpath);
	basepath = realpath(fn,NULL);
	printf("Processing file:\t%s\n", basepath);
	basepath = cpp_detect_includedir(basepath);
	printf("Including directory:\t%s\n", basepath);
	cpp_add_includedir(cpp, basepath);
	chdir(basepath);
	
	int ret = cpp_run(cpp, in, stdout, fn);
	cpp_free(cpp);
	if(in != stdin) fclose(in);
	
	/* Come back to starting directory */
	chdir(launchpath);
	
	return !ret;
}

