<div id="status">
<div></div>
<!--#if expr="$REMOTE_ADDR" -->
<p class="info">
<gettext>Sitzungsdauer:</gettext> <!--#echo var="session_time" --><br>
<gettext>verbleibend:</gettext> <span id="timer"><!--#echo var="max_idle_hh_mm_ss" --></span></p>
<p class="info"><gettext>Benutzer:</gettext>
<strong><!--#echo var="firstname" --> <!--#echo var="surname" --></strong><br>
<gettext>Raum:</gettext>
<!--#if expr="$remote_room" -->
<strong><!--#echo var="remote_room" --></strong><br>
<!--#else -->
<strong><gettext>unbekannt</gettext></strong><br>
<!--#endif -->
<gettext>Workstation:</gettext>
<strong><!--#echo var="remote_workstation" --></strong><br>
<gettext>IP:</gettext> <strong><!--#echo var="REMOTE_ADDR" --></strong><br>
<!--#if expr="$class" -->
<p class="info"><gettext>aktive Klasse:</gettext>
<strong><!--#echo var="class" --></strong></p>
<!--#endif -->
<!--#endif -->
</div>
