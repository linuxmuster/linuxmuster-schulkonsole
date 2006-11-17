#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef WWWUID
# define WWWUID 33
#endif
#ifndef MINUID
# define MINUID 10000
#endif

#ifndef PERL
# define PERL "/usr/bin/perl"
#endif

#ifndef QUOTAAPP
# define QUOTAAPP "/usr/libexec/schulkonsole/bin/quota.pl"
#endif


const uid_t c_www_user = WWWUID;
const uid_t c_min_user = MINUID;


const char* c_perl = PERL;


const char *script[] = {
	QUOTAAPP
};
const int c_max_script_id = 0;



/* extern char **environ; */


int
main()
{
	uid_t uid;

	uid_t user_id;
	int script_id;


	uid = getuid();

	if (uid != c_www_user) {
		return -3;
	}

	/* clear environment */
	clearenv();
	/* environ = NULL; */


	scanf("%d", &user_id);
	if (user_id < c_min_user) {
		return -4;
	}
	if (setreuid(user_id, user_id) != 0) {
		return -7;
	}


	scanf("%d", &script_id);

	if (script_id >= 0 && script_id <= c_max_script_id) {
		execl(c_perl, c_perl, script[script_id], NULL);

		return -6;
	} else {
		return -5;
	}
}
