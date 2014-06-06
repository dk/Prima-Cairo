package Prima::Cairo;
use strict;
use Prima;
use Cairo;
require Exporter;
require DynaLoader;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);

sub dl_load_flags { 0x01 };

$VERSION = '0.01';
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();

bootstrap Prima::Cairo $VERSION;

package Prima::Cairo::Surface;
use vars qw(@ISA);
our @ISA = qw(Cairo::Surface);

package
	Prima::Drawable;

sub cairo_context
{
	my $surface = Prima::Cairo::surface_create(shift);
	if ( $surface && $surface->status eq 'success') {
        	return Cairo::Context->create ($surface);
	} else {
		return undef;
	}
}

1;
