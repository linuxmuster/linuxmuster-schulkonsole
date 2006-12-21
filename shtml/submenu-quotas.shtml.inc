<!--#if expr="$link_quotas" -->
	<a class="separator" href="quotas"><gettext>Start</gettext></a>
<!--#endif -->
<!--#if expr="$quotaactivated" -->
<!--#if expr="$link_quotas_teachers" -->
	<a href="quotas_teachers"><gettext>Lehrer</gettext></a>
<!--#endif -->
<!--#if expr="$link_quotas_classes" -->
	<a href="quotas_classes"><gettext>Klassen</gettext></a>
<!--#endif -->
<!--#if expr="$link_quotas_projects" -->
	<a href="quotas_projects"><gettext>Projekte</gettext></a>
<!--#endif -->
<!--#if expr="$link_quotas_others" -->
	<a class="end" href="quotas_others"><gettext>Sonderquota</gettext></a>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_quotas_teachers" -->
	<span class="disabled"><gettext>Lehrer</gettext></span>
<!--#endif -->
<!--#if expr="$link_quotas_classes" -->
	<span class="disabled"><gettext>Klassen</gettext></span>
<!--#endif -->
<!--#if expr="$link_quotas_projects" -->
	<span class="disabled"><gettext>Projekte</gettext></span>
<!--#endif -->
<!--#if expr="$link_quotas_others" -->
	<span class="disabledend"><gettext>Sonderquota</gettext></span>
<!--#endif -->
<!--#endif -->

<img src="img/bw.jpg" alt="Baden-W&uuml;rttemberg - Ministerium f&uuml;r Kultur-, Jugend und Sport">
