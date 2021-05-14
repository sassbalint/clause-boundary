package PlainSentence;

use strict;

use Seq;
our @ISA = ( 'Seq' );
use Annotation;

# --- konstansok
my $DEBUG = '';

# regexp-ben a találat jelölõi
our $LM = '{';
our $RM = '}';

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{STRCS} = Annotation->new;
    # XXX az elsõ add_strcs_elem() híváskor inicializálódik
  bless ($self, $class);
}

# --- konstans getter-ek
sub LM { shift; return $LM; }
sub RM { shift; return $RM; }

# --- setter-getter-ek

# XXX setterként úgy használnám az Annotation osztályt,
# XXX mint sima tömböt, és ez nem helyes ! :)
# XXX de nem kéne/fogom setterként használni. :)
sub strcs {
  shift->_sg_objectlist( shift, 'STRCS', 'strcs', 'Token' );
}

# param: egy tárolandó struktúra (Token-ként)
# mûköd: a Token-t eltárolja STRCS-ben
# XXX logikátlanságát ld. Annotation kommentjében
sub add_strcs_elem {
  my $self = shift;
  my $tok = shift;
  if ( $self->len != $self->strcs->len ) {
    $self->strcs->init( $self->len );
  }
  $self->strcs->add_elem( $tok );
}

# param: formátum 'XML' vagy 'plain' vagy 'generative'
# XXX ugye az as_string -nek nem szokott paramétere lenni
sub as_string {
  my $self = shift;
  my $format = shift; # XXX 'XML' vagy 'plain' vagy 'generative'
  $format = 'plain' if not defined $format;
  my $string;
  my @ends = ();
    # a végek kezelése a kezdetnél való tárolás miatt kicsit bonyolult,
    # de sokkal jobb így szerintem, mint itt is ott is tárolni
my $ind = 0;
  for ( my $i = 0; $i < $self->len; ++$i ) {
    $string .= ' ' if not $i == 0;
    # nyitó "tag"
    # a ravasz 'reverse' miatt kapásból azt nyitja elõbb, amelyik hosszabb
no strict "refs";
# itt nagy disznóság van! rendbe kéne tenni XXX XXX XXX
# ti. van, mikor a get Exception-t ad (vajon miért)
# de úgy is gond nélkül jó a mûködés, ha azt egyszerûen
# számként (tömbindexként) kezeljük
# ezutóbbi szörnyû lépést nem engedné a strict "refs"
    my @arr = @{ $self->strcs->get($i) };
use strict "refs";
    if ( @arr ) {
      foreach my $strc ( reverse @arr ) {
        $string .= $format eq 'XML'
          ? "\n" . ( ' ' x $ind++ ) . '<' . $strc->type->as_string .
            ' pos="' . $strc->position->as_string . '">'
          : ( $format eq 'generative'
            ? '[' . $strc->type->as_string . ' '
            : $strc->type->as_string . '{'
            );
        push ( @ends, $strc );
      }
    }
    # tartalom
    $string .= $format eq 'XML'
      ? "\n      " . ${ $self->seq }[$i]->form
      : ${ $self->seq }[$i]->form;
    # záró "tag"
    # a ravasz 'reverse' miatt kapásból azt zárja elõbb, amelyik rövidebb
    foreach my $strc ( reverse @ends ) {
      if ( $strc->position->endpos == $i ) {
        $string .= $format eq 'XML'
          ? "\n" . ( ' ' x --$ind ) . '<#' . $strc->type->as_string .
            ' pos="' . $strc->position->as_string . '">'
          : ( $format eq 'generative' ? ']' : '}' );
      }
    }
  }
  $string;
}

sub info {
  my $self = shift;
  my $info = $self->SUPER::info .
  "\n STRCS=[";
  $info .= $self->strcs_info;
  $info .= "\n ]";
}

# XXX inkább valahogy az Annotation-ba lenne való: vö: Annotation::info
# de azért nem fér oda, mert ott nem "tudunk" a fölötte lévõ seq-ra hivatkozni
sub strcs_info {
  my $self = shift;
  my $info = '';
# a kikommentezett rész a régi változat, mikor a beágyazott Strc-ket is kiírtam
#  for ( my $i = 0; $i < $self->strcs->len; ++$i ) {
#    foreach my $strc ( @{ $self->strcs->get($i) } ) {
  foreach my $strc ( @{ $self->strcs->coverage } ) {
    if ( ref $strc ) {
      $info .= "\n + \"";

      $info .= join ' ', map { $_->form }
        @{ $self->seq }[ $strc->position->begpos .. $strc->position->endpos ];

      $info .= "\"\t";
      # utsó elõtti szó adatai a névutók kedvéért (gagyesz)
      # XXX XXX XXX mindenképp betesz valamit (-1 esetén az utsó szót)
      # XXX XXX XXX és még az sem biztos, hogy
      #             egyáltalán hozzátartozik a szerkezethez!!!!!
      $info .= ${ $self->seq }[ $strc->position->endpos - 1 ]->info;
      $info .= "\t";
      $info .= $strc->info;
    } else {
      $info .= "\n - [$strc]";
    }
  }
#    }
#  }
  $info;
}

# --- egyebek: a lényeg

# param: egy alkalmazandó szabály
# mûköd: karakteres regexp-kódolással, regexp-illesztéssel
#        megkeresi, és strc-ben tárolja az illeszkedõ szerkezeteket
sub match {
  my $self = shift;
  my $rule = shift;

  $self->_regexp_code( $rule );
  my $coded_sent = $self->_regexp_match( $rule );
  $self->_regexp_store( $rule, $coded_sent );
}

# param: egy alkalmazandó szabály
# mûköd: szabály termjeinek és a mondat illeszkedõ tokenjeinek kódolása
sub _regexp_code {
  my $self = shift;
  my $rule = shift;

  $rule->autocode;
  #print "\n *** A bekódolt szabály:\n";
  #print $rule->info . "\n";

  #print "\n *** Az illeszkedések kódokkal:\n";
  foreach my $w ( @{ $self->seq } ) {
    foreach my $t ( @{ $rule->seq } ) {
      if ( $w->satisfies( $t ) ) {
        $w->code( $t->code ); # ennyi a kódolás
        print $w->info . "\n" if $DEBUG;
        last;
        # XXX az elsõ megtaláltnál kilépünk, azaz az ütközés nincs kezelve
      } else {
        $w->code( '-' ); # ennyi a kódolás XXX hc
      }
    }
  }
}

# param: egy alkalmazandó szabály
# mûköd: regex-készítés és match-elés
sub _regexp_match {
  my $self = shift;
  my $rule = shift;

  my $coded_sent;
  foreach my $w ( @{ $self->seq } ) {
    $coded_sent .= $w->code;
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

  $coded_sent;
}

# param: egy alkalmazandó szabály
#        _regexp_match eredményeként kijött kódolt mondat
# mûköd: regexp-pel kódolt mondat visszaalakítása
#        és a találatok feljegyzése a mondat struktúrái (strc) közé
sub _regexp_store {
  my $self = shift;
  my $rule = shift;
  my $coded_sent = shift;

  my $i = 0;
  my $beg;
  my $end;
  foreach my $ch ( split //, $coded_sent ) {
    if ( $ch eq $self->LM ) {
      $beg = $i;
      --$i;
    } elsif ( $ch eq $self->RM ) {
      --$i;
      $end = $i;
      my $s = Token->new;
      $s->position( $beg, $end );
      $s->type->copy( $rule->type );
      $self->add_strcs_elem( $s ); # mindig Token -> hibakezelés nem kell
    }
    ++$i;
  }
}

1;

