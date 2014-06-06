# $Id$
package MY;
use strict;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use Config;
use Prima::Config;

my @obj  = ('Cairo.o');

my %cairo_cfg = ExtUtils::PkgConfig->find ("cairo >= 1.0.0");

WriteMakefile(
	NAME               => 'Prima::Cairo',
	VERSION_FROM       => 'lib/Prima/Cairo.pm',
	MIN_PERL_VERSION   => '5.008',
	PREREQ_PM          => {
		'Prima'		          => 1.38,
		'Cairo'	              => 1.104,
	},
	CONFIGURE_REQUIRES => {
    	'ExtUtils::Depends'   => 0.2,
	    'ExtUtils::PkgConfig' => 1.0,
		'Prima'		          => 1.38,
	},
	ABSTRACT_FROM      => 'lib/Prima/Cairo.pm',
	AUTHOR             => 'Dmitry Karasik <dmitry@karasik.eu.org>',
	LIBS               => "$Prima::Config::Config{libs} $cairo_cfg{libs}",
	DEFINE             => "$Prima::Config::Config{define} $cairo_cfg{cflags}",
	INC                => "$Prima::Config::Config{inc} -Iinclude",
	OBJECT             => "@obj",
);
