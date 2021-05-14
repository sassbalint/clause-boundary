package Frame;

use strict;

use Object;
our @ISA = ( 'Object' );
# use egyebek;

# --- konstansok
# indexek
our $VERB         = 0;
our $FREQ         = 1;
our $LENGTH       = 2;
our $COMP         = 4; # csak az�rt 4, hogy stimmeljen a zeman.pl-vel

# --- konstr
sub new {
  my $class = shift;
  my $self = [];
  $self->[$VERB] = '';
  $self->[$FREQ] = 0;
  $self->[$LENGTH] = 0;
  $self->[$COMP] = {}; # eset-kulcs� hash, �rt�kek a megfelel� lemm�k
  bless $self, $class;
}

# --- konstans getter-ek
#sub CONST { shift; return $CONST; }

# --- setter-getter-ek
sub verb {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$VERB] = $val; }
  $self->[$VERB];
}

sub freq {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$FREQ] = $val; }
  $self->[$FREQ];
}

sub length {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$LENGTH] = $val; }
  $self->[$LENGTH];
}

# a teljes comp hashref be�ll�t�sa/lek�rdez�se
sub comp {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$COMP] = $val; }
  $self->[$COMP];
}

# adott esethez tartoz� lemma be�ll�t�sa/lek�rdez�se
sub lemma {
  my $self = shift;
  my $case = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$COMP]->{$case} = $val; }
  $self->[$COMP]->{$case};
}

sub as_string {
  my $self = shift;
  $self->[$VERB] . "\t" .
  $self->[$FREQ] . "\t" .
  _comp_as_string( $self ) . "\t" .
  $self->[$LENGTH];
}

sub _comp_as_string {
  my $self = shift;
  join ',', map { $self->[$COMP]->{$_} . $_ } sort keys %{ $self->[$COMP] };
}

# --- egyebek: a l�nyeg
# Frame felt�lt�se 'new_compx..xb' form�tum� f�jl egy sor�b�l
# feltessz�k, hogy a bemenet val�ban 'new_compx..xb' form�tum� (!)
#
# forr�s: zeman.pl/create_frame
#         egy szabad eseteket (.tap.tth-t) kezel� v�ltozatot: ld. speci.pl
sub parse_new_compx_xb {
  my $self = shift;
  my $s = shift;

  chomp $s;
  $s =~ s/^\s+//; # soreleji ws
  my @compl = ();
  ( $self->[$FREQ], $self->[$VERB], @compl ) = split /\s+/, $s;

  my %comp = ();
  my $len = 0; # a keret hossza

  # a new_compx f�jlok form�tum�nak feldolgoz�sa.
  # ha t�bbsz�r van ua. eset: az ELS� sz�m�t, a t�bbi elv�sz!
  # (-><- comst.pl -l azaz a mazsoladb az UTOLS�t veszi!!)
  #
  # mivel csak OF-kel dolgozunk (xb f�jlok), szabad eset nem fodul el� itt

  foreach my $c ( @compl ) {
    my $lemma = '';
    my $case = '';
    my $len_inc = 0;

#    # NULLACC el�zetes kezel�se - kikapcsolva
#    # ezt j� lenne param�terezhet�v� tenni! ld. zeman.pl XXX
#    # if ( $c =~ /^(NULL)(ACC)$/ and $NULLACC == 1 )
#    if ( $c =~ /^(NULL)(ACC)$/ ) {
#      $lemma = '';
#      $case = $2;
#      $len_inc = 1; # !!! ugye nincs lemma -> a hossz csak 1-gyel n�!

    # fix n�vut�s - gagyi: uts� '=' a szepar�tor
    # -> az '='-t tartalmaz� sz�val baj lesz! Nem �rdekel. :) XXX
    # az '=' jelet belevettem a n�vut�ba
    #  * hogy egyszer�bb legyen a vissza�ll�t�s
    #  * plusz al�bb postp() �s real_cases() is erre �p�t!
    if ( $c =~ /^(.+)(=.+)$/ ) {  
      $lemma = $1;
      $case = $2;
      $len_inc = 2;
    # fix esetes - gagyi: uts� 3 nagybet� az eset XXX
    # jav�t�s: itt kor�bban sim�n csak (...) volt!
    } elsif ( $c =~ /^(.+)([A-Z]{3})$/ ) {
      $lemma = $1;
      $case = $2;
      $len_inc = 2;
    # mikor van HIBA: pl. eset n�lk�li (unknown) NE
    # hibakezel�s: asszem �gy kell haszn�lni az Exception.pm -et
    } else {
      return "$Exception::msg Erroneous complement string [$c].";
    }

# SIMA v�ltozat - az INDEXES v�ltozatot ld. zeman.pl
    if ( not exists $self->[$COMP]->{$case} ) {
      $self->[$COMP]->{$case} = $lemma;
      $len += $len_inc;
    }

  }
  $self->[$LENGTH] = $len;
  $self;
}

# milyen esetek vannak a keretben
sub cases {
  my $self = shift;
  sort keys %{ $self->[$COMP] };
}

# milyen nevut�k vannak
sub postp {
  my $self = shift;
  grep $_ =~ /^=/, sort keys %{ $self->[$COMP] };
}

# milyen sima esetek vannak (nem n�vut�k!)
sub real_cases {
  my $self = shift;
  grep $_ !~ /^=/, sort keys %{ $self->[$COMP] };
}

1;

