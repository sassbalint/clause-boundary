package Term;

use strict;

use Token;
our @ISA = ( 'Token' );

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{PRE} = '';  # repr: string
  $self->{POST} = ''; # repr: string
   # a regexp atomokon kívüli részei: ?*+, zárójelek, vagylagosság
   # tetszõleges Perl regexp-beli dolog megengedett
  $self->{COMP} = ''; # repr: string (összehasonlítási módja) e {=,!}
  bless $self, $class;
}

# --- setter-getter-ek
sub pre {  shift->_sg( shift, 'PRE' ); }
sub post { shift->_sg( shift, 'POST' ); }
sub comp {  shift->_sg( shift, 'COMP' ); }

sub as_string {
  my $self = shift;
  ( $self->pre ? $self->pre : '' ) .
  $self->SUPER::as_string .
  ( $self->post ? $self->post : '' );
}

sub info {
  my $self = shift;
  ( $self->pre ? ( " PRE=" . $self->pre ) : '' ) .
  '{' .
  $self->SUPER::info .
  '}' .
  ( $self->post ? ( " POST=" . $self->post ) : '' ) .
  ( $self->comp ? ( " COMP=" . $self->comp ) : '' );
}

# --- egyebek: a lényeg
# sub xxx {
# }

1;

