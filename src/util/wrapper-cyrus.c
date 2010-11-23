#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef WWWUID
# define WWWUID 33
#endif
#ifndef CYRUSNAME
# define CYRUSNAME "cyrus"
#endif

#ifndef PERL
# define PERL "/usr/bin/perl"
#endif

#ifndef CYRQUOTAAPP
# define CYRQUOTAAPP "/usr/libexec/schulkonsole/bin/cyrquota.pl"
#endif


const uid_t c_www_user = WWWUID;
const char* c_cyrus_name = CYRUSNAME;


const char* c_perl = PERL;


const char *script[] = {
	CYRQUOTAAPP
};
const int c_max_script_id = 0;



/* extern char **environ; */


int
main()
{
	uid_t uid;
	uid_t euid;
	struct passwd *cyrus_passwd;

	int script_id;


	uid = getuid();

	if (uid != c_www_user) {
		return -3;
	}

	/* clear environment */
	clearenv();
	/* environ = NULL; */

	cyrus_passwd = getpwnam(c_cyrus_name);
	if (! cyrus_passwd) {
		return -7;
	}
	
	euid = geteuid();
	if (cyrus_passwd->pw_uid != euid) {
		return -8;
	}


	scanf("%d", &script_id);

	if (script_id >= 0 && script_id <= c_max_script_id) {
		execl(c_perl, c_perl, script[script_id], NULL);

		return -6;
	} else {
		return -5;
	}
}
