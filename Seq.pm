package Seq;

use strict;

use Strc;
our @ISA = ( 'Strc' );
use Token;

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{SEQ} = [];
  bless ($self, $class);
}

# --- setter-getter-ek

sub seq {
  shift->_sg_objectlist( shift, 'SEQ', 'seq', 'Token' );
}

sub add_seq_elem {
  shift->_sg_add_objectlistelem( shift, 'SEQ', 'add_seq_elem', 'Token' );
}

sub len {
  scalar @{ shift->seq };
}

sub as_string {
  my $self = shift;
  ( join ' ', map {$_->marked_form} @{ $self->seq } );
}

# 2006.09.28. nem egészen az eredetit adja
# 2 azonos msd-bõl pl. 1 lesz
# "értelmezett" cqp -nak nevezem, mert nem tudom pontosan, hogy mi :)
sub as_string_cqp {
  my $self = shift;
  ( join ' ', map {$_->marked_form . '/' . $_->lemma . '/' . $_->msd->as_string} @{ $self->seq } );
}

sub as_string_with_msd {
  my $self = shift;
  ( join ' ', map {$_->marked_form . '/' . $_->msd->as_string} @{ $self->seq } );
}

sub as_string_with_msd_info {
  my $self = shift;
  ( join ' ', map {$_->marked_form . '/' . $_->msd->info . "\n"} @{ $self->seq } );
}

sub info {
  my $self = shift;
  my $info = $self->SUPER::info .
  "\n SEQ=[" .
  ( join ' ', map {$_->info} @{ $self->seq } ) .
  ']';
}

# --- egyebek: a lényeg

# param: HNC vertical formájú (soronként 1 szó) <s>-en belüli txt szöveg
sub load {
  my $self = shift;
  # plain string
  my $ps = shift;
  # plain token
  my @pt = split /\n/, $ps;
  foreach my $pt ( @pt ) {
    my $t = Token->new;
    my $st = $t->load( $pt );
    if ( Exception::isExc( $st ) ) { warn $st; } # XXX
    $t->position( scalar @{ $self->seq } );
    $self->add_seq_elem( $t );
      # itt sose lesz az, hogy ne Token lenne,
      # ezért nem törõdök az add_seq_elem status-ával.
  }
}

1;

