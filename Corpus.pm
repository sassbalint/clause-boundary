package Corpus;

use strict;

use Object;
our @ISA = ( 'Object' );
use Sentence;

# --- konstr
sub new {
  my $class = shift;
  my $self = {};
  $self->{FILENAME} = ''; # repr: string
  $self->{FORMAT}   = ''; # repr: string e {cqp,vertical}
  $self->{FILE}     = ''; # repr: filehandle typeglob, vagy mi :)
  bless $self, $class;
}

# --- setter-getter-ek
sub filename { shift->_sg( shift, 'FILENAME' ); }
sub format   { shift->_sg( shift, 'FORMAT' ); }
sub file     { shift->_sg( shift, 'FILE' ); }

sub as_string {
  my $self = shift;
  'Corpus. file:' . $self->filename . ' format:' . $self->format;
}

#sub info {
#  my $self = shift;
#  '';
#}

# --- egyebek: a l�nyeg
# param: f�jln�v
#        form�tum (jelenleg 'cqp' vagy 'vertical')
sub open {
  my $self = shift;
  my $fn = shift;
  my $format = shift;
  if ( $fn eq '-' ) {
    $self->filename( 'STDIN' );
    $self->file( *STDIN );
  } else {
    open F, "$fn" or die "Fatal: Corpus [$fn] not exists. ($!)"; # XXX
    $self->filename( $fn );
    $self->file( *F );
  }
  $self->format( $format );
  $self;
}

# m�k�d: visszaadja a korpusz k�vetkez� mondat�t
#        nem ellen�rzi, hogy t�nyleg olyan form�tum�-e a korpusz. TODO
sub next_sentence {
  my $self = shift;
  if ( $self->format eq 'cqp' or $self->format eq 'vertical' ) {
    my $l;
    my $v = '';
    # 'cqp': lehet�s�g van sorok kihagy�s�ra '#'-sel
    if ( $self->format eq 'cqp' ) {
      do {
        $l = readline $self->file; 
      } while ( defined $l and $l =~ /^#/ );
    # 'vertical': �ssze kell gy�jt�getni egy mondat sorait
    } else {
      my $ok = '';
      $l = readline $self->file; 
      while ( defined $l and $l !~ m{</s>} ) {
        if ( $ok and $l =~ /\t/) { $v .= $l; } # TAB == a sor egy sz�t tartalmaz
        if ( $l =~ m/<s[> ]/ ) { $ok = 1; } # <s> persze nem volt j�
        $l = readline $self->file; 
      }
    }
    if ( $l ) {
      # 'cqp' eset�n konvert�l�s vertical form�j�ra
      if ( $self->format eq 'cqp' ) {
          my @a = split /\s+/, $l;
          foreach my $a ( @a ) {
            if ( $a =~ s/^<(.*?)>$/$1/ ) {
              # valahogy tov�bb k�ne adni, hogy MARKED,
              # hogy a Strc->load-ban meg lehessen jel�lni! TODO
            }
            # cqp-s (ak�r nem-egy�rtelm�) perjelek feldolgoz�sa
            my @b = split /\//, $a;
            if ( @b == 3 ) { # leggyakoribb eset
              $v .= "$b[0]\t$b[1]\t$b[2]\n";
            } else { # pl. OS/2/OS/2/UNKNOWNTAG
              my $len = (@b-1)/2;
              my $form = join '/', @b[0..($len-1)];
              my $stem = join '/', @b[$len..(2*$len-1)];
              $v .= "$form\t$stem\t$b[-1]\n";
           }
         }
      }
      # �r�sjelek lev�g�sa a mondat v�g�r�l (minek is?) XXX
#      $v =~ s/\n[^\n]*SPUNCT\n/\n/;
      # k�zi korpusz-jav�t�s
      $v = manual_improve( $v );
      
      my $s = Sentence->new;
      $s->load( $v ); # hibakezel�s? XXX
      $s;
    } else {
      close $self->file;
      undef; # f�jl v�g�t jelzi
    }
  } else {
    "$Exception::msg Bad corpus format [$self->format] " .
    "Can be: 'cqp' or 'vertical'.";
  }
}

sub manual_improve {
  my $s = shift;
  $s =~ s#k�ne\tkell\tV\n#k�ne\tkell\tV.e3\n#g;
  # esetleg: Nincsen/nincsen/V XXX
  # n�vm�sok sz�fajokba rendez�se XXX XXX XXX
  my @fn = (
  #'ez', 'maga'
  #'ugyanaz'
  );
  my @mn = ( 'ilyen' );
  my @sn = ( 'n�h�ny' );
  foreach ( @fn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1N$2#g; }
  foreach ( @mn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1A$2#g; }
  foreach ( @sn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1Num$2#g; }
  $s;
}

1;

