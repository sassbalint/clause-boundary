package PlainSentence;

use strict;

use Seq;
our @ISA = ( 'Seq' );
use Annotation;

# --- konstansok
my $DEBUG = '';

# regexp-ben a tal�lat jel�l�i
our $LM = '{';
our $RM = '}';

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{STRCS} = Annotation->new;
    # XXX az els� add_strcs_elem() h�v�skor inicializ�l�dik
  bless ($self, $class);
}

# --- konstans getter-ek
sub LM { shift; return $LM; }
sub RM { shift; return $RM; }

# --- setter-getter-ek

# XXX setterk�nt �gy haszn�ln�m az Annotation oszt�lyt,
# XXX mint sima t�mb�t, �s ez nem helyes ! :)
# XXX de nem k�ne/fogom setterk�nt haszn�lni. :)
sub strcs {
  shift->_sg_objectlist( shift, 'STRCS', 'strcs', 'Token' );
}

# param: egy t�roland� strukt�ra (Token-k�nt)
# m�k�d: a Token-t elt�rolja STRCS-ben
# XXX logik�tlans�g�t ld. Annotation kommentj�ben
sub add_strcs_elem {
  my $self = shift;
  my $tok = shift;
  if ( $self->len != $self->strcs->len ) {
    $self->strcs->init( $self->len );
  }
  $self->strcs->add_elem( $tok );
}

# param: form�tum 'XML' vagy 'plain' vagy 'generative'
# XXX ugye az as_string -nek nem szokott param�tere lenni
sub as_string {
  my $self = shift;
  my $format = shift; # XXX 'XML' vagy 'plain' vagy 'generative'
  $format = 'plain' if not defined $format;
  my $string;
  my @ends = ();
    # a v�gek kezel�se a kezdetn�l val� t�rol�s miatt kicsit bonyolult,
    # de sokkal jobb �gy szerintem, mint itt is ott is t�rolni
my $ind = 0;
  for ( my $i = 0; $i < $self->len; ++$i ) {
    $string .= ' ' if not $i == 0;
    # nyit� "tag"
    # a ravasz 'reverse' miatt kap�sb�l azt nyitja el�bb, amelyik hosszabb
no strict "refs";
# itt nagy diszn�s�g van! rendbe k�ne tenni XXX XXX XXX
# ti. van, mikor a get Exception-t ad (vajon mi�rt)
# de �gy is gond n�lk�l j� a m�k�d�s, ha azt egyszer�en
# sz�mk�nt (t�mbindexk�nt) kezelj�k
# ezut�bbi sz�rny� l�p�st nem engedn� a strict "refs"
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
    # z�r� "tag"
    # a ravasz 'reverse' miatt kap�sb�l azt z�rja el�bb, amelyik r�videbb
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

# XXX ink�bb valahogy az Annotation-ba lenne val�: v�: Annotation::info
# de az�rt nem f�r oda, mert ott nem "tudunk" a f�l�tte l�v� seq-ra hivatkozni
sub strcs_info {
  my $self = shift;
  my $info = '';
# a kikommentezett r�sz a r�gi v�ltozat, mikor a be�gyazott Strc-ket is ki�rtam
#  for ( my $i = 0; $i < $self->strcs->len; ++$i ) {
#    foreach my $strc ( @{ $self->strcs->get($i) } ) {
  foreach my $strc ( @{ $self->strcs->coverage } ) {
    if ( ref $strc ) {
      $info .= "\n + \"";

      $info .= join ' ', map { $_->form }
        @{ $self->seq }[ $strc->position->begpos .. $strc->position->endpos ];

      $info .= "\"\t";
      # uts� el�tti sz� adatai a n�vut�k kedv��rt (gagyesz)
      # XXX XXX XXX mindenk�pp betesz valamit (-1 eset�n az uts� sz�t)
      # XXX XXX XXX �s m�g az sem biztos, hogy
      #             egy�ltal�n hozz�tartozik a szerkezethez!!!!!
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

# --- egyebek: a l�nyeg

# param: egy alkalmazand� szab�ly
# m�k�d: karakteres regexp-k�dol�ssal, regexp-illeszt�ssel
#        megkeresi, �s strc-ben t�rolja az illeszked� szerkezeteket
sub match {
  my $self = shift;
  my $rule = shift;

  $self->_regexp_code( $rule );
  my $coded_sent = $self->_regexp_match( $rule );
  $self->_regexp_store( $rule, $coded_sent );
}

# param: egy alkalmazand� szab�ly
# m�k�d: szab�ly termjeinek �s a mondat illeszked� tokenjeinek k�dol�sa
sub _regexp_code {
  my $self = shift;
  my $rule = shift;

  $rule->autocode;
  #print "\n *** A bek�dolt szab�ly:\n";
  #print $rule->info . "\n";

  #print "\n *** Az illeszked�sek k�dokkal:\n";
  foreach my $w ( @{ $self->seq } ) {
    foreach my $t ( @{ $rule->seq } ) {
      if ( $w->satisfies( $t ) ) {
        $w->code( $t->code ); # ennyi a k�dol�s
        print $w->info . "\n" if $DEBUG;
        last;
        # XXX az els� megtal�ltn�l kil�p�nk, azaz az �tk�z�s nincs kezelve
      } else {
        $w->code( '-' ); # ennyi a k�dol�s XXX hc
      }
    }
  }
}

# param: egy alkalmazand� szab�ly
# m�k�d: regex-k�sz�t�s �s match-el�s
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

  print "\n *** A k�dolt mondat:\n" . $coded_sent . "\n" if $DEBUG;
  print "\n *** A k�dolt szab�ly:\n" . $coded_rule . "\n" if $DEBUG;

  # itt t�rt�nik meg minden ...
  $coded_sent =~ s/($coded_rule)/$self->LM . $1 . $self->RM/ge;

  print "\n *** A felismert szerkezetek (k�dolt alak):\n" .
    $coded_sent . "\n\n" if $DEBUG;

  $coded_sent;
}

# param: egy alkalmazand� szab�ly
#        _regexp_match eredm�nyek�nt kij�tt k�dolt mondat
# m�k�d: regexp-pel k�dolt mondat visszaalak�t�sa
#        �s a tal�latok feljegyz�se a mondat strukt�r�i (strc) k�z�
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
      $self->add_strcs_elem( $s ); # mindig Token -> hibakezel�s nem kell
    }
    ++$i;
  }
}

1;

