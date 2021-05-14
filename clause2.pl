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
  "amikor amint ahol ahogyan am�g amik�pp amik�ppen ahova ahov� ami�ta ameddig amerre" ); # kieg: 'ahov�'
my %VCON_LEMMA = to_set(
  "aki ami amely amelyik amilyen ah�ny amennyi mely" );

my $pedig = "pedig ak�r azonban viszont ellenben mihelyt teh�t ugyanis";  
my $nehogy = "nehogy mintha";
my %PEDIG = to_set( $pedig );
my %NEHOGY = to_set( $nehogy );
my %PEDIGNEHOGY = to_set( $pedig . ' ' . $nehogy ); 
my %DE = to_set( "de illetve illet�leg mintegy" );

my %QUE_LEMMA = to_set(
  "ki mi hogyan hol honnan hova hov� merre mik�nt mikor mik�ppen melyik mif�le milyen mennyi h�ny h�nyadik" ); # h�nyszor?XXX

my %CH = to_set( ", -" );

# gyakran haszn�lt termek
my $CH =  { 'lemma' => \%CH }; # ',' vagy '-'
my $C =  { 'lemma' => ',' }; # ','
# tetsz�leges sz� (azaz nem �r�sjel)
# nem t�l hat�kony, XXX �s nem is teljes az �r�sjelek list�ja XXX
my $ANY = { 'lemma' => '[^,.;:?!]*' };

# m�r van egy regexp motor-szer�s�gem, de most csin�lok egy m�sikat! XXX
# mindig az ELS� elem UT�N teszi be a tagmondathat�rt, ha illeszkedik a szab�ly
# minden term pontosan 1x jelenik meg: '?', '*' nincs!
# itt vannak a szab�lyok:
my @RULES = (
  # -- �n szab�lyaim

  # pontosvessz� ut�n MINDIG!
  [ { 'lemma' => ';' } ],

  # kett�spont ut�n MINDIG!
    # XXX GOND: koord. 'meg tudn�k adni azoknak a civil szervezeteknek : n�pkonyh�knak , szoci�lis �tkezd�knek �s seg�t� szolg�latoknak a c�m�t'
    # XXX GOND: m�c�mek -> egy NE szerz�st�l
    # k�l�nben eg�sz j�... -> (egyel�re) marad
  [ { 'lemma' => ':' } ],

  # -- Kata f�le szab�lyok

  # 'rule1'
   # NINCS: rule1b (be�gyazott mondat v�ge)
   [ $CH, { 'form'  =>  \%VCON_FORM } ],
   [ $CH, { 'lemma' => \%VCON_LEMMA } ],
   [ $CH, { 'postag'   => 'Adv|Con' }, { 'form'  => \%VCON_FORM } ],
   [ $CH, { 'postag'   => 'Adv|Con' }, { 'lemma' => \%VCON_LEMMA } ],

  # 'rule2a'
   # NINCS: meg (esetleg �gy lehetne, hogy nincs k�zvetlen mellette ige XXX)
    # XXX GOND: koord. 'az esetek lez�ratlans�g��rt r�szben a rend�ri szervek , r�szben pedig az orsz�g f��gy�szs�ge , de maga Michal Valo f��gy�sz is felel�s'
    # ezt vajon Kat��k felismert�k egy NP-k�nt? :)
   # NINCS: fr�zisok, az�rt nem is kezelem k�l�n a PEDIG-et �s a NEHOGY-ot 
    # helyette 1-2-3 ANY szerepel
   [ $CH, { 'form' => \%PEDIGNEHOGY } ],  # nincs
   [ $CH, $ANY, { 'form' => \%PEDIGNEHOGY } ],
   [ $CH, $ANY, $ANY, { 'form' => \%PEDIGNEHOGY } ],
   [ $CH, $ANY, $ANY, $ANY, { 'form' => \%PEDIGNEHOGY } ],
  # 'rule2b'
   # a Con, de nem { DE } szab�ly - kir�ly! :)
   [ $C, { 'postag' => 'Con', 'nolemma' => \%DE } ],

  # 'rule3'
   [ $CH, { 'postag' => 'V', 'tense' => 'past', 'vnum' => 'sing', 'person' => '3' } ],

  # 'rule4' nem kell

  # 'rule5a'
   # GOND: �sszvissz 2 p�lda van, �s csak az egyik j� :)
   # XXX ez viszont j�:
   # 'A NATO-b�v�t�s m�g nem eld�nt�tt k�rd�s @@ �s ez�rt korai arr�l besz�lni'
   # XXX [ae]z�rt tutira nem j� -> kihagyom
   # a r�gi cikkben �k is eml�tik, hogy b�rhol (!) lehet!
   # XXX 00_press_nem_100000 -> 11db nem [ae]z�rt-es p�lda,
   # �s mind rossz (?!) -> az eg�sz szab�lyt elhagyom
   # [ $ANY, { 'postag' => 'Con', 'nolemma' => '[ae]z�rt' }, { 'postag' => 'Con' } ],
  # 'rule5b'
   # XXX 00_press_nem_100000 -> 7db p�lda,
   # �s fele rossz / fele k�rd�ses -> az eg�sz szab�lyt elhagyom
   # [ $ANY, { 'postag' => 'Con' }, { 'lemma' => \%QUE_LEMMA } ],

  # 'rule6'
   [ $C, { 'lemma' => \%QUE_LEMMA } ], # j�nak t�nik
   # XXX al�bbira nem volt p�lda -> elhagyom
   # [ $C, { 'msd' => 'Adv' }, { 'lemma' => \%QUE_LEMMA } ],
   # XXX al�bbiak f�leg a 'ki' igek�t�re (!) s�ltek el -> elhagyom
   # [ $C, $ANY, { 'lemma' => \%QUE_LEMMA } ],
   # [ $C, $ANY, $ANY, { 'lemma' => \%QUE_LEMMA } ],
   # [ $C, $ANY, $ANY, $ANY, { 'lemma' => \%QUE_LEMMA } ],

  # 'rule6.5'
   # XXX 00_press_nem_100000 -> 21-b�l 19 (Kat��k szerint) j� -> marad!
   # az egy darab egy�rtelm�en rossz, az egy HIN-koordin�ci�.
   [ $C, { 'postag' => 'HIN' } ],
   [ $C, { 'lemma' => '[ae]z' }, { 'postag' => 'HIN' } ],

);

# v�gig a mondatokon
while ( my $s = $corpus->next_sentence ) {

  my @output = (); # itt gy�jtj�k a tagmondatot
  my $verb_cnt = 0;
  my $con_index = undef;

  # v�gig a mondat szavain: felbont�s k�zpontoz�s ment�n
  my @words = @{ $s->seq };
  for ( my $i = 0; $i < @words; ++$i ) {
    my $w = $words[$i];
 
    if ( $w->msd->postag eq 'V' ) {
      # @output <=> van eggyel megel�z� sz�!
      if ( not ( $w->form eq 'volna' and
                 @output and
                 $words[$i-1]->msd->postag eq 'V' ) ) {
        ++$verb_cnt;
      }
    }
    # az akt sz� indexe kell, �s az pont = az eddigi kimenet m�ret�vel
    if ( $w->msd->postag eq 'Con' ) {
      $con_index = @output;
    }
    if ( $w->lemma =~ m/^[,;-]$/ ) { # XXX hardcoded
      $con_index = @output + 1;
      --$con_index if $con_index > $#words; # nehogy t�lindexeljen!
    }

    # Kat��k f�le guesser-szer�s�g
    # plusz Karesz 3. "consequence"-sze
if ( not $NONE ) {    
    if ( $verb_cnt > 1 ) { # ez mindig 2, ugye?
#print "{{SOK IGE: $verb_cnt}} " if $DEBUG;
#print "{{ez ut�n vagyunk: " . scalar @output . "}} " if $DEBUG;
      if ( not defined $con_index ) {
#print "{{nincs kor�bbi t�r�spont}} " if $DEBUG;      
# asszem tal�n akkor nem k�ne t�rni XXX XXX XXX XXX XXX XXX XXX
      } else {
#print "{{t�r�spont: $con_index}} " if $DEBUG;
        for ( my $k = 0; $k < $con_index; ++$k ) {
          # ki�rjuk + elfelejtj�k a t�r�spontig tart� r�szt
          my $tmp = shift @output;
          printout( $tmp );
        }
        print "@@" if $DEBUG; # tagm v�ge jel: '@@'
        print "\n";

      }
      $verb_cnt = 1; # ui. 2 ig�t vontunk �ssze eggy�!
      $con_index = undef;
    }
}    

    push @output, $w;

if ( not $NONE ) {
    # v�gig a szab�lyokon
    foreach my $r ( @RULES ) {
      my @rule = @{ $r };
      my $boundary = 1;
      if ( $i + $#rule < @words ) { # ha bef�r a szab�ly a mondat v�g�ig

        # v�gig a szab�lyok termjein
        TERMS:
        for ( my $j = 0; $j < @rule; ++$j ) {

          #my ( $type, $h ) = @{ $rule[$j] };
          my %term = %{ $rule[$j] };

          # v�gig a term-ben megadott k�vetelm�nyeken
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

            # -- eltessz�k ($thing), hogy mit is kell vizsg�lni
            # i+j mert az i. poz�ci�t�l a j. term-et illesztj�k
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

            # tagad�s lehet�s�ge
            my $yes = 1;
            if ( $type =~ m/^no/ ) { $yes = 0; }

            # -- megvizsg�ljuk (hash-k�nt vagy regexp ptn-k�nt)
            # ha b�rmelyik term elbukik -> nincs tagm-hat�r
            # ez van itten: if ( Y �s A vagy nY �s nA )
            # lehetne egyszer�bben? XXX
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
          } # v�gig egy term k�vetelm�nyein
        } # v�gig egy szab�ly termjein

        # ha egy szab�llyal tal�ltunk hat�rt, akkor a t�bbi m�r nem is kell
        if ( $boundary ) {
          # ez 2x van a k�dban!
          foreach ( @output ) { printout( $_ ); }
          @output = ();
          $verb_cnt = 0;
          $con_index = undef;

          print "@@" if $DEBUG; # tagm v�ge jel: '@@'
          print "\n";
          last;
        }
      }
    } # v�gig a szab�lyokon
}    
  } # v�gig a mondat szavain

  # ez 2x van a k�dban!
  foreach ( @output ) { printout( $_ ); }
  @output = ();

  print "##" if $DEBUG; # mondatv�ge jel: '##'
  print "\n"; # mondatv�gi tagmondathat�r

} # v�gig a mondatokon

# --- subs
sub printout {
  my $w = shift;
  if ( $opt{p} ) {
    print $w->form . ' ';      # sor v�g�re nem kell space ... XXX
  } else {
    print $w->as_string . ' '; # sor v�g�re nem kell space ... XXX
  }
}

sub to_set {
  my @list = split / /, $_[0];
  my %set = ();
  @set{@list} = (1) x @list; # halmazt <- list�b�l (Perl Cookbook 4.7)
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
