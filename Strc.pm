package Strc;

use strict;

use Object;
our @ISA = ( 'Object' );
use Msd;
use Type; # 2006.03.07. e nélkül hogy bírt mûködni eddig? XXX
use Position;
use Exception;

# --- konstr
sub new {
  my $class = shift;
  my $self = {};
  $self->{FORM}     = '';            # repr: string
  $self->{CAPIT}    = '';            # repr: string (nagybetûs) e {yes,no}
  $self->{LEMMA}    = '';            # repr: string
  $self->{MSD}      = Msd->new;      # repr: Msd osztály
  $self->{TYPE}     = Type->new;     # repr: Type osztály
  $self->{POSITION} = Position->new; # repr: Position osztály
  $self->{CODE}     = '';            # repr: 1 (!) karakter
  $self->{MARKED}   = '';            # repr: boolean '' vagy 1
  
  bless $self, $class;
}

# --- setter-getter-ek
sub form {     shift->_sg( shift, 'FORM' ); }
sub capit {    shift->_sg( shift, 'CAPIT' ); }
sub lemma {    shift->_sg( shift, 'LEMMA' ); }
sub msd {
  my $self = shift;
  my $status = '';
  if ( @_) {
    $status = $self->{MSD}->parse( shift );
  }
  Exception::isExc( $status ) ? $status : $self->{MSD};
}
sub type {
  my $self = shift;
  if ( @_ ) { $self->{TYPE}->parse( shift ); }
  # nincs hibakezelés, mivel Type::parse -ben sincs XXX
  $self->{TYPE};
}
sub position {
  my $self = shift;
  if ( @_ ) { $self->{POSITION}->parse( @_ ); }
  # nincs hibakezelés, mivel Position::parse -ben sincs XXX
  $self->{POSITION};
}
sub code {     shift->_sg( shift, 'CODE' ); }
sub marked {   shift->_sg( shift, 'MARKED' ); }
sub marked_form {
  my $self = shift;
  $self->marked ? '<' . $self->form . '>' : $self->form;
}

sub as_string {
  my $self = shift;
                  $self->form .
  '/' .           $self->lemma .
  '/' .           $self->msd->as_string;
}

sub as_full_string {
  my $self = shift;
  $self->as_string .
  '-[' . $self->position->as_string . ']';
}

sub info {
  my $self = shift;
  $self->type->as_string .     "\t" .
  $self->position->as_string . "\t" .
  $self->code .                "\t" .
                  $self->form .
  '/' .           $self->lemma .
  '/' .           $self->msd->as_string;
}

# --- egyebek: a lényeg

# param: 'form TAB lemma TAB msd' formájú txt token
sub load {
  my $self = shift;
  # plain string
  my $ps = shift;
  my @pa = split /\t/, $ps;
  $self->form( $pa[0] );
  $self->lemma( $pa[1] );
  $self->msd( $pa[2] );
  $self->capit( ( $pa[0] =~ /^[A-ZÁÉÍÓÖÕÚÜÛ]/ ) ? 'yes' : 'no' );
}

1;

