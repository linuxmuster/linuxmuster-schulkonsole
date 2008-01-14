<!--#if expr="$link_room" -->
	<a class="separator" href="room"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$edit" -->
<!--#if expr="$link_room_shares" -->
	<a href="room_shares"><gettext>Tauschen</gettext></a>
<!--#endif -->
<!--#if expr="$exammode" -->
<!--#if expr="$link_room_handout" -->
	<span class="disabled"><gettext>Austeilen</gettext></span>
<!--#endif -->
<!--#if expr="$link_room_collect" -->
	<span class="disabledseparator"><gettext>Einsammeln</gettext></span>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_room_handout" -->
	<a href="room_handout"><gettext>Austeilen</gettext></a>
<!--#endif -->
<!--#if expr="$link_room_collect" -->
	<a class="separator" href="room_collect"><gettext>Einsammeln</gettext></a>
<!--#endif -->
<!--#endif -->
<!--#if expr="$link_room_test" -->
	
<!--#if expr="$done_test_password" -->
	<a class="end" href="room_test_collect">
<!--#else -->
<!--#if expr="$done_test_handout" -->
	<a class="end" href="room_test_password">
<!--#else -->
<!--#if expr="$done_test_start" -->
	<a class="end" href="room_test_handout">
<!--#else -->
	<a class="end" href="room_test">
<!--#endif -->
<!--#endif -->
<!--#endif -->
	<gettext>Klassenarbeit</gettext></a>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_room_shares" -->
	<span class="disabled"><gettext>Tauschen</gettext></a></span>
<!--#endif -->
<!--#if expr="$link_room_handout" -->
	<span class="disabled"><gettext>Austeilen</gettext></span>
<!--#endif -->
<!--#if expr="$link_room_collect" -->
	<span class="disabledseparator"><gettext>Einsammeln</gettext></span>
<!--#endif -->
<!--#if expr="$link_room_test" -->
	<span class="disabledend"><gettext>Klassenarbeit</gettext></span>
<!--#endif -->
<!--#endif -->

<img src="img/bw.jpg" alt="Baden-W&uuml;rttemberg - Ministerium f&uuml;r Kultur-, Jugend und Sport">
