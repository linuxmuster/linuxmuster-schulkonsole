<div id="status">
<h2><gettext>Status</gettext></h2>
<p><!--#echo var="status" --></p>
<!--#if expr="$REMOTE_ADDR" -->
<p class="info"><gettext>Sie sind:</gettext>
<strong><!--#echo var="firstname" --> <!--#echo var="surname" --></strong><br>
<gettext>in Raum:</gettext>
<!--#if expr="$remote_room" -->
<strong><!--#echo var="remote_room" --></strong><br>
<!--#else -->
<strong><gettext>unbekannt</gettext></strong><br>
<!--#endif -->
<gettext>an Platz:</gettext>
<strong><!--#echo var="remote_workstation" --></strong><br>
<gettext>mit IP:</gettext> <strong><!--#echo var="REMOTE_ADDR" --></strong><br>
<gettext>Sitzungsdauer:</gettext> <!--#echo var="session_time" --><br>
<gettext>verbleibend:</gettext> <span id="timer"><gettext>unbekannt</gettext></span></p>
<!--#if expr="$class" -->
<p class="info"><gettext>aktive Klasse:</gettext>
<strong><!--#echo var="class" --></strong></p>
<!--#endif -->
<!--#endif -->
</div>
