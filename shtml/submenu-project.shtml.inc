<ul>
<!--#if expr="$link_project" -->
	<li><a href="project"><gettext>Start</gettext></a></li>
<!--#endif -->
<!--#if expr="$project" -->
<!--#if expr="$link_project_members" -->
	<li><a href="project_members"><gettext>Mitglieder</gettext></a></li>
<!--#endif -->
<!--#if expr="$isadmin" -->
<!--#if expr="$link_project_handoutcopy" -->
	<li><a href="project_handoutcopy"><gettext>Austeilen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<li><a href="project_handout"><gettext>Bereitstellen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<li><a href="project_collect"><gettext>Einsammeln</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<li><a href="project_db"><gettext>Datenbanken</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<li><a href="project_revision_control"><gettext>Versionskontrolle</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<li><a href="project_www"><gettext>Webfreigabe</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<li><a href="project_shares"><gettext>Tauschen</gettext></a></li>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_project_handoutcopy" -->
	<li class="disabled"><gettext>Austeilen</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<li class="disabled"><gettext>Bereitstellen</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<li class="disabled"><gettext>Einsammeln</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<li class="disabled"><gettext>Datenbanken</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<li class="disabled"><gettext>Versionskontrolle</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<li class="disabled"><gettext>Webfreigabe</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<li class="disabled"><gettext>Tauschen</gettext></li>
<!--#endif -->
<!--#endif -->
<!--#else -->
<!--#if expr="$link_project_members" -->
	<li class="disabled"><gettext>Mitglieder</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_addmembers" -->
	<li class="disabled"><gettext>Mitglieder hinzuf&uuml;gen</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_handoutcopy" -->
	<li class="disabled"><gettext>Austeilen</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_handout" -->
	<li class="disabled"><gettext>Bereitstellen</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_collect" -->
	<li class="disabled"><gettext>Einsammeln</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_db" -->
	<li class="disabled"><gettext>Datenbanken</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_revision_control" -->
	<li class="disabled"><gettext>Versionskontrolle</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_www" -->
	<li class="disabled"><gettext>Webfreigabe</gettext></li>
<!--#endif -->
<!--#if expr="$link_project_shares" -->
	<li class="disabled"><gettext>Tauschen</gettext></li>
<!--#endif -->
<!--#endif -->

</ul>
