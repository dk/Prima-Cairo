#! /usr/bin/perl
use strict;
use warnings;

use Test::More;

use Prima::noX11;
use Prima qw(Cairo);

plan tests => 2;

my $original = Prima::Image->create(
	width    => 2,
	height   => 2,
	type     => im::bpp24,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	lineSize => 6,
);

my $surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo surface ok');

my $image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima image ok");
