#! /usr/bin/perl
use strict;
use warnings;

use Test::More;

use Prima::noX11;
use Prima qw(Cairo);

plan tests => 13;

my $original = Prima::Image->create(
	width    => 2,
	height   => 2,
	type     => im::bpp24,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	lineSize => 6,
);

my $surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo rgb24 surface ok');
ok( $surface->get_format eq 'rgb24', 'type is rgb24');

my $image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima bpp24 image ok");

$original = Prima::Image->create(
	width    => 4,
	height   => 2,
	type     => im::Byte,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80",
	lineSize => 4,
);

$surface = Prima::Cairo::to_cairo_surface($original, 'a8');
ok( $surface->status eq 'success', 'cairo a8 surface ok');
ok( $surface->get_format eq 'a8', 'type is a8');

$image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima imByte image ok");

$original = Prima::Image->create(
	width    => 32,
	height   => 2,
	type     => im::BW,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80",
	lineSize => 4,
);

$surface = Prima::Cairo::to_cairo_surface($original, 'a1');
ok( $surface->status eq 'success', 'cairo a1 surface ok');
ok( $surface->get_format eq 'a1', 'type is a1');

$image = $surface->to_prima_image;
ok( $image && $image->data eq $original->data, "prima imBW image ok");

$original = Prima::Icon->create(
	width    => 2,
	height   => 2,
	type     => im::bpp24,
	data     => "\x10\x20\x30\x40\x50\x60\x70\x80\x90\xa0\xb0\xc0",
	mask     => "\xc0\x00\x00\x00\x00\x00\x00\x00",
	lineSize => 6,
);
$surface = $original->to_cairo_surface;
ok( $surface->status eq 'success', 'cairo argb32 surface ok');
ok( $surface->get_format eq 'argb32', 'type is argb32');

$image = $surface->to_prima_image('Prima::Icon');
ok( $image && $image->data eq $original->data, "prima icon data ok");
ok( $image && $image->mask eq $original->mask, "prima icon mask ok");
