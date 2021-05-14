package Type;

use strict;

use Object;
our @ISA = ( 'Object' );

# --- konstansok
our $DEFAULT_TYPE = 'w';
our $TYPESEP = ':';

# --- konstr
sub new {
  my $class = shift;
  my $self = []; # t�pus, alt�pus, alalt�pus, ...
  push ( @{ $self }, $DEFAULT_TYPE );
  bless $self, $class;
}

# --- konstans getter-ek
sub DEFAULT_TYPE { shift; return $DEFAULT_TYPE; }
sub TYPESEP { shift; return $TYPESEP; }

# --- setter-getter-ek
# param: stringben a t�pus
sub parse {
  my $self = shift;
  my $s = shift;
  @{ $self } = split /$TYPESEP/, $s;
  $self;
}

sub copy {
  my $self = shift;
  my $t = shift;
  if ( $t->isa( 'Type' ) ) {
    @{ $self } = @{ $t };
    $self;  
  } else {
    "$Exception::msg " . ref( $self ) .
    "::copy requires a " . ref( $self) . ".";
  }
}

sub as_string {
  my $self = shift;
  join $TYPESEP, @{ $self };
}

sub info {
  my $self = shift;
  join $TYPESEP, @{ $self };
}

# --- egyebek: a l�nyeg
# param: egy Type
# retur: hogy a param�ter Type megfelel-e jelen Type-nak
#        ti. 'NE:ext' megfelel 'NE' -nek
sub satisfies {
  my $self = shift;
  my $type = shift;
  ( $type->isa( 'Type' ) )
    ? $self->_satisfies( $type ) 
    : "$Exception::msg Type::satisfies requires a Type to satisfy.";
}

sub _satisfies {
  my $self = shift;
  my $type = shift;
  my $i = 0;
  # am�g type meg van adva, meg kell n�zni, hogy megfelel�nk-e neki
  # (lukat nem enged�nk meg az alt�pusok sor�ban)
  while ( $i < @{ $type } and
    $self->[$i] and $type->[$i] and
    $self->[$i] eq $type->[$i] ) { ++$i; }
  ( $i == scalar @{ $type } ) or ( $self->[$i] and not $type->[$i] );
  # ok�, ha a $type v�g�re �rt�nk vagy ha $type kevesebbet v�r el
}

1;

