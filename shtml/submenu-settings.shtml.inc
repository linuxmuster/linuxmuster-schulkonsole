<!--#if expr="$link_settings" -->
	<a class="separator" href="settings"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$link_settings_program" -->
	<a href="settings_program"><gettext>Schulkonsole</gettext></a>
<!--#endif -->
<!--#if expr="$link_settings_users" -->
	<a href="settings_users"><gettext>Benutzerverwaltung</gettext></a>
<!--#endif -->
<!--#if expr="$link_settings_classs" -->
	<a href="settings_classs"><gettext>Klassen</gettext></a>
<!--#endif -->
<!--#if expr="$link_settings_backup" -->
	<a class="end" href="settings_backup"><gettext>Backup</gettext></a>
<!--#endif -->

<!--#include file="footer_submenu.shtml.inc" -->
