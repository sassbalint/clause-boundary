package Annotation;

use strict;

use Object;
our @ISA = ( 'Object' );

# --- konstr
sub new {
  my $class = shift;
  my $self = []; # egy t�mb (!), ami a strukt�r�kat t�rol�
                 # t�mb�ket tartalmazza: az i. poz�ci�n�l
                 # kezd�d� strukt�ra az i. alt�mbben van
  bless $self, $class;
}

# megfelel� m�ret� legyen
sub init {
  my $self = shift;
  my $size = shift;
  for ( my $i = 0; $i < $size; ++$i ) {
    $self->[$i] = [];
  }
  $self;
}

# --- setter-getter-ek

# param: egy t�roland� Token (=strukt�ra)
# m�k�d: a Token-t a kezd�poz�ci�ja �ltal meghat�rozott
#        index� t�mbh�z adja hozz�
#        ezt a Token->position->begpos mutatja meg
# XXX logik�tlan, hogy a strukt�r�k Token n�ven futnak, de egyel�re ez van.
#     az�rt stimmel egy�bk�nt, mert csak egy t�pus+poz�ci� strukt�ra-v�zat
#     t�rolunk, ami a PlainSentence konkr�t Token-jeire hivatkozik.
#     az teszi lehet�v� a logik�tlans�got, hogy a Token-beli Position
#     is t�rolhat intervallumot - tiltsuk le, vagy mi?
# XXX esetleg lehetne ide a Tokennek egy �rtelmes lesz�rmazottja
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

# i. alt�mb, azaz az adott poz�ci�n kezd�d� szerkezetek t�mbje
sub get {
  my $self = shift;
  my $index = shift;
  ( $index >= 0 and $index < $self->len )
    ? $self->[$index]
    : "$Exception::msg index ($index) out of bounds (0.." .
      ($self->len - 1) . ") in Annotation::get";
}

# i. alt�mb hossza, azaz az adott poz�ci�n kezd�d� szerkezetek sz�ma
sub cnt {
  my $self = shift;
  my $index = shift;
  ( $index >= 0 and $index < $self->len )
    ? scalar @{ $self->[$index] }
    : "$Exception::msg index ($index) out of bounds (0.." .
      ($self->len - 1) . ") in Annotation::cnt"; # XXX k�dduplik�l�s (!)
}

sub as_array {
  my $self = shift;
  my @arr = ();
  for ( my $i = 0; $i < $self->len; ++$i ) {
    @arr = ( @arr, @{ $self->get($i) } ); # XXX ez biztos d�g lass�
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

# v�: PlainSentence::strcs_info
sub info {
  my $self = shift;
  ( join "\n", map {
    ref $_
      ? ( ' + ' . $_->info )
      : ( ' - [' . $_ . ']' )
    }
    @{$self->coverage} );
}

# erre nincs nagy sz�ks�g, ld. PlainSentence::info, de mi�rt ne
sub info_all { # XXX el�g h�lye n�v
  my $self = shift;
  my $info = " STRCS=[";
  for ( my $i = 0; $i < $self->len; ++$i ) {
    foreach my $strc ( @{ $self->get($i) } ) {
      $info .= "\n  " . $strc->info;
    }
  }
  $info .= "\n ]"; 
}

# --- egyebek: a l�nyeg

# param: -
# m�k�d: Token-t�mb-ref -k�nt visszaadja a legjobb lefed�st
#        legjobb lefed�s: a lehet� legb�vebb k�dolt szerkezetek
#        olyan sorozata, mely lehet� legjobban lefedi a mondatot,
#        az �res helyeken egy index lesz, ti. hogy
#        a mondat szav�val kell a helyet kit�lteni
# XXX kicsit zagyva ez a vegyes lista
# XXX Seq-t k�ne visszaadni? De hogy?
sub coverage {
  my $self = shift;

  my @poslist = (); # poz�ci�kezdetek
                    # helyett lefed�st ad� tokenek,
                    # illetve index, ahol csak egy sz� kell

  for ( my $i = 0; $i < $self->len; ++$i ) {
    # ha van k�dolt struktur�nk, akkor abb�l a leghosszabbat vessz�k

    my $found = '';
    my $length = 0;
    my $tok = Token->new;
#    $tok->position( '0-0' ); # XXX mi�rt nem j� ezzel a $length helyett

    # ford�tott ciklus, hogy azonos hosszon el�sz�r a k�ls�bb
    # stukt�r�t tal�ljuk meg (!)
    for ( my $j = $self->cnt($i) - 1; $j >=0; --$j ) {

      my $x = ${ $self->get($i) }[$j]; # XXX esetleg valami get(i,j)

      if ( $x->position->len > $length ) {
#      if ( $x->position->len > $tok->position->len ) {
        $found = 1;
        $length = $x->position->len;
        $tok = $x; # ide copy k�ne, nem? vagy nem m�dos�tom?
      }
    }
    if ( $found ) {         # ha van k�dolt strukt�ra, akkor az kell
      push @poslist, $tok;
      $i += $length - 1;
#      $i += $tok->position->len - 1;
    } else {                # ha nincs, akkor sim�n az index
      push @poslist, $i;
    }
  }
  \@poslist;
}

# param: typestr - az ilyen nev� annot�ci�kat kell t�r�lni
#        XXX pontosan ilyen nev�t? - nem ink�bb az al�rendelteket is XXX
sub delete {
  my $self = shift;
  my $type = shift;

  for ( my $i = 0; $i < $self->len; ++$i ) {
    for ( my $j = 0; $j < $self->cnt($i); ++$j ) {
      my $x = ${ $self->get($i) }[$j]; # XXX esetleg valami get(i,j)
      if ( $x->type->satisfies( $type ) ) {
        # $i-edik alt�mbb�l ki kell venni a $j-ediket
        # �s a t�bbit eggyel lejjebb kell cs�sztatni
        my $k = $j;
        for ( ; $k < $self->cnt($i) - 1; ++$k ) {
          ${ $self->get($i) }[$k] = ${ $self->get($i) }[$k+1];
        }
        $#{ $self->get($i) } = $k-1; # eggyel �ssz�bb megy a t�mb
        --$j; # az �j j-ediket �jb�l ellen�rizni kell
      }
    }
  }
}

1;

