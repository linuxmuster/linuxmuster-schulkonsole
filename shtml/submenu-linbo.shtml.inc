<!--#if expr="$link_linbo" -->
	<a class="separator" href="linbo"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$link_linbo_edit" -->
	<a class="tworow" href="linbo_edit"><gettext>Gruppenkonfiguration editieren</gettext></a></br>
<!--#endif -->
<!--#if expr="$link_linbo_new" -->
	<a class="tworowseparator"  href="linbo_new"><gettext>Gruppenkonfiguration erstellen</gettext></a></br>
<!--#endif -->
<!--#if expr="$link_linbo_regpatchedit" -->
	<a href="linbo_regpatchedit"><gettext>Registrypatch editieren</gettext></a></br>
<!--#endif -->
<!--#if expr="$link_linbo_pxeedit" -->
	<a class="separator" href="linbo_pxeedit"><gettext>PXE-Start</gettext></a></br>
<!--#endif -->
<!--#if expr="$link_linbo_menuedit" -->
        <a class="separator" href="linbo_menuedit"><gettext>menu.lst editieren</gettext></a></br>
<!--#endif -->
<!--#if expr="$link_linbo_images" -->
	<a class="end" href="linbo_images"><gettext>Imageverwaltung</gettext></a></br>
<!--#endif -->

<!--#include file="footer_submenu.shtml.inc" -->
