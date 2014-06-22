package Prima::Cairo::Drawable;
use strict;
use warnings;
use Prima qw(Cairo);
use vars qw(@ISA);
@ISA = qw(Prima::Drawable);


sub profile_default
{
	my $def = $_[ 0]-> SUPER::profile_default;
	my %prf = (
		surface          => undef,
		alpha            => 1,
		resolution       => [ 300, 300 ], # cairo's default
		useDeviceFonts   => 'match',
	);
	@$def{keys %prf} = values %prf;
	return $def;
}

sub init
{
	my $self = shift;
	$self->{resolution} = [300,300];
	my %profile = $self-> SUPER::init(@_);
	$self-> $_( $profile{$_}) for qw( surface alpha useDeviceFonts );
	$self-> $_( @{ $profile{$_} } ) for qw(resolution);
	return %profile;
}

sub save_state
{
	my $self = $_[0];
	
	$self-> {save_state} = {};
	$self-> {save_state}-> {$_} = $self-> $_() for qw( 
		color backColor fillPattern lineEnd linePattern lineWidth
		rop rop2 textOpaque textOutBaseline font lineJoin fillWinding
		alpha
	);
	delete $self->{save_state}->{font}->{size};
	$self-> {save_state}-> {$_} = [$self-> $_()] for qw( 
		translate clipRect
	);
}

sub restore_state
{
	my $self = $_[0];
	for ( qw( color backColor fillPattern lineEnd linePattern lineWidth
		rop rop2 textOpaque textOutBaseline font lineJoin fillWinding
		alpha
	)) {
		$self-> $_( $self-> {save_state}-> {$_});     
	}      
	for ( qw( translate clipRect)) {
		$self-> $_( @{$self-> {save_tate}-> {$_}});
	}      
}

sub surface
{
	return exists($_[0]->{save_state}->{surface}) ? $_[0]->{save_state}->{surface} : $_[0]->{surface} unless $#_;

	my ( $self, $surface ) = @_;
	return if $self->get_paint_state != ps::Disabled;
	if ( $self->{surface} = $surface ) {
		$self->{context} = Cairo::Context->create($surface); 
		my @extents = $self->{context}->clip_extents;
		my $matrix = Cairo::Matrix->init(
			1, 0, 
			0, -1, 
			0, $extents[3],
		);
		$self->{context}->transform($matrix);
		$self->{surface_width}  = $extents[2];
		$self->{surface_height} = $extents[3];
	} else {
		$self->{context} = undef;
		$self->{surface_width}  = undef;
		$self->{surface_height} = undef;
	}
}

sub new_page
{
	my $self = shift;
	return if $self->get_paint_state == ps::Disabled;
	$self->context->show_page;
	$self->{pages}++;
}

sub pages { shift->{pages} }

sub resolution
{
	return @{$_[0]->{resolution}} unless $#_;
	my ( $self, $x, $y ) = @_;
	return if $self->get_paint_state != ps::Disabled;
	$self->{resolution} = [ $x, $y ];
}

sub context { $_[0]->{context} }

sub alpha
{
	return $_[0]->{alpha} unless $#_;

	my ( $self, $alpha ) = @_;
	$alpha = 0 if $alpha < 0;
	$alpha = 1 if $alpha > 1;
	$self->{alpha} = $alpha;
	$self->{changed}->{fill} = 1 if $self->{can_draw};
}

sub useDeviceFonts
{
	# XXX and fonts etc
	return $_[0]->{useDeviceFonts} unless $#_;
	my ( $self, $udf ) = @_;
	die "useDeviceFonts: none, match, only" unless $udf =~ /(none|match|only)$/;
	$self->{useDeviceFonts} = $udf;
}

sub _begin_doc
{
	my $self = shift;
	$self->{translate} = [0,0];
	$self->{pages} = 0;
	$self->{changed} = {};
}

sub begin_paint
{
	my $self = shift;
	return unless $self->get_paint_state == ps::Disabled;
	return unless $self->context;
	$self->save_state;
	$self->_begin_doc;
	$self->surface->set_fallback_resolution($self->resolution);
	my $ok = $self->SUPER::begin_paint;
	return $ok unless $ok;
	$self->{can_draw}  = 1;
	$self->{current} = {}
	$self->$_( $self->{save_state}->{$_} ) for qw( 
		color backColor fillPattern lineEnd linePattern lineWidth
		rop rop2 textOpaque textOutBaseline font lineJoin fillWinding
		alpha
	);		
	return $ok;
}

sub begin_paint_info
{
	my $self = shift;
	return unless $self->get_paint_state == ps::Disabled;
	return unless $self->context;
	$self->save_state;
	$self->{save_state}->{surface} = $self->{surface};
	my @size = ($self->{surface_width}, $self->{surface_height}); 
	$self->_begin_doc;
	my $ok = $self->SUPER::begin_paint_info;
	return unless $ok;

	$self->surface( Cairo::RecordingSurface-> create( { x => 0, y => 0, width => $size[0], height => $size[1] }));
	$self->surface->set_fallback_resolution($self->resolution);
}

sub end_paint_info
{
	my $self = shift;
	return unless $self->get_paint_state == ps::Information;
	$self->surface( delete $self->{save_state}->{surface} );
	$self->restore_state;
	delete $self->{changed};
	return $self->SUPER::end_paint_info;
}

sub end_paint
{
	my $self = shift;
	return unless $self->get_paint_state == ps::Enabled;
	delete $self->{can_draw};
	delete $self->{changed};
	delete $self->{current};
	$self->restore_state;
	return $self->SUPER::end_paint_info;
}

sub translate
{
	return if $_[0]->get_paint_state == ps::Disabled;
	return @{ $_[0]->{translate} } unless $#_;
	my ( $self, $x, $y ) = @_;
	my ($cx, $cy) = @{ $self->{translate} } ;
	$self->context->translate($x - $cx, $y - $cy);
	@{ $self->{translate} } = ( $x, $y );
}

sub rotate
{
	return if $_[0]->get_paint_state == ps::Disabled;
	return @{ $_[0]->{rotate} } unless $#_;
	my ( $self, $x, $y ) = @_;
	my ($cx, $cy) = @{ $self->{rotate} } ;
	$self->context->rotate($x - $cx, $y - $cy);
	@{ $self->{rotate} } = ( $x, $y );
}

sub scale
{
	return if $_[0]->get_paint_state == ps::Disabled;
	return @{ $_[0]->{scale} } unless $#_;
	my ( $self, $x, $y ) = @_;
	my ($cx, $cy) = @{ $self->{scale} } ;
	$self->context->scale($x - $cx, $y - $cy);
	@{ $self->{scale} } = ( $x, $y );
}

sub clipRect
{
	return if $_[0]->get_paint_state == ps::Disabled;
	if ( $#_ ) {
		my ( $self, $x1, $y1, $x2, $y2 ) = @_;
		my $cr = $self->context;
		$cr->reset_clip;
		$cr->new_path;
		$cr->rectangle($x1, $y1, $x2, $y2);
		$cr->clip;
	} else {
		return shift->context->clip_extents;
	}
}	    


sub rectangle
{
	my ($self, $x1, $y1, $x2, $y2) = @_;
	my $cr = $self->context;
	$cr->rectangle($x1, $y1, $x2 - $x1 + 1, $y2 - $y1 + 1 );
	$cr->stroke;
}

sub bar
{
	my ($self, $x1, $y1, $x2, $y2) = @_;
	my $cr = $self->context;
	$cr->rectangle($x1, $y1, $x2 - $x1 + 1, $y2 - $y1 + 1 );
	$cr->fill;
}

sub line
{
	my ($self, $x1, $y1, $x2, $y2) = @_;
	my $cr = $self->context;
	$cr->new_path;
	$cr->move_to($x1,$y1);
	$cr->line_to($x2,$y2);
	$cr->stroke;
}

eval <<PROP for qw(color backColor fillPattern);
sub $_
{
	return \$_[0]-> SUPER::$_ unless \$#_;
	\$_[0]-> SUPER::$_(\$_[1]);
	return unless \$_[0]->{can_draw};
	\$_[0]->{changed}->{fill} = 1;
}
PROP

eval <<RASTER for qw(rop rop2);
sub $_
{
	return \$_[0]-> SUPER::$_ unless \$#_;
	my (\$self,\$rop) = \@_;
	\$rop = rop::Copy if \$rop != rop::Whiteness && \$rop != rop::Blackness && \$rop != rop::NoOper;
	my \$old = \$self->SUPER::$_;
	return if \$old == \$rop;
	\$self-> SUPER::$_(\$rop);
	return unless \$self->{can_draw};
	\$self->{changed}->{fill} = 1;
}
RASTER

sub _fill
{
	my $self = shift;
	return unless $self->{can_draw};

	if ( $self->{changed}->{fill}) {
		my ($fc, $bc) = ($self->color, $self->backColor);
		my ( $rop, $rop2 ) = ( $self->rop, $self->rop2 );
		$fc = 0x000000 if $rop  == rop::Blackness;
		$fc = 0xFFFFFF if $rop  == rop::Whiteness;
		$bc = 0x000000 if $rop2 == rop::Blackness;
		$bc = 0xFFFFFF if $rop2 == rop::Whiteness;

		my @fp  = @{$self-> SUPER::fillPattern};
		my $solid_back = ! grep { $_ != 0 } @fp;
		my $solid_fore = ! grep { $_ != 0xff } @fp;
		if (
			($solid_fore && $rop  == rop::NoOper) ||
			($solid_back && $rop2 == rop::NoOper) ||
			($rop == rop::NoOper && $rop2 == rop::NoOper)
		) {
			$self->{current}->{can_paint} = 0;
			goto EXIT_FILL;
		}

		if ( $solid_fore || $solid_back ) {
			my $color = $solid_fore ? $fc : $bc;
			$self->set_source_rgba(
				int((($color & 0xff0000) >> 16) * 100 / 256 + 0.5) / 100, 
				int((($color & 0xff00) >> 8) * 100 / 256 + 0.5) / 100, 
				int(($color & 0xff)*100/256 + 0.5) / 100);
				$self->alpha );
		} else {
		}
		$self->{current}->{can_paint} = 1;
	EXIT_FILL:		
		$self->{changed}->{fill} = 0;
	}
}	

1;
