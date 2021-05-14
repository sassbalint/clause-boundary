package Rule;

use strict;

use Seq;
our @ISA = ( 'Seq' );
use Type;

# Seq.pm - Token-eket k�vetel meg
# Rule.pm - Term-eket k�vetel meg

# --- konstr
sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->{COMMAND} = ''; # a szab�ly fajt�ja:
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
                  
our $CBEG      = '{';  # term felt�telek nyit�
our $CEND      = '}';  #                 z�r�
our $VARSEP    = '\.'; # alv�ltoz�-elv�laszt�
  our $PVARSEP = '.';  # alv�ltoz�-elv�laszt� ki�r�shoz
our $COMP      = '[=!~]'; # "v�ltoz� $COMP �rt�k"
our $QT        = "'";  # $QT . �rt�k . $QT
our $TYPESEP   = Type->TYPESEP; # alt�pus-elv�laszt�
our $AND       = ';';  # "felt�tel $AND felt�tel"

our $VALOR     = '|';  # �rt�kbeli vagylagoss�g jele 'Laci|Pista' XXX

our $TCHAR     = 'A-Za-z0-9_' . $TYPESEP;
                       # a t�pus ilyen karaktereket tartalmazhat

our $CHAR      = $TCHAR . '������������������';
                       # alap megengedett karakterek
                       # m�r most l�tom, hogy az �kezetekkel baj lesz ... XXX

our $VCHAR     = $CHAR . ',.?!';
                       # �rt�k ilyen karaktereket tartalmazhat


our $TARGET    = '^[' . $TCHAR . $TYPESEP . ']+$'; # target
our $VARSTR    = '^[' . $TCHAR . $PVARSEP . ']+$'; # v�ltoz�n�v
our $VALSTR    = '^[' . $VCHAR . $VALOR .  ']+$';  # �rt�kben mi lehet

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

# --- egyebek: a l�nyeg
# param: -
# seq (felt�lt�se) ut�n kell h�vni (!)
sub autocode {
  my $self = shift;
  my $code = 65; # 'a'-t�l kezd�dik
                 # XXX csak kis- �s nagybet�ket �s sz�mokat szabad engedni
  foreach my $t ( @{ $self->seq } ) {
    $t->code( chr( $code++ ) );
  }
  $self->seq;
}

# param: egy string
# m�k�d: �rtelmezi �s ellen�rzi a stringet,
#        �s felt�lti ez alapj�n a szab�lyt
# XXX a hibaellen�rz�s kicsit sz�rny�, de m�k�dik :)
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

# XXX ide csak "warning" k�ne
#  if ( $command eq $DELETE and @t >= 3 ) {
#    return "$Exception::msg Rule::load - " .
#    "'$F_DELETE' command does not need any terms\n";
#  }

  if ( $command eq $MATCH and @t < 3 ) {
    return "$Exception::msg Rule::load - " .
    "'$F_MATCH' command needs at least one term\n";
  }
  # a '<-' ($MATCH) parancs termjei
  if ( $command eq $MATCH ) { # itt m�r tutira van $t[2]
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
      # hozz�tessz�k a default t�pust, ha nincs t�pus
      $type = Type->DEFAULT_TYPE if not $type; # ha �res
print " TYPE = [$type]\n" if $DEBUG;
$term->type( $type );
$term->comp( '=' );
# XXX hc XXX ideiglenes: alapb�l '=' legyen
# XXX ugyanis, ha nincs benne egy term se,
#     akkor a jelenlegi �llapotban nem der�l ki az �sszehasonl�t�si m�d.

      my $st = parse_cond( $cond, $term );
      if ( Exception::isExc( $st ) ) { return $st; }
      $term = $st; # ha nem hib�t, akkor a termet adja vissza XXX

print " PRE  = [$pre]\n" if $pre and $DEBUG;
      $term->pre( $pre );
print " POST = [$post]\n" if $post and $DEBUG;
      $term->post( $post );

      push @r, $term;
    }

    # eval-os regex-pr�ba, hogy pre �s post legal�bb k�b� stimmel-e
    my $regexp;
    foreach my $te ( @r ) {
      $regexp .= $te->pre . 'a' . $te->post;
    }
    eval { 'aaaa' =~ m/$regexp/; };
    if ( $@ ) {
      my $err = $@;
      $err =~ s/regex; marked by.*$/rule \n$s/;
      return "$Exception::msg $err"; # XXX kb. j� lesz ...
    }

    # minden stimmel: felt�ltj�k adatokkal a szab�lyt
    $self->seq( \@r );
  }  

  # minden stimmel: felt�ltj�k adatokkal a szab�lyt
  $self->type( $target_type );
  $self->command( $command );
print $self->info if $DEBUG;  
}

# param: felt�telek egy stringben
#        egy term, amit fel kell t�lteni a felt�teleknek megfelel�en
# m�k�d: egy term-re vonatkoz� felt�telek feldolgoz�sa
# XXX a hibaellen�rz�s kicsit sz�rny�, de m�k�dik :)
# hasznos k�l�nv�lasztani, mert ez m�shol is kellhet
# ez nem igazi oszt�ly-elj�r�s - nincs is Rule param�tere (!) XXX
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

    # XXX k�v�nt tulajdons�gok be�ll�t�sa ellen�rz�ssel
    # XXX ezt �ltal�nos�tani kell tetsz�leges m�lys�gre
    # XXX v�g�lis csak egy ciklus (!)
    my @var = split /$VARSEP/, $var;
    if ( @var == 1 ) {
      my $v0 = $var[0];
      if ( $term->can( $v0 ) ) {
        $term->$v0( $val );
      } else {
        return "$Exception::msg Rule::load - " .
        "[$var] can't be set in [$cond].\n";
      }
    } else { # @var == 2 - m�lyebb egyel�re nincs XXX
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

