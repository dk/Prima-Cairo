use strict;
use warnings;
use Prima qw(Application Lists Cairo);

my $font;
if ( @ARGV ) {
	$font = $ARGV[0];
} else {
	for ( @{$::application->fonts} ) {
		next unless $_->{name} =~ /emoji/i;
		$font = $_->{name};
		last;
	}
	warn "You don't seem to have an emoji font\n" unless $font;
}

my @glyphs;
$::application->begin_paint_info;
$::application->font->name($font);
my $ranges = $::application-> get_font_ranges;
for ( my $i = 0; $i < @$ranges; $i += 2 ) {
	push @glyphs, $ranges->[$i] .. $ranges->[$i+1];
}
$::application->end_paint_info;

my $w = Prima::MainWindow->new(
	text => 'Emojis',
	packPropagate => 0,
);

my $ih = $w->font->height * 4;
my $cr;
$w->insert( AbstractListViewer => 
	pack => { fill => 'both', expand => 1 },
	multiColumn => 1,
	itemWidth   => $ih,
	itemHeight  => $ih,
	hScroll     => 1,
	vScroll     => 1,
	drawGrid    => 0,
	onPaint     => sub {
		my ( $self, $canvas ) = @_;
		$self->clear;
                $cr = $canvas->cairo_context( transform => 0 );
		$cr->select_font_face($font,normal=>'normal') if defined $font;
		$cr->set_font_size($w->font->size * 4);
		$self->on_paint($canvas);
		undef $cr;
	},
	onDrawItem  => sub {
		my ( $self, $canvas, $index, $x1, $y1, $x2, $y2, $selected, $focused, $prelight ) = @_;
		my @cs;
		if ( $focused || $prelight) {
			@cs = ( $canvas-> color, $canvas-> backColor);
			my $fo = $focused ? $canvas-> hiliteColor : $canvas-> color ;
			my $bk = $focused ? $canvas-> hiliteBackColor : $canvas-> backColor ;
			$canvas-> set( color => $fo, backColor => $bk );

		}
		$self-> draw_item_background( $canvas, $x1, $y1, $x2, $y2, $prelight );
		my $k = $cr->text_extents( chr($glyphs[$index]));
		$cr->move_to(
			$x1 + ( $x2 - $x1 - $k->{width}) / 2 - $k->{x_bearing}, 
			$self->height - $y1 - ($y2 - $y1 - ($k->{height}))/2 - $k->{height} - $k->{y_bearing}
		);
		$cr->show_text( chr($glyphs[$index]));
		my $tx = sprintf("%x", $glyphs[$index] );
		$canvas-> text_out( $tx, $x1 + ( $x2 - $x1 - $canvas->get_text_width($tx)) / 2, $y1);
		$canvas-> set( color => $cs[0], backColor => $cs[1]) if $focused || $prelight;
	},
)->count(scalar @glyphs);

run Prima;
