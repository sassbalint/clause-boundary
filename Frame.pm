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
our $COMP         = 4; # csak azért 4, hogy stimmeljen a zeman.pl-vel

# --- konstr
sub new {
  my $class = shift;
  my $self = [];
  $self->[$VERB] = '';
  $self->[$FREQ] = 0;
  $self->[$LENGTH] = 0;
  $self->[$COMP] = {}; # eset-kulcsú hash, értékek a megfelelõ lemmák
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

# a teljes comp hashref beállítása/lekérdezése
sub comp {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->[$COMP] = $val; }
  $self->[$COMP];
}

# adott esethez tartozó lemma beállítása/lekérdezése
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

# --- egyebek: a lényeg
# Frame feltöltése 'new_compx..xb' formátumú fájl egy sorából
# feltesszük, hogy a bemenet valóban 'new_compx..xb' formátumú (!)
#
# forrás: zeman.pl/create_frame
#         egy szabad eseteket (.tap.tth-t) kezelõ változatot: ld. speci.pl
sub parse_new_compx_xb {
  my $self = shift;
  my $s = shift;

  chomp $s;
  $s =~ s/^\s+//; # soreleji ws
  my @compl = ();
  ( $self->[$FREQ], $self->[$VERB], @compl ) = split /\s+/, $s;

  my %comp = ();
  my $len = 0; # a keret hossza

  # a new_compx fájlok formátumának feldolgozása.
  # ha többször van ua. eset: az ELSÕ számít, a többi elvész!
  # (-><- comst.pl -l azaz a mazsoladb az UTOLSÓt veszi!!)
  #
  # mivel csak OF-kel dolgozunk (xb fájlok), szabad eset nem fodul elõ itt

  foreach my $c ( @compl ) {
    my $lemma = '';
    my $case = '';
    my $len_inc = 0;

#    # NULLACC elõzetes kezelése - kikapcsolva
#    # ezt jó lenne paraméterezhetõvé tenni! ld. zeman.pl XXX
#    # if ( $c =~ /^(NULL)(ACC)$/ and $NULLACC == 1 )
#    if ( $c =~ /^(NULL)(ACC)$/ ) {
#      $lemma = '';
#      $case = $2;
#      $len_inc = 1; # !!! ugye nincs lemma -> a hossz csak 1-gyel nõ!

    # fix névutós - gagyi: utsó '=' a szeparátor
    # -> az '='-t tartalmazó szóval baj lesz! Nem érdekel. :) XXX
    # az '=' jelet belevettem a névutóba
    #  * hogy egyszerûbb legyen a visszaállítás
    #  * plusz alább postp() és real_cases() is erre épít!
    if ( $c =~ /^(.+)(=.+)$/ ) {  
      $lemma = $1;
      $case = $2;
      $len_inc = 2;
    # fix esetes - gagyi: utsó 3 nagybetû az eset XXX
    # javítás: itt korábban simán csak (...) volt!
    } elsif ( $c =~ /^(.+)([A-Z]{3})$/ ) {
      $lemma = $1;
      $case = $2;
      $len_inc = 2;
    # mikor van HIBA: pl. eset nélküli (unknown) NE
    # hibakezelés: asszem így kell használni az Exception.pm -et
    } else {
      return "$Exception::msg Erroneous complement string [$c].";
    }

# SIMA változat - az INDEXES változatot ld. zeman.pl
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

# milyen nevutók vannak
sub postp {
  my $self = shift;
  grep $_ =~ /^=/, sort keys %{ $self->[$COMP] };
}

# milyen sima esetek vannak (nem névutók!)
sub real_cases {
  my $self = shift;
  grep $_ !~ /^=/, sort keys %{ $self->[$COMP] };
}

1;

