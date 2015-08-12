
<div id="status"[% IF is_error == 0 %] class="ok"[% END %]>
<div></div>
[% IF status %]
<p>[% status %]</p>
[% END %]
[% IF REMOTE_ADDR %]
<p class="info">
<gettext>Sitzungsdauer:</gettext> [% session_time %]<br>
<gettext>verbleibend:</gettext> <span id="timer">[% max_idle_hh_mm_ss %]</span></p>
<p class="info"><gettext>Benutzer:</gettext>
<strong>[% firstname %] [% surname %]</strong><br>
<gettext>Raum:</gettext>
[% IF remote_room %]
<strong>[% remote_room %]</strong><br>
[% ELSE %]
<strong><gettext>unbekannt</gettext></strong><br>
[% END %]
<gettext>Workstation:</gettext>
<strong>[% remote_workstation %]</strong><br>
<gettext>IP:</gettext> <strong>[% REMOTE_ADDR %]</strong><br>
[% IF class %]
<p class="info"><gettext>aktive Klasse:</gettext>
<strong>[% class %]</strong></p>
[% END %]
[% END %]
</div>
