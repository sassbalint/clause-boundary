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

my $NOTFULL = '???'; # nem teljes (=nem MSD-k�dd� alak�that�) Msd

# --- konstr
sub new {
  my $class = shift;
  my $self = {};
  $self->{POSTAG}  = ''; # repr: string
# n�vsz�
  $self->{TIVE}    = ''; # repr: string (fokoz�s)       e {pos,com,sup} XXX nem mechanikus
  $self->{NNUM}    = ''; # repr: string (sz�m)          e {sing,plur}
  $self->{PS}      = ''; # repr: string (birtokos)      e {yes,no}
  $self->{PSNUM}   = ''; # repr: string (birtokos:sz�m) e {sing,plur}
  $self->{PSPERS}  = ''; # repr: string (birt:szem)     e {1,2,3}
  $self->{PSPL}    = ''; # repr: string (birt:t�bbes)   e {yes,no}
  $self->{ANA}     = ''; # repr: string (anaf '-�')     e {yes,no}
  $self->{ANAPL}   = ''; # repr: string (anaf:t�bbes)   e {yes,no}
  $self->{CASE}    = ''; # repr: string (eset)
# ige ill. fni(pre,vnum,person)
  $self->{PRE}     = ''; # repr: string (igek�t�) e {yes,no}
  $self->{CONJ}    = ''; # repr: string (ragoz�s) e {subj,obj,lak}
  $self->{TENSE}   = ''; # repr: string (igek�t�) e {pres,past}         XXX nem mechanikus
  $self->{MOOD}    = ''; # repr: string (igek�t�) e {decl,impe,cond}    XXX nem mechanikus
  $self->{VNUM}    = ''; # repr: string (sz�m)    e {sing,plur}
  $self->{PERSON}  = ''; # repr: string (szem�ly) e {1,2,3}
# sz�m�tott attrib�tumok
  $self->{NUMBER}  = ''; # repr: string (n�vsz� igazi, egyeztetend� sz�ma)
  $self->{UNKNOWN} = ''; # repr: string (ismert-e) e {yes,no}
  $self->{LOC}     = ''; # repr: string (helyhat�roz�) e {to,from}

  bless $self, $class;
}
# XXX minden bels� �rt�k hardk�dolt - j� lesz ez �gy vajon?

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

# --- sz�m�tott dolgok setter-getter-ei
# Ha be van valamire �ll�tva, akkor
# azt adja vissza, �s nem sz�molja ki az "igazit" (!)
# (Be�ll�t�snak tal�n csak Term eset�n van �rtelme)
# XXX XXX XXX ennek ink�bb a parse-ben lenne a helye !?
sub number { # egyeztet�si sz�m == a birtok sz�ma
  my $self = shift;
  my $val = shift;
  if ( defined $val ) { $self->{NUMBER} = $val; }

  if ( $self->{NUMBER} eq '' ) { # ez lenne a default �rt�k XXX
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
    } else {                             # !ana �s !ps
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

  if ( $self->{LOC} eq '' ) { # ez lenne a default �rt�k XXX
    my $loc = '';
    if ( $self->case eq 'ILL' or
         $self->case eq 'ALL' or $self->case eq 'SUB' ) {
      $loc = 'to'; # XXX n�vut�k kezel�se hib�dzik (!)    
    } elsif ( $self->case eq 'ELA' or
              $self->case eq 'ABL' or $self->case eq 'DEL' ) {
      $loc = 'from'; # XXX n�vut�k kezel�se hib�dzik (!)
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
  $x ne ''; # azaz, ha b�rhol b�rmi be van �ll�tva
}
#Ez lehet, hogy bazi lass�, �s jobb lesz a r�gi (de rossz:) XXX
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

  # --- f�n�vi igen�v
  } elsif ( $s =~ m/^(?:(Pre)\.)?V\.IN(F|R..)$/ ) {
    $self->pre( $1 ? 'yes' : 'no' );
    $self->postag( 'INF' );
    my $inf = $2;
    if ( $inf =~ m/R(.)(.)/ ) {
      $self->vnum( $1 eq 'e' ? 'sing' : 'plur' );
      $self->person( $2 );
    }
    $self->unknown( 'no' );

  # --- hat�roz�i igen�v
  } elsif ( $s =~ m/^(?:(Pre)\.)?V\.HIN$/ ) {
    $self->pre( $1 ? 'yes' : 'no' );
    $self->postag( 'HIN' );
    $self->unknown( 'no' );

  # --- n�vsz�
  } elsif ( $s =~ m/^(?:(FF)\.)?($NOMINAL)(?:\.(FOK))?(?:\.(PL))?(?:\.(PS[et][123]i?))?(?:\.(POSi?))?(?:\.(...))?$/ ) {
    $self->postag( $2 );
    $self->tive( $1 ? 'sup' : ( $3 ? 'com' : 'pos' ) );
    # ha van 'FF.' akkor fels� �s figyelmen k�v�l hagyhatom a '.FOK'-ot
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

# ami megv�ltozott (!) - logol�s XXX
if ( $self->as_string ne $ps ) {
  print STDERR "[$ps] " . $self->info;
  print STDERR " -> [" . $self->as_string . "]";
  print STDERR "\n";
}

  $self->ok ? $self : "$Exception::msg Erroneous MSD string [$s].";
}

# param: egy msd-string
# m�k�d: k�t�jeleket �s a vagylagoss�got heurisztik�val kiegyszer�s�ti
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
        # minden esetben az utols�t vessz�k
        # - k�t�jeles sz�n�l ez tal�n mindig j�,
        # - vagylagoss�g eset�n viszont csak m�zli, ha �pp az uts� a j� XXX
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
    } else { # n�vsz�
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
  if ( $str ne $NOTFULL ) {         # ha �rtelmes az as_string
    my $number = $self->number;
    my $loc = $self->loc;
    $info .= $self->as_string .
      # hozz�tessz�k a sz�m�tott attrib�tumokat
      ( $number ? ( '[' . $number . ']' ) : '' ) .
      ( $loc ? ( '[' . $loc . ']' ) : '' );
      #( $number ? ( ',number=[' . $number . ']' ) : '' );
  } else {                          # ha nem �rtelmes az as_string
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

# --- egyebek: a l�nyeg
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

