package Position;

use strict;

use Object;
our @ISA = ( 'Object' );

# --- konstr
sub new {
  my $class = shift;
  my $self = {};
  $self->{BEGPOS} = '';
  $self->{ENDPOS} = '';
  bless $self, $class;
}

# --- setter-getter-ek
sub begpos { shift->_sg( shift, 'BEGPOS' ); }
sub endpos { shift->_sg( shift, 'ENDPOS' ); }

# param: poz�ci� VAGY kezd�- �s v�gpoz�ci� - ez az igazi setter (!)
# XXX hibakezel�s nincs - kell?
sub parse {
  my $self = shift;
  if ( @_ < 2 ) { # egy param�ter
    if ( $_[0] =~ m/^([0-9]+)-([0-9]+)$/ ) {
      $self->begpos ( $1 );
      $self->endpos ( $2 );
    } else {
      $self->begpos ( $_[0] );
      $self->endpos ( $_[0] );
    }
  } else {
    $self->begpos ( shift );
    $self->endpos ( shift );
  }
  $self;
}

# "pontszer�"-e a poz�ci�
sub single {
  my $self = shift;
  ( $self->begpos =~ m/[0-9]+/ ) &&
  ( $self->begpos == $self-> endpos );
}

# hossz
sub len {
  my $self = shift;
  return $self->endpos - $self->begpos + 1;
}

sub as_string {
  my $self = shift;
  my $b = $self->begpos;
  my $e = $self->endpos;
  ( $self->_isinteger( $b ) && $self->_isinteger( $e) && $b < $e )
    ? "$b-$e"
    : $b;
}

sub info {
  shift->as_string();
}

# --- egyebek: a l�nyeg
# sub xxx {
# }

1;

