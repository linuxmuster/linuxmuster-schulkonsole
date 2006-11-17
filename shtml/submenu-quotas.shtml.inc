<ul>
<!--#if expr="$link_quotas" -->
	<li><a href="quotas"><gettext>Start</gettext></a></li>
<!--#endif -->
<!--#if expr="$quotaactivated" -->
<!--#if expr="$link_quotas_teachers" -->
	<li><a href="quotas_teachers"><gettext>Lehrer</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_quotas_classes" -->
	<li><a href="quotas_classes"><gettext>Klassen</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_quotas_projects" -->
	<li><a href="quotas_projects"><gettext>Projekte</gettext></a></li>
<!--#endif -->
<!--#if expr="$link_quotas_others" -->
	<li><a href="quotas_others"><gettext>Sonderquota</gettext></a></li>
<!--#endif -->
<!--#else -->
<!--#if expr="$link_quotas_teachers" -->
	<li class="disabled"><gettext>Lehrer</gettext></li>
<!--#endif -->
<!--#if expr="$link_quotas_classes" -->
	<li class="disabled"><gettext>Klassen</gettext></li>
<!--#endif -->
<!--#if expr="$link_quotas_projects" -->
	<li class="disabled"><gettext>Projekte</gettext></li>
<!--#endif -->
<!--#if expr="$link_quotas_others" -->
	<li class="disabled"><gettext>Sonderquota</gettext></li>
<!--#endif -->
<!--#endif -->
</ul>
