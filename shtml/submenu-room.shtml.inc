<ul>
<!--#if expr="$link_room" -->
	<li><a href="room"><gettext>Start</gettext></a></li>
<!--#endif -->
</ul>
<!--#if expr="$edit" -->
<ul>
<!--#if expr="$link_room_shares" -->
	<li><a href="room_shares"><gettext>Tauschen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_screen2teacher" -->
	<li><a href="room_screen2teacher"><gettext>Sch&uuml;lerbildschirm auf Lehrer-PC</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_screen2student" -->
	<li><a href="room_screen2student"><gettext>Lehrerbildschirm auf Sch&uuml;ler-PC</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_handout" -->
	<li><a href="room_handout"><gettext>Austeilen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_collect" -->
	<li><a href="room_collect"><gettext>Einsammeln</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<li>
<!--#if expr="$done_test_password" -->
	<a href="room_test_collect">
<!--#else -->
<!--#if expr="$done_test_handout" -->
	<a href="room_test_password">
<!--#else -->
<!--#if expr="$done_test_start" -->
	<a href="room_test_handout">
<!--#else -->
	<a href="room_test">
<!--#endif -->
<!--#endif -->
<!--#endif -->
	<gettext>Klassenarbeit</gettext></a></li>
<!--#endif -->
</ul>
<!--#else -->
<ul>
<!--#if expr="$link_room_shares" -->
	<li class="disabled"><gettext>Tauschen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_room_screen2teacher" -->
	<li class="disabled"><gettext>Sch&uuml;lerbildschirm auf Lehrer-PC</gettext></li>
<!--#endif -->
<!--#if expr="$link_room_screen2student" -->
	<li class="disabled"><gettext>Lehrerbildschirm auf Sch&uuml;ler-PC</gettext></li>
<!--#endif -->
<!--#if expr="$link_room_handout" -->
	<li class="disabled"><gettext>Austeilen</gettext></li>
<!--#endif -->
<!--#if expr="$link_room_collect" -->
	<li class="disabled"><gettext>Einsammeln</gettext></li>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<li class="disabled"><gettext>Klassenarbeit</gettext></li>
<!--#endif -->
</ul>
<!--#endif -->
