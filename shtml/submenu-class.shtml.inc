<!--#if expr="$link_class" -->
	<a class="separator" href="class"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$class" -->
<!--#if expr="$link_class_list" -->
	<a href="class_list"><gettext>Klassenliste</gettext></a>
<!--#endif -->
<!--#if expr="$link_class_passwords" -->
	<a class="separator" href="class_passwords"><gettext>Passw&ouml;rter</gettext></a>
<!--#endif -->
<!--#if expr="$link_class_handoutcopy" -->
	<a href="class_handoutcopy"><gettext>Austeilen</gettext></a>
<!--#endif -->
<!--#if expr="$link_class_handout" -->
	<a href="class_handout"><gettext>Bereitstellen</gettext></a>
<!--#endif -->
<!--#if expr="$link_class_collect" -->
	<a class="separator" href="class_collect"><gettext>Einsammeln</gettext></a>
<!--#endif -->
<!--#if expr="$link_class_shares" -->
	<a class="separator" href="class_shares"><gettext>Tauschen</gettext></a>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<a class="separator" href="room_test"><gettext>Klassenarbeit</gettext></a>
<!--#endif -->
<!--#if expr="$link_group_lesson" -->
	<a class="end" href="group_lesson"><gettext>Unterricht</gettext></a>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_class_list" -->
	<span class="disabled"><gettext>Klassenliste</gettext></span>
<!--#endif -->
<!--#if expr="$link_class_passwords" -->
	<span class="disabledseparator"><gettext>Passw&ouml;rter</gettext></span>
<!--#endif -->
<!--#if expr="$link_class_handoutcopy" -->
	<span class="disabled"><gettext>Austeilen</gettext></span>
<!--#endif -->
<!--#if expr="$link_class_handout" -->
	<span class="disabled"><gettext>Bereitstellen</gettext></span>
<!--#endif -->
<!--#if expr="$link_class_collect" -->
	<span class="disabledseparator"><gettext>Einsammeln</gettext></span>
<!--#endif -->
<!--#if expr="$link_class_shares" -->
	<span class="disabledseparator"><gettext>Tauschen</gettext></span>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<span class="disabledseparator"><gettext>Klassenarbeit</gettext></span>
<!--#endif -->
<!--#if expr="$link_group_lesson" -->
	<span class="disabledend"><gettext>Unterricht</gettext></span>
<!--#endif -->
<!--#endif -->

<!--#include file="footer_submenu.shtml.inc" -->
