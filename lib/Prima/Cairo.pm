package Prima::Cairo;
use strict;
use Prima;
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

1;
