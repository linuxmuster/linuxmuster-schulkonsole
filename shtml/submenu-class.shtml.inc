<ul>
<!--#if expr="$link_class" -->
	<li><a href="class"><gettext>Start</gettext></a></li>
<!--#endif -->
<!--#if expr="$class" -->
<!--#if expr="$link_class_list" -->
	<li><a href="class_list"><gettext>Klassenliste</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_passwords" -->
	<li><a href="class_passwords"><gettext>Passw&ouml;rter</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_handoutcopy" -->
	<li><a href="class_handoutcopy"><gettext>Austeilen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_handout" -->
	<li><a href="class_handout"><gettext>Bereitstellen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_collect" -->
	<li><a href="class_collect"><gettext>Einsammeln</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_db" -->
	<li><a href="class_db"><gettext>Datenbanken</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_revision_control" -->
	<li><a href="class_revision_control"><gettext>Versionskontrolle</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_www" -->
	<li><a href="class_www"><gettext>Webfreigabe</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_class_shares" -->
	<li><a href="class_shares"><gettext>Tauschen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<li><a href="room_test"><gettext>Klassenarbeit</gettext></a></li>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_class_list" -->
	<li class="disabled"><gettext>Klassenliste</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_passwords" -->
	<li class="disabled"><gettext>Passw&ouml;rter</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_handoutcopy" -->
	<li class="disabled"><gettext>Austeilen</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_handout" -->
	<li class="disabled"><gettext>Bereitstellen</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_collect" -->
	<li class="disabled"><gettext>Einsammeln</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_db" -->
	<li class="disabled"><gettext>Datenbanken</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_revision_control" -->
	<li class="disabled"><gettext>Versionskontrolle</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_www" -->
	<li class="disabled"><gettext>Webfreigabe</gettext></li>
<!--#endif -->
<!--#if expr="$link_class_shares" -->
	<li class="disabled"><gettext>Tauschen</gettext></li>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<li class="disabled"><gettext>Klassenarbeit</gettext></li>
<!--#endif -->
<!--#endif -->
</ul>
