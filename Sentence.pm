package Sentence;

use strict;

use PlainSentence;
our @ISA = ( 'PlainSentence' );

# --- konstansok
my $DEBUG = '';

# csak a match mûködésében más, mint a PlainSentence, ti.
# beágyazott struktúrákat is kezel, nem csak egyszintût

# --- egyebek: a lényeg

# param: egy alkalmazandó szabály
# mûköd: command alapján szétosztja a kérést a megfelelõ eljáráshoz
sub apply {
  my $self = shift;
  my $rule = shift;

  if ( $rule->command eq $Rule::MATCH ) {
    $self->match( $rule );
  } else { # XXX egyelõre, ha nem MATCH, akkor DELETE
    $self->delete( $rule );
  }
}

# param: egy alkalmazandó delete-szabály
# mûköd: törli a szabályban megadott annotációt
sub delete {
  my $self = shift;
  my $rule = shift;
  my $type = $rule->type;
  $self->strcs->delete( $type );
}

# param: egy alkalmazandó match-szabály
# mûköd: karakteres regexp-kódolással, regexp-illesztéssel
#        megkeresi, és strc-ben tárolja az illeszkedõ szerkezeteket
sub match {
  my $self = shift;
  my $rule = shift;

  $self->_regexp_code( $rule );
  my ( $coded_sent, $poslistref ) = $self->_regexp_match( $rule );
  $self->_regexp_store( $rule, $coded_sent, $poslistref );
  # XXX postlistref jó esetben nem fog kelleni
}

# param: egy alkalmazandó szabály
# mûköd: szabály termjeinek és a mondat illeszkedõ
#        szerkezeteinek / tokenjeinek kódolása
sub _regexp_code {
  my $self = shift;
  my $rule = shift;

  $rule->autocode;
  #print "\n *** A bekódolt szabály:\n";
  #print $rule->info . "\n";

  #print "\n *** Az illeszkedések kódokkal:\n";
  # bekódolok minden tokent/szerkezetet
  my @arr = ( @{ $self->seq }, @{ $self->strcs->as_array } );
  foreach my $w ( @arr ) {
    foreach my $t ( @{ $rule->seq } ) {
      if ( $w->satisfies( $t ) ) {
        $w->code( $t->code ); # ennyi a kódolás
        print $w->info . " - oké!\n" if $DEBUG;
        last;
        # XXX az elsõ megtaláltnál kilépünk, azaz az ütközés nincs kezelve
      } else {
        $w->code( '-' ); # ennyi a kódolás XXX hc
        print $w->info . " - nem jó.\n" if $DEBUG;
      }
    }
  }
}

# param: egy alkalmazandó szabály
# mûköd: regex-készítés és match-elés
sub _regexp_match {
  my $self = shift;
  my $rule = shift;

  my $coded_sent = '';
  my @poslist = @{ $self->strcs->coverage };
print 'poslist:' .
  ( join ' ', map { ref $_ ? $_->info : $_ } @poslist ) . "\n" if $DEBUG;
  # XXX ez azonos a Annotation::as_string -béli kóddal

  if ( $self->len == $self->strcs->len ) {
    # XXX ez kicsit gyagya, de helyes
    # ellenõrzése annak, hogy már vannak-e struktúrák
    foreach my $t ( @poslist ) {
      if ( ref( $t ) eq 'Token' ) { # XXX isa?
        $coded_sent .= $t->code;
      } else { # ha nem Token, akkor ugye egy szó-index
        $coded_sent .= ${ $self->seq }[$t]->code;
      }
    }
  } else {
    for ( my $i = 0; $i < $self->len; ++$i ) {
      $coded_sent .= ${ $self->seq }[$i]->code;
      push @poslist, $i; # "default" poslist: index-sorozat egyesével
    }
  }

  my $coded_rule;
  foreach my $t ( @{ $rule->seq } ) {
    $coded_rule .= $t->pre . $t->code . $t->post;
  }

  print "\n *** A kódolt mondat:\n" . $coded_sent . "\n" if $DEBUG;
  print "\n *** A kódolt szabály:\n" . $coded_rule . "\n" if $DEBUG;

  # itt történik meg minden ...
  $coded_sent =~ s/($coded_rule)/$self->LM . $1 . $self->RM/ge;

  print "\n *** A felismert szerkezetek (kódolt alak):\n" .
    $coded_sent . "\n\n" if $DEBUG;

  ( $coded_sent, \@poslist ); # XXX XXX XXX na ez már tényleg szörnyû
}

# param: egy alkalmazandó szabály
#        _regexp_match eredményeként kijött kódolt mondat
# mûköd: regexp-pel kódolt mondat visszaalakítása
#        és a találatok feljegyzése a mondat struktúrái (strc) közé
sub _regexp_store {
  my $self = shift;
  my $rule = shift;
  my $coded_sent = shift;
  my $poslistref = shift; # XXX
  my @poslist = @{ $poslistref }; # XXX

  my $i = 0;
  my $beg;
  my $end;
# XXX legjobb lefedés alapján kell visszaalakítani
  foreach my $ch ( split //, $coded_sent ) {
    if ( $ch eq $self->LM ) {
      $beg = ref( $poslist[$i] ) eq 'Token'
        ? $poslist[$i]->position->begpos
        : $poslist[$i];
      --$i;
    } elsif ( $ch eq $self->RM ) {
      --$i;
      $end = ref( $poslist[$i] ) eq 'Token'
        ? $poslist[$i]->position->endpos
        : $poslist[$i]; # XXX totál nem értem, hogy itt miért nincs -1 a végén,
                        #     ha egyszer a poslist-ben a _kezdetek_ vannak
      my $s = Token->new;

      # fej-perkoláció: elvileg mindig a szerkezet
      # utolsó (mindig jó ez? XXX) szavának msd-je jön át
      $s->form( ${ $self->seq }[$end]->form );
      $s->lemma( ${ $self->seq }[$end]->lemma );
      $s->msd->copy( ${ $self->seq }[$end]->msd );
      # mindig Msd -> hibakezelés nem kell
      $s->type->copy( $rule->type );
      $s->position( $beg, $end );
      # 2008.04.15. capit attribútumot vajh miért nem másoljuk? XXX

      $self->add_strcs_elem( $s ); # mindig Token -> hibakezelés nem kell
    }
    ++$i;
  }
}

1;

