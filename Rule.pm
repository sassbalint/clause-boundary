package Rule;

use strict;

use Seq;
our @ISA = ( 'Seq' );
use Type;

# Seq.pm - Token-eket követel meg
# Rule.pm - Term-eket követel meg

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{COMMAND} = ''; # a szabály fajtája:
                         # jelenleg 'regexpmatch' vagy 'delete' XXX
  bless ($self, $class);
}

# --- konstansok
my $DEBUG = '';

our $F_MATCH   = '<-';
our $F_DELETE  = '@delete';
our $MATCH     = 'MATCH';
our $DELETE    = 'DELETE';
our %COMMAND   = ( $F_MATCH => $MATCH, $F_DELETE => $DELETE );
                       # "target <- termek" vagy "target @delete"
                  
our $CBEG      = '{';  # term feltételek nyitó
our $CEND      = '}';  #                 záró
our $VARSEP    = '\.'; # alváltozó-elválasztó
  our $PVARSEP = '.';  # alváltozó-elválasztó kiíráshoz
our $COMP      = '[=!~]'; # "változó $COMP érték"
our $QT        = "'";  # $QT . érték . $QT
our $TYPESEP   = Type->TYPESEP; # altípus-elválasztó
our $AND       = ';';  # "feltétel $AND feltétel"

our $VALOR     = '|';  # értékbeli vagylagosság jele 'Laci|Pista' XXX

our $TCHAR     = 'A-Za-z0-9_' . $TYPESEP;
                       # a típus ilyen karaktereket tartalmazhat

our $CHAR      = $TCHAR . 'áéíóöõúüûÁÉÍÓÖÕÚÜÛ';
                       # alap megengedett karakterek
                       # már most látom, hogy az ékezetekkel baj lesz ... XXX

our $VCHAR     = $CHAR . ',.?!';
                       # érték ilyen karaktereket tartalmazhat


our $TARGET    = '^[' . $TCHAR . $TYPESEP . ']+$'; # target
our $VARSTR    = '^[' . $TCHAR . $PVARSEP . ']+$'; # változónév
our $VALSTR    = '^[' . $VCHAR . $VALOR .  ']+$';  # értékben mi lehet

our $NO_TCHAR  = _no_ptn( $TCHAR );
our $NO_CBEG   = _no_ptn( $CBEG );
our $NO_CEND   = _no_ptn( $CEND );
our $NO_COMP   = _no_ptn( _remove_brack( $COMP ) );
our $NO_QT     = _no_ptn( $QT );

sub _no_ptn {
  '[^' . $_[0] . ']';
}
sub _remove_brack {
  my $s = $_[0];
  $s =~ s/^\[//g; $s =~ s/\]$//g;
  $s;
}

# --- setter-gettek-ek
sub command {  shift->_sg( shift, 'COMMAND' ); }
sub seq {
  shift->_sg_objectlist( shift, 'SEQ', 'seq', 'Term' );
}

sub info {
  my $self = shift;
  $self->SUPER::info . " COMMAND: '" . $self->command . "'";
}

# --- egyebek: a lényeg
# param: -
# seq (feltöltése) után kell hívni (!)
sub autocode {
  my $self = shift;
  my $code = 65; # 'a'-tól kezdõdik
                 # XXX csak kis- és nagybetûket és számokat szabad engedni
  foreach my $t ( @{ $self->seq } ) {
    $t->code( chr( $code++ ) );
  }
  $self->seq;
}

# param: egy string
# mûköd: értelmezi és ellenõrzi a stringet,
#        és feltölti ez alapján a szabályt
# XXX a hibaellenõrzés kicsit szörnyû, de mûködik :)
sub load {
  my $self = shift;
  my $s = shift;

print "\n[$s]\n\n" if $DEBUG;

  my $target_type;
  my $command;
  my @r = ();

  my ( @t ) = split /\s+/, $s;

  if ( @t < 2 ) {
    return "$Exception::msg Rule::load - " .
    "We need a target-type then a command [" .
    ( join ',', keys %COMMAND ) . "]\n";
  }

  # "target"
  {
    my $t = $t[0];
    if ( $t !~ m#$TARGET# ) {
      return "$Exception::msg Rule::load - " .
      "Target [$t] can contain only [" .
      $TCHAR . "] and [". $TYPESEP ."]\n";
    }
print "TARG    [$t]\n" if $DEBUG;
$target_type = $t;
  }

  # "command"
  {
    my $t = $t[1];
    if ( not exists $COMMAND{$t} ) {
      return "$Exception::msg Rule::load - " .
      "2nd token [$t] must be a command [" .
      ( join ',', keys %COMMAND ) . "]\n";
    }
$command = $COMMAND{$t};
  }

# XXX ide csak "warning" kéne
#  if ( $command eq $DELETE and @t >= 3 ) {
#    return "$Exception::msg Rule::load - " .
#    "'$F_DELETE' command does not need any terms\n";
#  }

  if ( $command eq $MATCH and @t < 3 ) {
    return "$Exception::msg Rule::load - " .
    "'$F_MATCH' command needs at least one term\n";
  }
  # a '<-' ($MATCH) parancs termjei
  if ( $command eq $MATCH ) { # itt már tutira van $t[2]
    for ( my $i = 2; $i < @t; ++$i ) {
      my $t = $t[$i];

print "TERM    [$t]\n" if $DEBUG;
my $term = Term->new;
      my ( $pre, $type, $cond, $post ) =
        $t =~ m/^($NO_TCHAR*)([$TCHAR]*)$CBEG($NO_CEND*)$CEND(.*)$/;
      if ( not defined $cond or not defined $type ) {
        return "$Exception::msg Rule::load - " .
        "Term [$t] format must be [type" . $CBEG . "conditions" . $CEND . "]\n";
      }
      # hozzátesszük a default típust, ha nincs típus
      $type = Type->DEFAULT_TYPE if not $type; # ha üres
print " TYPE = [$type]\n" if $DEBUG;
$term->type( $type );
$term->comp( '=' );
# XXX hc XXX ideiglenes: alapból '=' legyen
# XXX ugyanis, ha nincs benne egy term se,
#     akkor a jelenlegi állapotban nem derül ki az összehasonlítási mód.

      my $st = parse_cond( $cond, $term );
      if ( Exception::isExc( $st ) ) { return $st; }
      $term = $st; # ha nem hibát, akkor a termet adja vissza XXX

print " PRE  = [$pre]\n" if $pre and $DEBUG;
      $term->pre( $pre );
print " POST = [$post]\n" if $post and $DEBUG;
      $term->post( $post );

      push @r, $term;
    }

    # eval-os regex-próba, hogy pre és post legalább kábé stimmel-e
    my $regexp;
    foreach my $te ( @r ) {
      $regexp .= $te->pre . 'a' . $te->post;
    }
    eval { 'aaaa' =~ m/$regexp/; };
    if ( $@ ) {
      my $err = $@;
      $err =~ s/regex; marked by.*$/rule \n$s/;
      return "$Exception::msg $err"; # XXX kb. jó lesz ...
    }

    # minden stimmel: feltöltjük adatokkal a szabályt
    $self->seq( \@r );
  }  

  # minden stimmel: feltöltjük adatokkal a szabályt
  $self->type( $target_type );
  $self->command( $command );
print $self->info if $DEBUG;  
}

# param: feltételek egy stringben
#        egy term, amit fel kell tölteni a feltételeknek megfelelõen
# mûköd: egy term-re vonatkozó feltételek feldolgozása
# XXX a hibaellenõrzés kicsit szörnyû, de mûködik :)
# hasznos különválasztani, mert ez máshol is kellhet
# ez nem igazi osztály-eljárás - nincs is Rule paramétere (!) XXX
sub parse_cond {
  my $cond = shift;
  my $term = shift;
  my @cond = split /$AND/, $cond;
  foreach my $cond ( @cond ) {
print " COND = [$cond]\n" if $DEBUG;
    my ( $var, $comp, $val ) = $cond =~ m/^($NO_COMP+)($COMP)$QT($NO_QT+)$QT$/;
    if ( not defined $var or not defined $val ) {
      return "$Exception::msg Rule::load - " .
      "Condition [$cond] format must be [var(" . $PVARSEP . "subvar)[" .
      $COMP . ']' . $QT . "value" . $QT . "]\n";
    }
print "  VAR = [$var]\n" if $DEBUG;
    if ( $var !~ m#$VARSTR# ) {
      return "$Exception::msg Rule::load - " .
      "Variable [$var] can contain only [" .
      $TCHAR . "] and [". $PVARSEP ."]\n";
    }
print " COMP = [$comp]\n" if $DEBUG;
$term->comp( $comp );
print "  VAL = [$val]\n" if $DEBUG;
    if ( $val !~ m#^$VALSTR# ) {
      return "$Exception::msg Rule::load - " .
      "Value [$val] can contain only [" .
      $VCHAR . "] and [". $VALOR ."]\n";
    }

    # XXX kívánt tulajdonságok beállítása ellenõrzéssel
    # XXX ezt általánosítani kell tetszõleges mélységre
    # XXX végülis csak egy ciklus (!)
    my @var = split /$VARSEP/, $var;
    if ( @var == 1 ) {
      my $v0 = $var[0];
      if ( $term->can( $v0 ) ) {
        $term->$v0( $val );
      } else {
        return "$Exception::msg Rule::load - " .
        "[$var] can't be set in [$cond].\n";
      }
    } else { # @var == 2 - mélyebb egyelõre nincs XXX
      my $v0 = $var[0];
      my $v1 = $var[1];
      if ( $term->can( $v0 ) and $term->$v0->can( $v1 ) ) {
        $term->$v0->$v1( $val );
      } else {
        return "$Exception::msg Rule::load - " .
        "[$var] can't be set in [$cond].\n";
      }
    }

  }
  $term;
}

1;

