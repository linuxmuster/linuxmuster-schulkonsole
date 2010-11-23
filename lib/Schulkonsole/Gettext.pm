use strict;
use Locale::gettext;

package Locale::gettext;





sub domain {
	my $class = shift;
	my $domain = shift;
	my $this = {};

	Locale::gettext::textdomain($domain);

	return bless $this, $class;
}




sub dir {
	my $this = shift;
	my $dir = shift;
}




sub get {
	my $this = shift;
	my $string = shift;

	return Locale::gettext::gettext($string);
}





1;
