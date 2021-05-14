#!/usr/bin/perl -w

use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

use strict;
use POSIX;

use POSIX "locale_h";
setlocale ( LC_ALL, "hu_HU" );
use locale;

use File::Basename;
use Getopt::Std;
my $PROG = basename ( $0 );

my %opt;
getopts ( "npc:v:hd", \%opt ) or usage();
usage() if $opt{h} or
  ( not $opt{v} and not $opt{c} ) or
  ( $opt{v} and $opt{c} );

my $DEBUG = ( defined $opt{d} ? 1 : 0 );

# --- program starts HERE
my $NONE = $opt{n} ? 1 : '';

use Corpus;
use Sentence;

my $corpus = Corpus->new;
if ( $opt{v} ) {
  $corpus->open( $opt{v}, 'vertical' );
} else {
  $corpus->open( $opt{c}, 'cqp' );
}

my %VCON_FORM = to_set(
  "amikor amint ahol ahogyan amíg amiképp amiképpen ahova ahová amióta ameddig amerre" ); # kieg: 'ahová'
my %VCON_LEMMA = to_set(
  "aki ami amely amelyik amilyen ahány amennyi mely" );

my $pedig = "pedig akár azonban viszont ellenben mihelyt tehát ugyanis";  
my $nehogy = "nehogy mintha";
my %PEDIG = to_set( $pedig );
my %NEHOGY = to_set( $nehogy );
my %PEDIGNEHOGY = to_set( $pedig . ' ' . $nehogy ); 
my %DE = to_set( "de illetve illetõleg mintegy" );

my %QUE_LEMMA = to_set(
  "ki mi hogyan hol honnan hova hová merre miként mikor miképpen melyik miféle milyen mennyi hány hányadik" ); # hányszor?XXX

my %CH = to_set( ", -" );

# gyakran használt termek
my $CH =  { 'lemma' => \%CH }; # ',' vagy '-'
my $C =  { 'lemma' => ',' }; # ','
# tetszõleges szó (azaz nem írásjel)
# nem túl hatékony, XXX és nem is teljes az írásjelek listája XXX
my $ANY = { 'lemma' => '[^,.;:?!]*' };

# már van egy regexp motor-szerûségem, de most csinálok egy másikat! XXX
# mindig az ELSÕ elem UTÁN teszi be a tagmondathatárt, ha illeszkedik a szabály
# minden term pontosan 1x jelenik meg: '?', '*' nincs!
# itt vannak a szabályok:
my @RULES = (
  # -- én szabályaim

  # pontosvesszõ után MINDIG!
  [ { 'lemma' => ';' } ],

  # kettõspont után MINDIG!
    # XXX GOND: koord. 'meg tudnák adni azoknak a civil szervezeteknek : népkonyháknak , szociális étkezdéknek és segítõ szolgálatoknak a címét'
    # XXX GOND: mûcímek -> egy NE szerzõstül
    # különben egész jó... -> (egyelõre) marad
  [ { 'lemma' => ':' } ],

  # -- Kata féle szabályok

  # 'rule1'
   # NINCS: rule1b (beágyazott mondat vége)
   [ $CH, { 'form'  =>  \%VCON_FORM } ],
   [ $CH, { 'lemma' => \%VCON_LEMMA } ],
   [ $CH, { 'postag'   => 'Adv|Con' }, { 'form'  => \%VCON_FORM } ],
   [ $CH, { 'postag'   => 'Adv|Con' }, { 'lemma' => \%VCON_LEMMA } ],

  # 'rule2a'
   # NINCS: meg (esetleg úgy lehetne, hogy nincs közvetlen mellette ige XXX)
    # XXX GOND: koord. 'az esetek lezáratlanságáért részben a rendõri szervek , részben pedig az ország fõügyészsége , de maga Michal Valo fõügyész is felelõs'
    # ezt vajon Katáék felismerték egy NP-ként? :)
   # NINCS: frázisok, azért nem is kezelem külön a PEDIG-et és a NEHOGY-ot 
    # helyette 1-2-3 ANY szerepel
   [ $CH, { 'form' => \%PEDIGNEHOGY } ],  # nincs
   [ $CH, $ANY, { 'form' => \%PEDIGNEHOGY } ],
   [ $CH, $ANY, $ANY, { 'form' => \%PEDIGNEHOGY } ],
   [ $CH, $ANY, $ANY, $ANY, { 'form' => \%PEDIGNEHOGY } ],
  # 'rule2b'
   # a Con, de nem { DE } szabály - király! :)
   [ $C, { 'postag' => 'Con', 'nolemma' => \%DE } ],

  # 'rule3'
   [ $CH, { 'postag' => 'V', 'tense' => 'past', 'vnum' => 'sing', 'person' => '3' } ],

  # 'rule4' nem kell

  # 'rule5a'
   # GOND: összvissz 2 példa van, és csak az egyik jó :)
   # XXX ez viszont jó:
   # 'A NATO-bõvítés még nem eldöntött kérdés @@ és ezért korai arról beszélni'
   # XXX [ae]zért tutira nem jó -> kihagyom
   # a régi cikkben õk is említik, hogy bárhol (!) lehet!
   # XXX 00_press_nem_100000 -> 11db nem [ae]zért-es példa,
   # és mind rossz (?!) -> az egész szabályt elhagyom
   # [ $ANY, { 'postag' => 'Con', 'nolemma' => '[ae]zért' }, { 'postag' => 'Con' } ],
  # 'rule5b'
   # XXX 00_press_nem_100000 -> 7db példa,
   # és fele rossz / fele kérdéses -> az egész szabályt elhagyom
   # [ $ANY, { 'postag' => 'Con' }, { 'lemma' => \%QUE_LEMMA } ],

  # 'rule6'
   [ $C, { 'lemma' => \%QUE_LEMMA } ], # jónak tûnik
   # XXX alábbira nem volt példa -> elhagyom
   # [ $C, { 'msd' => 'Adv' }, { 'lemma' => \%QUE_LEMMA } ],
   # XXX alábbiak fõleg a 'ki' igekötõre (!) sültek el -> elhagyom
   # [ $C, $ANY, { 'lemma' => \%QUE_LEMMA } ],
   # [ $C, $ANY, $ANY, { 'lemma' => \%QUE_LEMMA } ],
   # [ $C, $ANY, $ANY, $ANY, { 'lemma' => \%QUE_LEMMA } ],

  # 'rule6.5'
   # XXX 00_press_nem_100000 -> 21-bõl 19 (Katáék szerint) jó -> marad!
   # az egy darab egyértelmûen rossz, az egy HIN-koordináció.
   [ $C, { 'postag' => 'HIN' } ],
   [ $C, { 'lemma' => '[ae]z' }, { 'postag' => 'HIN' } ],

);

# végig a mondatokon
while ( my $s = $corpus->next_sentence ) {

  my @output = (); # itt gyûjtjük a tagmondatot
  my $verb_cnt = 0;
  my $con_index = undef;

  # végig a mondat szavain: felbontás központozás mentén
  my @words = @{ $s->seq };
  for ( my $i = 0; $i < @words; ++$i ) {
    my $w = $words[$i];
 
    if ( $w->msd->postag eq 'V' ) {
      # @output <=> van eggyel megelõzõ szó!
      if ( not ( $w->form eq 'volna' and
                 @output and
                 $words[$i-1]->msd->postag eq 'V' ) ) {
        ++$verb_cnt;
      }
    }
    # az akt szó indexe kell, és az pont = az eddigi kimenet méretével
    if ( $w->msd->postag eq 'Con' ) {
      $con_index = @output;
    }
    if ( $w->lemma =~ m/^[,;-]$/ ) { # XXX hardcoded
      $con_index = @output + 1;
      --$con_index if $con_index > $#words; # nehogy túlindexeljen!
    }

    # Katáék féle guesser-szerûség
    # plusz Karesz 3. "consequence"-sze
if ( not $NONE ) {    
    if ( $verb_cnt > 1 ) { # ez mindig 2, ugye?
#print "{{SOK IGE: $verb_cnt}} " if $DEBUG;
#print "{{ez után vagyunk: " . scalar @output . "}} " if $DEBUG;
      if ( not defined $con_index ) {
#print "{{nincs korábbi töréspont}} " if $DEBUG;      
# asszem talán akkor nem kéne törni XXX XXX XXX XXX XXX XXX XXX
      } else {
#print "{{töréspont: $con_index}} " if $DEBUG;
        for ( my $k = 0; $k < $con_index; ++$k ) {
          # kiírjuk + elfelejtjük a töréspontig tartó részt
          my $tmp = shift @output;
          printout( $tmp );
        }
        print "@@" if $DEBUG; # tagm vége jel: '@@'
        print "\n";

      }
      $verb_cnt = 1; # ui. 2 igét vontunk össze eggyé!
      $con_index = undef;
    }
}    

    push @output, $w;

if ( not $NONE ) {
    # végig a szabályokon
    foreach my $r ( @RULES ) {
      my @rule = @{ $r };
      my $boundary = 1;
      if ( $i + $#rule < @words ) { # ha befér a szabály a mondat végéig

        # végig a szabályok termjein
        TERMS:
        for ( my $j = 0; $j < @rule; ++$j ) {

          #my ( $type, $h ) = @{ $rule[$j] };
          my %term = %{ $rule[$j] };

          # végig a term-ben megadott követelményeken
          foreach my $type ( keys %term ) {
            my $h = $term{$type};

            # -- hash-t vagy regesp ptn-t kaptunk?
            my %h = ();
            my $ptn = undef;
            my $is_hash = undef;
            if ( ref( $h ) eq 'HASH') {
              %h = %{ $h }; # a 2. elem vagy egy hash ...
              $is_hash = 1;
            } else {
              $ptn = $h;    # ... vagy pedig egy regexp pattern
              $is_hash = '';
            }

            # -- eltesszük ($thing), hogy mit is kell vizsgálni
            # i+j mert az i. pozíciótól a j. term-et illesztjük
            my $thing = '';
            if ( $type =~ m/lemma$/ ) {
              $thing = $words[$i+$j]->lemma;
            } elsif ( $type =~ m/form$/ ) {
              $thing = $words[$i+$j]->form;
            } elsif ( $type =~ m/postag$/ ) {
              $thing = $words[$i+$j]->msd->postag;
            } elsif ( $type =~ m/tense$/ ) {
              $thing = $words[$i+$j]->msd->tense;
            } elsif ( $type =~ m/vnum$/ ) {
              $thing = $words[$i+$j]->msd->vnum;
            } elsif ( $type =~ m/person$/ ) {
              $thing = $words[$i+$j]->msd->person; # kezd kicsit sok lenni XXX
            }

            # tagadás lehetõsége
            my $yes = 1;
            if ( $type =~ m/^no/ ) { $yes = 0; }

            # -- megvizsgáljuk (hash-ként vagy regexp ptn-ként)
            # ha bármelyik term elbukik -> nincs tagm-határ
            # ez van itten: if ( Y és A vagy nY és nA )
            # lehetne egyszerûbben? XXX
            if ( $is_hash ) {
              if ( $yes ) {
                if ( not exists $h{ $thing } ) { $boundary = ''; last TERMS; }
              } else {
                if ( exists $h{ $thing } ) { $boundary = ''; last TERMS; }
              }
            } else {
              if ( $yes ) {
                if ( $thing !~ m/^$ptn$/ ) { $boundary = ''; last TERMS; }
              } else {
                if ( $thing =~ m/^$ptn$/ ) { $boundary = ''; last TERMS; }
              }
            }
          } # végig egy term követelményein
        } # végig egy szabály termjein

        # ha egy szabállyal találtunk határt, akkor a többi már nem is kell
        if ( $boundary ) {
          # ez 2x van a kódban!
          foreach ( @output ) { printout( $_ ); }
          @output = ();
          $verb_cnt = 0;
          $con_index = undef;

          print "@@" if $DEBUG; # tagm vége jel: '@@'
          print "\n";
          last;
        }
      }
    } # végig a szabályokon
}    
  } # végig a mondat szavain

  # ez 2x van a kódban!
  foreach ( @output ) { printout( $_ ); }
  @output = ();

  print "##" if $DEBUG; # mondatvége jel: '##'
  print "\n"; # mondatvégi tagmondathatár

} # végig a mondatokon

# --- subs
sub printout {
  my $w = shift;
  if ( $opt{p} ) {
    print $w->form . ' ';      # sor végére nem kell space ... XXX
  } else {
    print $w->as_string . ' '; # sor végére nem kell space ... XXX
  }
}

sub to_set {
  my @list = split / /, $_[0];
  my %set = ();
  @set{@list} = (1) x @list; # halmazt <- listából (Perl Cookbook 4.7)
  #foreach ( @list ) { $set{$_} = 1; } # ez nem lehet, hogy gyorsabb? XXX
  return %set;
}

# prints usage info
sub usage {
  print STDERR "Usage: $PROG -v vert | -c cqp [-p] [-d] [-h]\n";
  print STDERR "Clause-determiner. :)\n";
  print STDERR "  -v vert  vertical corpus to process\n";
  print STDERR "  -c cqp   cqp corpus to process\n";
  print STDERR "  -n       no clause-determining, just print\n";
  print STDERR "  -p       plain txt output\n";
  print STDERR "  -d       turns on debugging\n";
  print STDERR "  -h       prints this help message & exit\n";
  exit 1;
}
