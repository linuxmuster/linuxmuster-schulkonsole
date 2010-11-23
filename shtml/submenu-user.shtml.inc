<!--#if expr="$link_user" -->
	<a class="separator" href="user"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_students" -->
	<a href="user_students"><gettext>Sch&uuml;lerliste pflegen</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_teachers" -->
	<a href="user_teachers"><gettext>Lehrerliste pflegen</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_extra" -->
	<a class="separator" href="user_extra"><gettext>Extralisten pflegen</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_check" -->
	<a href="user_check"><gettext>Benutzerlisten pr&uuml;fen</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_commit" -->
	<a class="tworowseparator" href="user_commit"><gettext>Benutzerdaten &uuml;bernehmen</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_teacherpasswords" -->
	<a href="user_teacherpasswords"><gettext>Lehrerpassw&ouml;rter</gettext></a>
<!--#endif -->
<!--#if expr="$link_user_reports" -->
	<a class="end" href="user_reports"><gettext>Berichte</gettext></a>
<!--#endif -->

<!--#include file="footer_submenu.shtml.inc" -->
