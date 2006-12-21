<!--#if expr="$link_project" -->
	<a class="separator" href="project"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$project" -->
<!--#if expr="$link_project_members" -->
	<a class="separator" href="project_members"><gettext>Mitglieder</gettext></a>
<!--#endif -->
<!--#if expr="$isadmin" -->
<!--#if expr="$link_project_handoutcopy" -->
	<a href="project_handoutcopy"><gettext>Austeilen</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<a href="project_handout"><gettext>Bereitstellen</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<a class="separator" href="project_collect"><gettext>Einsammeln</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<a href="project_db"><gettext>Datenbanken</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<a href="project_revision_control"><gettext>Versionskontrolle</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<a href="project_www"><gettext>Webfreigabe</gettext></a>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<a class="end" href="project_shares"><gettext>Tauschen</gettext></a>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_project_handoutcopy" -->
	<span class="disabled"><gettext>Austeilen</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<span class="disabled"><gettext>Bereitstellen</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<span class="disabled"><gettext>Einsammeln</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<span class="disabled"><gettext>Datenbanken</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<span class="disabled"><gettext>Versionskontrolle</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<span class="disabled"><gettext>Webfreigabe</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<span class="disabled"><gettext>Tauschen</gettext></span>
<!--#endif -->
<!--#endif -->
<!--#else -->
<!--#if expr="$link_project_members" -->
	<span class="disabledseparator"><gettext>Mitglieder</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_handoutcopy" -->
	<span class="disabled"><gettext>Austeilen</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<span class="disabled"><gettext>Bereitstellen</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<span class="disabledseparator"><gettext>Einsammeln</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<span class="disabled"><gettext>Datenbanken</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<span class="disabled"><gettext>Versionskontrolle</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<span class="disabled"><gettext>Webfreigabe</gettext></span>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<span class="disabledend"><gettext>Tauschen</gettext></span>
<!--#endif -->
<!--#endif -->

<img src="img/bw.jpg" alt="Baden-W&uuml;rttemberg - Ministerium f&uuml;r Kultur-, Jugend und Sport">
