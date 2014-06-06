# Port of http://www.playfuljs.com/demos/raycaster/ (c) Hunter Loftis 

use strict;
use warnings;
use POSIX qw(ceil floor);
use Time::HiRes qw(time);
use Prima qw(Application MsgBox Cairo);

my $pi          = atan2(1,0)*2;
my $twopi       = $pi*2;
my ( $x, $y, $direction, $paces ) = (15.3,-1.2,$pi*3,0);
my $weapon      = Cairo::ImageSurface->create_from_png('knife_hand.png');
my $sky         = Prima::Image->load('deathvalley_panorama.jpg')->bitmap;
my $wall        = Prima::Image->load('wall_texture.jpg')->bitmap;
my $size        = 32;
my @grid        = map {(0.3 > rand) ? 1 : 0} 1..$size*$size;
my $light       = 0;
my $fov         = $pi * 0.4;
my $resolution  = 160;
my $range       = 14;
my $light_range = 5;
my $cast_cache;
my $seconds     = 1;
my $draw_rain   = 1;

my ( $width, $height, $spacing, $scale ) ;

sub rotate { 
    $direction = ($direction + $twopi + shift);
    $direction -= $twopi while $direction > $twopi;
    undef $cast_cache;
}

sub walk 
{
    my $distance = shift;
    my $dx = cos($direction) * $distance;
    my $dy = sin($direction) * $distance;
    $x += $dx if inside($x + $dx, $y) <= 0;
    $y += $dy if inside($x, $y + $dy) <= 0;
    $paces += $distance;
    undef $cast_cache;
}

sub inside
{
    my ( $x, $y ) = map { floor($_) } @_;
    return ($x < 0 or $x > $size - 1 or $y < 0 or $y > $size - 1) ? -1 : $grid[ $y * $size + $x ];
}
    
sub cast
{
    my ($x, $y, $angle, $range) = @_;
    my $sin    = sin($angle);
    my $cos    = cos($angle);
    my $sincos = $sin / $cos;
    my $cossin = $cos / $sin;

    my @rays = ({
        x        => $x,
        y        => $y,
        height   => 0,
        distance => 0,
    });

    while (1) {
        my $r = $rays[-1];

        my ( $stepx, $stepy );
        if ( $cos != 0 ) {
            my ( $x, $y ) = ($r->{x}, $r->{y});
            my $dx = ($cos > 0) ? int($x + 1) - $x : ceil($x - 1) - $x;
            my $dy = $dx * $sincos;
            $stepx = {
                x => $x + $dx,
                y => $y + $dy,
                length2 => $dx*$dx + $dy*$dy,
            };
        } else {
            $stepx = { length2 => 0 + 'Inf' };
        }
        
        if ( $sin != 0 ) {
            my ( $x, $y ) = ($r->{y}, $r->{x});
            my $dx = ($sin > 0) ? int($x + 1) - $x : ceil($x - 1) - $x;
            my $dy = $dx * $cossin;
            $stepy = {
                y => $x + $dx,
                x => $y + $dy,
                length2 => $dx*$dx + $dy*$dy,
            };
        } else {
            $stepy = { length2 => 0 + 'Inf' };
        }

        my ( $nextstep, $shiftx, $shifty, $distance, $offset ) = 
            ($stepx->{length2} < $stepy->{length2}) ?
                ($stepx, 1, 0, $r->{distance}, $stepx->{y}) :
                ($stepy, 0, 1, $r->{distance}, $stepy->{x});
        
        my ( $x, $y ) = map { floor($_) } (
            $nextstep->{x} - (( $cos < 0 ) ? $shiftx : 0), 
            $nextstep->{y} - (( $sin < 0 ) ? $shifty : 0)
        );
        $nextstep->{height}   = ($x < 0 or $x > $size - 1 or $y < 0 or $y > $size - 1) ? -1 : $grid[ $y * $size + $x ]; 
        $nextstep->{distance} = $distance + sqrt($nextstep->{length2});
        $nextstep->{shading}  = $shiftx ? ( $cos < 0 ? 2 : 0 ) : ( $sin < 0 ? 2 : 1 );
        $nextstep->{offset}   = $offset - int($offset);
                    
        last if $nextstep->{distance} > $range;
        push @rays, $nextstep;
    }; 
    
    return \@rays;
}

sub update
{
    if ( $light > 0 ) {
        my $l = $light - 10 * $seconds;
        $light = ($l < 0) ? 0 : $l;
    } elsif ( rand() * 5 < $seconds ) {
        $light = 2;
    }
}

sub draw_sky
{
    my ($canvas) = @_;
    my $w = $width * $twopi / $fov;
    my $left = -$w * $direction / $twopi;
    $canvas->stretch_image( $left, 0, $w, $height, $sky );
    $canvas->stretch_image( $left + $w, 0, $w, $height, $sky ) if $left < $w - $width;
    if ($light > 0) {
        my $cr = $canvas->cairo_context;
        $cr->set_source_rgba(1,1,1,$light*0.1);
        $cr->rectangle(0,$canvas->height/2, $canvas->width,$canvas->height/2);
        $cr->fill;
    }
}

sub draw_columns
{
    my $canvas = shift;
    for ( my $column = 0; $column < $resolution; $column++) {
        my $angle = $fov * ( $column / $resolution - 0.5 );
        my $ray   = $cast_cache->[$column] //= cast($x, $y, $direction + $angle, $range);
        draw_column($canvas, $column, $ray, cos($angle));
    }
}

sub draw_column
{
    my ( $canvas, $column, $rays, $cos_angle ) = @_;
    my $left = int( $column * $spacing );
    my $width = ceil( $spacing );
    my $hit = -1;
    do {} while ++$hit < @$rays && $rays->[$hit]->{height} <= 0;
    my @lines;
    my $wall_width  = $wall->width;
    my $wall_height = $wall->height;
    my $cr = $canvas->cairo_context;
    for ( my $s = $#$rays; $s >= 0; $s--) {
        my $step         = $rays->[$s];
        my $rain_drops   = $s * (rand() ** 3);
        my $cos_distance = $cos_angle * $step->{distance};
        my $bottom       = ($rain_drops > 0) ? $height / 2 * (1 + 1 / $cos_distance) : 0;
        my $rain_height  = ($rain_drops > 0) ? 0.1 * $height / $cos_distance         : 0;
        my $rain_top     = $bottom + $rain_height;
        if ( $s == $hit ) {
            my $texturex = int( $wall_width * $step->{offset});
            my $wproj_height = $height * $step->{height} / $cos_distance;
            my $wproj_top   = $bottom + $wproj_height;
            $canvas->put_image_indirect( 
                $wall, $left, 
                $height - $wproj_top + $wproj_height, 
                $texturex, 0, 
                $width, $wproj_height, 
                1, $wall_height, 
                rop::CopyPut
            );
            my $alpha = ($step->{distance} + $step->{shading}) / $light_range - $light;
            $alpha = 0 if $alpha < 0;
            $cr->set_source_rgba(0,0,0,$alpha);
            $cr->rectangle($left, $height - $wproj_top + $wproj_height, $width, $wproj_height);
            $cr->fill;
        }

        
        $cr->set_source_rgba(1,1,1,0.15);
        while ( $draw_rain && --$rain_drops > 0 ) {
            my $top = rand() * $rain_top ;
            $cr->rectangle($left, $height - $top, 1, $rain_height);
            $cr->fill;
        }
    }

}

sub draw_weapon 
{
    my ( $canvas ) = @_;
    my $bobx = cos($paces * 2) * $scale * 6;
    my $boby = sin($paces * 4) * $scale * 6;
    my $left = $width * 0.66 + $bobx;
    my $top  = $height * 0.6 + $boby;
    my $cr = $canvas->cairo_context( transform => 0);
    my $m = Cairo::Matrix->init_identity;
    $m->scale($scale, $scale);
    $cr->transform($m); 
    $cr->set_source_surface($weapon, $left/$scale, $top/$scale);
    $cr->paint;
}


sub set_resolution($)
{
    $spacing *= $resolution;
    $resolution = shift;
    $spacing /= $resolution;
    undef $cast_cache;
}
      

my $last_time = time;
my $w = Prima::MainWindow->new(
    text => 'Cairo raycaster',
    menuItems => [
        [ '~Options' => [
            [ '~Resolution' => [
                [ '40'  => sub { set_resolution 40 } ],
                [ '80'  => sub { set_resolution 80 } ],
                [ '160' => sub { set_resolution 160 } ],
                [ '320' => sub { set_resolution 320 } ],
                [ '640' => sub { set_resolution 640 } ],
            ]],
            ['*rain' => 'R~ain' => sub { $draw_rain = shift->menu->toggle(shift) } ],
        ]],
	[],
	['About' => sub {
		message_box("Raycaster", "Port of http://www.playfuljs.com/demos/raycaster/ by Hunter Loftis", mb::Information);
	}],
    ],

    buffered => 1,
    onSize   => sub {
        my ( $self, $ox, $oy, $x, $y ) = @_;
        $width = $x;
        $height = $y;
        $spacing = $width / $resolution;
        $scale  = ( $width + $height ) / 1200;
    },
    onKeyDown => sub {
        my ( $self, $code, $key, $mod ) = @_;
           if ( $key == kb::Left  ) { rotate(-$pi*$seconds); } 
        elsif ( $key == kb::Right ) { rotate($pi*$seconds);  }
        elsif ( $key == kb::Up    ) { walk(3*$seconds);      } 
        elsif ( $key == kb::Down  ) { walk(-3*$seconds);     }
    },
    onPaint => sub {
        my ( $self, $canvas ) = @_;
        update();
        draw_sky($canvas);
        draw_columns($canvas);
        draw_weapon($canvas);

        my $t = time;
        $canvas->color(cl::White);
        $seconds = $t - $last_time;
        $canvas->text_out(sprintf("%.1d fps", 1/$seconds),0,0);
        $last_time = $t;
    },
);


$w->insert(Timer => 
    onTick => sub { $w->repaint },
    timeout => 200,
)->start;

run Prima;
