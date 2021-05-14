package Sentence;

use strict;

use PlainSentence;
our @ISA = ( 'PlainSentence' );

# --- konstansok
my $DEBUG = '';

# csak a match m�k�d�s�ben m�s, mint a PlainSentence, ti.
# be�gyazott strukt�r�kat is kezel, nem csak egyszint�t

# --- egyebek: a l�nyeg

# param: egy alkalmazand� szab�ly
# m�k�d: command alapj�n sz�tosztja a k�r�st a megfelel� elj�r�shoz
sub apply {
  my $self = shift;
  my $rule = shift;

  if ( $rule->command eq $Rule::MATCH ) {
    $self->match( $rule );
  } else { # XXX egyel�re, ha nem MATCH, akkor DELETE
    $self->delete( $rule );
  }
}

# param: egy alkalmazand� delete-szab�ly
# m�k�d: t�rli a szab�lyban megadott annot�ci�t
sub delete {
  my $self = shift;
  my $rule = shift;
  my $type = $rule->type;
  $self->strcs->delete( $type );
}

# param: egy alkalmazand� match-szab�ly
# m�k�d: karakteres regexp-k�dol�ssal, regexp-illeszt�ssel
#        megkeresi, �s strc-ben t�rolja az illeszked� szerkezeteket
sub match {
  my $self = shift;
  my $rule = shift;

  $self->_regexp_code( $rule );
  my ( $coded_sent, $poslistref ) = $self->_regexp_match( $rule );
  $self->_regexp_store( $rule, $coded_sent, $poslistref );
  # XXX postlistref j� esetben nem fog kelleni
}

# param: egy alkalmazand� szab�ly
# m�k�d: szab�ly termjeinek �s a mondat illeszked�
#        szerkezeteinek / tokenjeinek k�dol�sa
sub _regexp_code {
  my $self = shift;
  my $rule = shift;

  $rule->autocode;
  #print "\n *** A bek�dolt szab�ly:\n";
  #print $rule->info . "\n";

  #print "\n *** Az illeszked�sek k�dokkal:\n";
  # bek�dolok minden tokent/szerkezetet
  my @arr = ( @{ $self->seq }, @{ $self->strcs->as_array } );
  foreach my $w ( @arr ) {
    foreach my $t ( @{ $rule->seq } ) {
      if ( $w->satisfies( $t ) ) {
        $w->code( $t->code ); # ennyi a k�dol�s
        print $w->info . " - ok�!\n" if $DEBUG;
        last;
        # XXX az els� megtal�ltn�l kil�p�nk, azaz az �tk�z�s nincs kezelve
      } else {
        $w->code( '-' ); # ennyi a k�dol�s XXX hc
        print $w->info . " - nem j�.\n" if $DEBUG;
      }
    }
  }
}

# param: egy alkalmazand� szab�ly
# m�k�d: regex-k�sz�t�s �s match-el�s
sub _regexp_match {
  my $self = shift;
  my $rule = shift;

  my $coded_sent = '';
  my @poslist = @{ $self->strcs->coverage };
print 'poslist:' .
  ( join ' ', map { ref $_ ? $_->info : $_ } @poslist ) . "\n" if $DEBUG;
  # XXX ez azonos a Annotation::as_string -b�li k�ddal

  if ( $self->len == $self->strcs->len ) {
    # XXX ez kicsit gyagya, de helyes
    # ellen�rz�se annak, hogy m�r vannak-e strukt�r�k
    foreach my $t ( @poslist ) {
      if ( ref( $t ) eq 'Token' ) { # XXX isa?
        $coded_sent .= $t->code;
      } else { # ha nem Token, akkor ugye egy sz�-index
        $coded_sent .= ${ $self->seq }[$t]->code;
      }
    }
  } else {
    for ( my $i = 0; $i < $self->len; ++$i ) {
      $coded_sent .= ${ $self->seq }[$i]->code;
      push @poslist, $i; # "default" poslist: index-sorozat egyes�vel
    }
  }

  my $coded_rule;
  foreach my $t ( @{ $rule->seq } ) {
    $coded_rule .= $t->pre . $t->code . $t->post;
  }

  print "\n *** A k�dolt mondat:\n" . $coded_sent . "\n" if $DEBUG;
  print "\n *** A k�dolt szab�ly:\n" . $coded_rule . "\n" if $DEBUG;

  # itt t�rt�nik meg minden ...
  $coded_sent =~ s/($coded_rule)/$self->LM . $1 . $self->RM/ge;

  print "\n *** A felismert szerkezetek (k�dolt alak):\n" .
    $coded_sent . "\n\n" if $DEBUG;

  ( $coded_sent, \@poslist ); # XXX XXX XXX na ez m�r t�nyleg sz�rny�
}

# param: egy alkalmazand� szab�ly
#        _regexp_match eredm�nyek�nt kij�tt k�dolt mondat
# m�k�d: regexp-pel k�dolt mondat visszaalak�t�sa
#        �s a tal�latok feljegyz�se a mondat strukt�r�i (strc) k�z�
sub _regexp_store {
  my $self = shift;
  my $rule = shift;
  my $coded_sent = shift;
  my $poslistref = shift; # XXX
  my @poslist = @{ $poslistref }; # XXX

  my $i = 0;
  my $beg;
  my $end;
# XXX legjobb lefed�s alapj�n kell visszaalak�tani
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
        : $poslist[$i]; # XXX tot�l nem �rtem, hogy itt mi�rt nincs -1 a v�g�n,
                        #     ha egyszer a poslist-ben a _kezdetek_ vannak
      my $s = Token->new;

      # fej-perkol�ci�: elvileg mindig a szerkezet
      # utols� (mindig j� ez? XXX) szav�nak msd-je j�n �t
      $s->form( ${ $self->seq }[$end]->form );
      $s->lemma( ${ $self->seq }[$end]->lemma );
      $s->msd->copy( ${ $self->seq }[$end]->msd );
      # mindig Msd -> hibakezel�s nem kell
      $s->type->copy( $rule->type );
      $s->position( $beg, $end );
      # 2008.04.15. capit attrib�tumot vajh mi�rt nem m�soljuk? XXX

      $self->add_strcs_elem( $s ); # mindig Token -> hibakezel�s nem kell
    }
    ++$i;
  }
}

1;

