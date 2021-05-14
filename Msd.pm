package Msd;

use strict;

use Object;
our @ISA = ( 'Object' );
use Exception;

my $NOMINAL = join '|', ( 'N', 'A', 'Num', 'MIA', 'MIB', 'MIF', 'Pro',
                          'Adv', 'Int', 'S', 'Abb' );
my $SIMPLE  = join '|', ( 'DIG', 'Det', 'NU', 'Pre', 'Con',
                          'ELO', 'SPUNCT', 'WPUNCT', 'Clit' );
my $UNKNOWN = join '|', ( 'UNKNOWN', 'UNKNOWNTAG' );

my $NOTFULL = '???'; # nem teljes (=nem MSD-kóddá alakítható) Msd

# --- konstr
sub new {
  my $class = shift;
  my $self = {};
  $self->{POSTAG}  = ''; # repr: string
# névszó
  $self->{TIVE}    = ''; # repr: string (fokozás)       e {pos,com,sup} XXX nem mechanikus
  $self->{NNUM}    = ''; # repr: string (szám)          e {sing,plur}
  $self->{PS}      = ''; # repr: string (birtokos)      e {yes,no}
  $self->{PSNUM}   = ''; # repr: string (birtokos:szám) e {sing,plur}
  $self->{PSPERS}  = ''; # repr: string (birt:szem)     e {1,2,3}
  $self->{PSPL}    = ''; # repr: string (birt:többes)   e {yes,no}
  $self->{ANA}     = ''; # repr: string (anaf '-é')     e {yes,no}
  $self->{ANAPL}   = ''; # repr: string (anaf:többes)   e {yes,no}
  $self->{CASE}    = ''; # repr: string (eset)
# ige ill. fni(pre,vnum,person)
  $self->{PRE}     = ''; # repr: string (igekötõ) e {yes,no}
  $self->{CONJ}    = ''; # repr: string (ragozás) e {subj,obj,lak}
  $self->{TENSE}   = ''; # repr: string (igekötõ) e {pres,past}         XXX nem mechanikus
  $self->{MOOD}    = ''; # repr: string (igekötõ) e {decl,impe,cond}    XXX nem mechanikus
  $self->{VNUM}    = ''; # repr: string (szám)    e {sing,plur}
  $self->{PERSON}  = ''; # repr: string (személy) e {1,2,3}
# számított attribútumok
  $self->{NUMBER}  = ''; # repr: string (névszó igazi, egyeztetendõ száma)
  $self->{UNKNOWN} = ''; # repr: string (ismert-e) e {yes,no}
  $self->{LOC}     = ''; # repr: string (helyhatározó) e {to,from}

  bless $self, $class;
}
# XXX minden belsõ érték hardkódolt - jó lesz ez így vajon?

# --- setter-getter-ek
sub postag { shift->_sg( shift, 'POSTAG' ); }

sub tive   { shift->_sg( shift, 'TIVE' ); }
sub nnum   { shift->_sg( shift, 'NNUM' ); }
sub ps     { shift->_sg( shift, 'PS' ); }
sub psnum  { shift->_sg( shift, 'PSNUM' ); }
sub pspers { shift->_sg( shift, 'PSPERS' ); }
sub pspl   { shift->_sg( shift, 'PSPL' ); }
sub ana    { shift->_sg( shift, 'ANA' ); }
sub anapl  { shift->_sg( shift, 'ANAPL' ); }
sub case   { shift->_sg( shift, 'CASE' ); }

sub pre    { shift->_sg( shift, 'PRE' ); }
sub conj   { shift->_sg( shift, 'CONJ' ); }
sub tense  { shift->_sg( shift, 'TENSE' ); }
sub mood   { shift->_sg( shift, 'MOOD' ); }
sub vnum   { shift->_sg( shift, 'VNUM' ); }
sub person { shift->_sg( shift, 'PERSON' ); }

# --- számított dolgok setter-getter-ei
# Ha be van valamire állítva, akkor
# azt adja vissza, és nem számolja ki az "igazit" (!)
# (Beállításnak talán csak Term esetén van értelme)
# XXX XXX XXX ennek inkább a parse-ben lenne a helye !?
sub number { # egyeztetési szám == a birtok száma
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->{NUMBER} = $val; }

  if ( $self->{NUMBER} eq '' ) { # ez lenne a default érték XXX
    my $number = '';
    if ( $self->ana eq 'yes' ) {         # ana
      if ( $self->anapl eq 'yes' ) {     # anapl -> plur
        $number = 'plur';
      } elsif ( $self->anapl eq 'no' ) {
        $number = 'sing';
      }
    } elsif ( $self->ps eq 'yes' ) {     # !ana de ps
      if ( $self->pspl eq 'yes' ) {      # pspl -> plur
        $number = 'plur';
      } elsif ( $self->pspl eq 'no' ) {
        $number = 'sing';
      }
    } else {                             # !ana és !ps
      $number = $self->nnum;             # = nnum
    }
    $self->{NUMBER} = $number;
  }
  $self->{NUMBER};
}
sub unknown { shift->_sg( shift, 'UNKNOWN' ); }
sub loc {
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->{LOC} = $val; }

  if ( $self->{LOC} eq '' ) { # ez lenne a default érték XXX
    my $loc = '';
    if ( $self->case eq 'ILL' or
         $self->case eq 'ALL' or $self->case eq 'SUB' ) {
      $loc = 'to'; # XXX névutók kezelése hibádzik (!)    
    } elsif ( $self->case eq 'ELA' or
              $self->case eq 'ABL' or $self->case eq 'DEL' ) {
      $loc = 'from'; # XXX névutók kezelése hibádzik (!)
    }
    $self->{LOC} = $loc;
  }
  $self->{LOC};
}

sub ok {
  my $self = shift;
  my $x = ''; # XXX hc
  my @keys = keys %{$self};
  for ( my $i = 0; $i < @keys and $x eq ''; ++$i ) {
    $x .= ${$self}{$keys[$i]} if defined ${$self}{$keys[$i]};
  }
  $x ne ''; # azaz, ha bárhol bármi be van állítva
}
#Ez lehet, hogy bazi lassú, és jobb lesz a régi (de rossz:) XXX
#sub ok { shift->postag ? 1 : '' }

# param: stringben az msd - ez az igazi setter (!)
sub parse {
  my $self = shift;
  my $ps = shift; $ps = '' if not defined $ps;

  $ps = $self->_simplify( $ps );
  my $s = $ps;

  $self->postag( '' );

  # --- ige
  if ( $s =~ m/^(?:(Pre)\.)?(V)\.([IT])?([FPM])?([et])([123])$/ ) {
    $self->pre( $1 ? 'yes' : 'no' );
    $self->postag( $2 );
    if ( $3 ) {
         if ( $3 eq 'I' ) { $self->conj( 'lak' ); }
      elsif ( $3 eq 'T' ) { $self->conj( 'obj' ); }
       else               { $self->conj( 'subj' ); }
    }
    if ( $4 ) {
         if ( $4 eq 'F' ) { $self->tense( 'pres' ); $self->mood( 'cond' ); }
      elsif ( $4 eq 'P' ) { $self->tense( 'pres' ); $self->mood( 'impe' ); }
      elsif ( $4 eq 'M' ) { $self->tense( 'past' ); $self->mood( 'decl' ); }
      else                { $self->tense( 'pres' ); $self->mood( 'decl' ); }
    }
    $self->vnum( $5 eq 'e' ? 'sing' : 'plur' );
    $self->person( $6 );
    # ige_msd.INFO szerint:
    # Pre. --> V. --> I --> F --> e --> 1
    # nil             T     P     t     2
    #                nil    M           3
    #                      nil
    $self->unknown( 'no' );

  # --- fõnévi igenév
  } elsif ( $s =~ m/^(?:(Pre)\.)?V\.IN(F|R..)$/ ) {
    $self->pre( $1 ? 'yes' : 'no' );
    $self->postag( 'INF' );
    my $inf = $2;
    if ( $inf =~ m/R(.)(.)/ ) {
      $self->vnum( $1 eq 'e' ? 'sing' : 'plur' );
      $self->person( $2 );
    }
    $self->unknown( 'no' );

  # --- határozói igenév
  } elsif ( $s =~ m/^(?:(Pre)\.)?V\.HIN$/ ) {
    $self->pre( $1 ? 'yes' : 'no' );
    $self->postag( 'HIN' );
    $self->unknown( 'no' );

  # --- névszó
  } elsif ( $s =~ m/^(?:(FF)\.)?($NOMINAL)(?:\.(FOK))?(?:\.(PL))?(?:\.(PS[et][123]i?))?(?:\.(POSi?))?(?:\.(...))?$/ ) {
    $self->postag( $2 );
    $self->tive( $1 ? 'sup' : ( $3 ? 'com' : 'pos' ) );
    # ha van 'FF.' akkor felsõ és figyelmen kívül hagyhatom a '.FOK'-ot
    $self->nnum( $4 ? 'plur' : 'sing' );
    my $ps = $5;
    my $ana = $6;
    $self->case( $7 ) if $7;

    if ( $ps and $ps =~ m/PS(.)(.)(i?)/ ) {
      $self->ps( 'yes' );
      $self->psnum( $1 eq 'e' ? 'sing' : 'plur' );
      $self->pspers( $2 );
      $self->pspl( $3 ? 'yes' : 'no' );
    } else {
      $self->ps( 'no' );
    }

    if ( $ana and $ana =~ m/POS(i?)/ ) {
      $self->ana( 'yes' );
      $self->anapl( $1 ? 'yes' : 'no' );
    } else {
      $self->ana( 'no' );
    }
    # nevszo_msd.INFO szerint:
    # FF. --> {alap} --> .FOK --> .PL --> {ps} --> {pos} --> {eset}
    # {alap} - A Abb Adv Int MIA MIB MIF N Num Pro S
    # {ps} --- .PS[et][123](i)
    # {pos} -- .POS(i)
    # {eset} - .NOM .FOR .TEM .CAU .TER .DAT .SUB .DEL .INE .ELA
    #          .ILL .ADE .ABL .INS .SOC .FAC .ALL .SUP .ACC .ESS
    $self->unknown( 'no' );

  } elsif ( $s =~ m/^($NOMINAL)$/ ) { # pl. 'Adv' miatt
    $self->postag( $1 );
    $self->unknown( 'no' );

  # --- egyebek
  } elsif ( $s =~ m/^($SIMPLE)$/ ) {
    $self->postag( $1 );
    $self->unknown( 'no' );
  } elsif ( $s =~ m/^($UNKNOWN)$/ ) {
    $self->postag( $1 );
    $self->unknown( 'yes' );
  }

# ami megváltozott (!) - logolás XXX
if ( $self->as_string ne $ps ) {
  print STDERR "[$ps] " . $self->info;
  print STDERR " -> [" . $self->as_string . "]";
  print STDERR "\n";
}

  $self->ok ? $self : "$Exception::msg Erroneous MSD string [$s].";
}

# param: egy msd-string
# mûköd: kötõjeleket és a vagylagosságot heurisztikával kiegyszerûsíti
sub _simplify {
  my $self = shift;
  my $s = shift;

  foreach my $spl ( ( '[|]', '--' ) ) {
    if ( $s =~ m/$spl/ ) {
      my @a = split /$spl/, $s;
      if ( @a == 2 and $a[0] eq $a[1] ) {
        $s = $a[0];
      } else {
        $s = $a[-1];
        # minden esetben az utolsót vesszük
        # - kötõjeles szónál ez talán mindig jó,
        # - vagylagosság esetén viszont csak mázli, ha épp az utsó a jó XXX
      }
    }
  }
  $s;
}

sub copy {
  my $self = shift;
  my $m = shift;
  if ( $m->isa( 'Msd' ) ) {
    foreach my $k ( keys %{$self} ) {
      my $sub = lc($k);
      $self->$sub( $m->$sub );
    }
    $self;
  } else {
    "$Exception::msg " . ref( $self ) .
    "::copy requires a " . ref( $self ) . ".";
  }
}

sub as_string {
  my $self = shift;

  my $s = '';

  if ( $self->ok ) {
    if ( $self->postag =~ m/^($SIMPLE)$/ ) {
      $s .= $self->postag;
    } elsif ( $self->postag eq 'V' ) {
      $s .= $self->pre eq 'yes' ? 'Pre.' : '';
      $s .= 'V.';
      $s .= $self->conj eq 'lak' ? 'I' : '';
      $s .= $self->conj eq 'obj' ? 'T' : '';
      $s .= $self->tense eq 'past' ? 'M' : '';
      $s .= $self->mood eq 'impe' ? 'P' : '';
      $s .= $self->mood eq 'cond' ? 'F' : '';
      $s .= $self->vnum eq 'plur' ? 't' : 'e';
      $s .= $self->person;
    } elsif ( $self->postag eq 'INF' ) {
      $s .= $self->pre eq 'yes' ? 'Pre.' : '';
      $s .= 'V.IN';
      if ( $self->vnum ) {
        $s .= 'R' . ( $self->vnum eq 'plur' ? 't' : 'e' ) . $self->person;
      } else {
        $s .= 'F';
      }
    } elsif ( $self->postag eq 'HIN' ) {
      $s .= $self->pre eq 'yes' ? 'Pre.' : '';
      $s .= 'V.HIN';
    } else { # névszó
      $s .= $self->tive eq 'sup' ? 'FF.' : '';
      $s .= $self->postag;
      $s .= ( $self->tive eq 'com' or $self->tive eq 'sup' ) ? '.FOK' : '';
      $s .= ( $self->nnum eq 'plur' ) ? '.PL' : '';
      if ( $self->ps eq 'yes' ) {
        $s .= '.PS' .
          ( $self->psnum eq 'plur' ? 't' : 'e' ) .
          $self->pspers .
          ( $self->pspl eq 'yes' ? 'i' : '' );
      }
      if ( $self->ana eq 'yes' ) {
        $s .= '.POS' .
          ( $self->anapl eq 'yes' ? 'i' : '' );
      }
      $s .= $self->case ? ( '.' . $self->case ) : '';
    }
    $s;
  } else {
    $NOTFULL;
  }
}

sub info {
  my $self = shift;

  my $info = '';

  my $str = $self->as_string;
  if ( $str ne $NOTFULL ) {         # ha értelmes az as_string
    my $number = $self->number;
    my $loc = $self->loc;
    $info .= $self->as_string .
      # hozzátesszük a számított attribútumokat
      ( $number ? ( '[' . $number . ']' ) : '' ) .
      ( $loc ? ( '[' . $loc . ']' ) : '' );
      #( $number ? ( ',number=[' . $number . ']' ) : '' );
  } else {                          # ha nem értelmes az as_string
    foreach my $k ( sort keys %{$self} ) {
      my $sub = lc($k);
      if ( $self->$sub ) {
        $info .= ",$sub=[" . $self->$sub . "]";
      }
    }
    $info =~ s/^,//;
  }
  $info;
}

# --- egyebek: a lényeg
sub satisfies {
  my $self = shift;
  my $msd = shift; # XXX ennek Msd-nek kell lennie ...

  my $ok = 1;

  my @keys = keys %{$self};

  for ( my $i = 0; $ok and $i < @keys; ++$i ) {
    my $sub = lc($keys[$i]);
    if ( $msd->$sub and $self->$sub ne $msd->$sub ) {
      $ok = '';
    }
  }

  $ok;
}

1;

