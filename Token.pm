package Token;

use strict;

use Strc;
our @ISA = ( 'Strc' );

# --- egyebek: a lényeg
# param: egy Term
# retur: hogy ez a Token kielégíti-e a Term-et
#  ez egy tipikus proxy eljárás :)
sub satisfies {
  my $self = shift;
  my $term = shift;
  ( $term->isa( 'Term' ) )
    ? $self->_satisfies( $term )
    : "$Exception::msg Token::satisfies requires a Term to satisfy.";
}

sub _satisfies {
  my $self = shift;
  my $term = shift;
  my $ok = 1;

#print
#  "\n[" . $term->comp . '] ' .
#  $term->info . ' ' .
#  $self->as_string . ' ' .
#  $term->position->as_string . ' =? ' .
#  $self->position->as_string . ' ';

  # a típusnak mindenképp stimmelnie kell, nem lehet tagadni (!) XXX
  if ( not $self->type->satisfies( $term->type ) ) {
    return '';
  }

  if ( $term->comp eq '=' ) { # hc XXX

     if ( $term->form  and $self->form  ne $term->form )  { $ok = ''; }
  elsif ( $term->capit and $self->capit ne $term->capit ) { $ok = ''; }
  elsif ( $term->lemma and $self->lemma ne $term->lemma ) { $ok = ''; }
  elsif ( not $self->msd->satisfies( $term->msd ) )       { $ok = ''; }
  elsif ( $term->position->begpos ne '' and
    $self->position->begpos ne $term->position->begpos )  { $ok = ''; }
    # XXX ez a Position::satisfies-be való

  } elsif ( $term->comp eq '!' ) { # hc XXX

     if ( $term->form  and $self->form  eq $term->form )  { $ok = ''; }
  elsif ( $term->capit and $self->capit eq $term->capit ) { $ok = ''; }
  elsif ( $term->lemma and $self->lemma eq $term->lemma ) { $ok = ''; }
  elsif ( $term->msd->ok and
    $self->msd->satisfies( $term->msd ) )                 { $ok = ''; }
  elsif ( $term->position->begpos ne '' and
    $self->position->begpos eq $term->position->begpos )  { $ok = ''; }
    # XXX ez a Position::satisfies-be való

  } elsif ( $term->comp eq '~' ) { # hc XXX
  # XXX XXX XXX CSAK ezekre megy: form, lemma
  # XXX XXX XXX a többire '='-ként viselkedik

    my $tf = $term->form;
    my $tl = $term->lemma;
     if ( $term->form  and ( $self->form  !~ m/$tf/ ) )   { $ok = ''; }
  elsif ( $term->capit and $self->capit ne $term->capit ) { $ok = ''; }
  elsif ( $term->lemma and ( $self->lemma !~ m/$tl/ ) )   { $ok = ''; }
  elsif ( not $self->msd->satisfies( $term->msd ) )       { $ok = ''; }
  elsif ( $term->position->begpos ne '' and
    $self->position->begpos ne $term->position->begpos )  { $ok = ''; }
    # XXX ez a Position::satisfies-be való
  }

  $ok;
}

1;

