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

# --- egyebek: a lényeg
# param: fájlnév
#        formátum (jelenleg 'cqp' vagy 'vertical')
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

# mûköd: visszaadja a korpusz következõ mondatát
#        nem ellenõrzi, hogy tényleg olyan formátumú-e a korpusz. TODO
sub next_sentence {
  my $self = shift;
  if ( $self->format eq 'cqp' or $self->format eq 'vertical' ) {
    my $l;
    my $v = '';
    # 'cqp': lehetõség van sorok kihagyására '#'-sel
    if ( $self->format eq 'cqp' ) {
      do {
        $l = readline $self->file; 
      } while ( defined $l and $l =~ /^#/ );
    # 'vertical': össze kell gyûjtögetni egy mondat sorait
    } else {
      my $ok = '';
      $l = readline $self->file; 
      while ( defined $l and $l !~ m{</s>} ) {
        if ( $ok and $l =~ /\t/) { $v .= $l; } # TAB == a sor egy szót tartalmaz
        if ( $l =~ m/<s[> ]/ ) { $ok = 1; } # <s> persze nem volt jó
        $l = readline $self->file; 
      }
    }
    if ( $l ) {
      # 'cqp' esetén konvertálás vertical formájúra
      if ( $self->format eq 'cqp' ) {
          my @a = split /\s+/, $l;
          foreach my $a ( @a ) {
            if ( $a =~ s/^<(.*?)>$/$1/ ) {
              # valahogy tovább kéne adni, hogy MARKED,
              # hogy a Strc->load-ban meg lehessen jelölni! TODO
            }
            # cqp-s (akár nem-egyértelmû) perjelek feldolgozása
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
      # írásjelek levágása a mondat végérõl (minek is?) XXX
#      $v =~ s/\n[^\n]*SPUNCT\n/\n/;
      # kézi korpusz-javítás
      $v = manual_improve( $v );
      
      my $s = Sentence->new;
      $s->load( $v ); # hibakezelés? XXX
      $s;
    } else {
      close $self->file;
      undef; # fájl végét jelzi
    }
  } else {
    "$Exception::msg Bad corpus format [$self->format] " .
    "Can be: 'cqp' or 'vertical'.";
  }
}

sub manual_improve {
  my $s = shift;
  $s =~ s#kéne\tkell\tV\n#kéne\tkell\tV.e3\n#g;
  # esetleg: Nincsen/nincsen/V XXX
  # névmások szófajokba rendezése XXX XXX XXX
  my @fn = (
  #'ez', 'maga'
  #'ugyanaz'
  );
  my @mn = ( 'ilyen' );
  my @sn = ( 'néhány' );
  foreach ( @fn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1N$2#g; }
  foreach ( @mn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1A$2#g; }
  foreach ( @sn ) { $s =~ s#(\S+\t$_\t)Pro(\.\S+)#$1Num$2#g; }
  $s;
}

1;

