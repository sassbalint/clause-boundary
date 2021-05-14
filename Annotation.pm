package Annotation;

use strict;

use Object;
our @ISA = ( 'Object' );

# --- konstr
sub new {
  my $class = shift;
  my $self = []; # egy tömb (!), ami a struktúrákat tároló
                 # tömböket tartalmazza: az i. pozíciónál
                 # kezdõdõ struktúra az i. altömbben van
  bless $self, $class;
}

# megfelelõ méretû legyen
sub init {
  my $self = shift;
  my $size = shift;
  for ( my $i = 0; $i < $size; ++$i ) {
    $self->[$i] = [];
  }
  $self;
}

# --- setter-getter-ek

# param: egy tárolandó Token (=struktúra)
# mûköd: a Token-t a kezdõpozíciója által meghatározott
#        indexû tömbhöz adja hozzá
#        ezt a Token->position->begpos mutatja meg
# XXX logikátlan, hogy a struktúrák Token néven futnak, de egyelõre ez van.
#     azért stimmel egyébként, mert csak egy típus+pozíció struktúra-vázat
#     tárolunk, ami a PlainSentence konkrét Token-jeire hivatkozik.
#     az teszi lehetõvé a logikátlanságot, hogy a Token-beli Position
#     is tárolhat intervallumot - tiltsuk le, vagy mi?
# XXX esetleg lehetne ide a Tokennek egy értelmes leszármazottja
#     mondjuk Head (?) ...
sub add_elem {
  my $self = shift;
  my $tok = shift;

  my $pos = $tok->position->begpos;
  $self->_sg_arr_add_objectlistelem(
    $tok, $self->[$pos], 'add_elem', 'Token' );
}

# hossz
sub len {
  my $self = shift;
  scalar @{ $self };
}

# i. altömb, azaz az adott pozíción kezdõdõ szerkezetek tömbje
sub get {
  my $self = shift;
  my $index = shift;
  ( $index >= 0 and $index < $self->len )
    ? $self->[$index]
    : "$Exception::msg index ($index) out of bounds (0.." .
      ($self->len - 1) . ") in Annotation::get";
}

# i. altömb hossza, azaz az adott pozíción kezdõdõ szerkezetek száma
sub cnt {
  my $self = shift;
  my $index = shift;
  ( $index >= 0 and $index < $self->len )
    ? scalar @{ $self->[$index] }
    : "$Exception::msg index ($index) out of bounds (0.." .
      ($self->len - 1) . ") in Annotation::cnt"; # XXX kódduplikálás (!)
}

sub as_array {
  my $self = shift;
  my @arr = ();
  for ( my $i = 0; $i < $self->len; ++$i ) {
    @arr = ( @arr, @{ $self->get($i) } ); # XXX ez biztos dög lassú
  }
#  foreach my $a ( @{ $self } ) {
#    @arr = ( @arr, @{$a} ); 
#  }
  \@arr;
}

sub as_string {
  my $self = shift;
  ( join ' ', map { ref $_ ? $_->as_string : $_ } @{$self->coverage} );
}

# vö: PlainSentence::strcs_info
sub info {
  my $self = shift;
  ( join "\n", map {
    ref $_
      ? ( ' + ' . $_->info )
      : ( ' - [' . $_ . ']' )
    }
    @{$self->coverage} );
}

# erre nincs nagy szükség, ld. PlainSentence::info, de miért ne
sub info_all { # XXX elég hülye név
  my $self = shift;
  my $info = " STRCS=[";
  for ( my $i = 0; $i < $self->len; ++$i ) {
    foreach my $strc ( @{ $self->get($i) } ) {
      $info .= "\n  " . $strc->info;
    }
  }
  $info .= "\n ]"; 
}

# --- egyebek: a lényeg

# param: -
# mûköd: Token-tömb-ref -ként visszaadja a legjobb lefedést
#        legjobb lefedés: a lehetõ legbõvebb kódolt szerkezetek
#        olyan sorozata, mely lehetõ legjobban lefedi a mondatot,
#        az üres helyeken egy index lesz, ti. hogy
#        a mondat szavával kell a helyet kitölteni
# XXX kicsit zagyva ez a vegyes lista
# XXX Seq-t kéne visszaadni? De hogy?
sub coverage {
  my $self = shift;

  my @poslist = (); # pozíciókezdetek
                    # helyett lefedést adó tokenek,
                    # illetve index, ahol csak egy szó kell

  for ( my $i = 0; $i < $self->len; ++$i ) {
    # ha van kódolt strukturánk, akkor abból a leghosszabbat vesszük

    my $found = '';
    my $length = 0;
    my $tok = Token->new;
#    $tok->position( '0-0' ); # XXX miért nem jó ezzel a $length helyett

    # fordított ciklus, hogy azonos hosszon elõször a külsõbb
    # stuktúrát találjuk meg (!)
    for ( my $j = $self->cnt($i) - 1; $j >=0; --$j ) {

      my $x = ${ $self->get($i) }[$j]; # XXX esetleg valami get(i,j)

      if ( $x->position->len > $length ) {
#      if ( $x->position->len > $tok->position->len ) {
        $found = 1;
        $length = $x->position->len;
        $tok = $x; # ide copy kéne, nem? vagy nem módosítom?
      }
    }
    if ( $found ) {         # ha van kódolt struktúra, akkor az kell
      push @poslist, $tok;
      $i += $length - 1;
#      $i += $tok->position->len - 1;
    } else {                # ha nincs, akkor simán az index
      push @poslist, $i;
    }
  }
  \@poslist;
}

# param: typestr - az ilyen nevû annotációkat kell törölni
#        XXX pontosan ilyen nevût? - nem inkább az alárendelteket is XXX
sub delete {
  my $self = shift;
  my $type = shift;

  for ( my $i = 0; $i < $self->len; ++$i ) {
    for ( my $j = 0; $j < $self->cnt($i); ++$j ) {
      my $x = ${ $self->get($i) }[$j]; # XXX esetleg valami get(i,j)
      if ( $x->type->satisfies( $type ) ) {
        # $i-edik altömbbõl ki kell venni a $j-ediket
        # és a többit eggyel lejjebb kell csúsztatni
        my $k = $j;
        for ( ; $k < $self->cnt($i) - 1; ++$k ) {
          ${ $self->get($i) }[$k] = ${ $self->get($i) }[$k+1];
        }
        $#{ $self->get($i) } = $k-1; # eggyel összébb megy a tömb
        --$j; # az új j-ediket újból ellenõrizni kell
      }
    }
  }
}

1;

