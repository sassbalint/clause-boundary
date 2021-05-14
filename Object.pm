package Object;

use strict;

# --- konstr nincs (!)
# ez a csomag csak az �ltal�nos met�dusokat ad

# --- �ltal�nos egy attrib�tumot megad� setter-getter
sub _sg {
  my $self = shift;
  my $val = shift;
  my $attr = shift;
  if ( defined $val ) { $self->{$attr} = $val; }
  $self->{$attr};
}

# --- �ltal�nos objectlist-attrib�tumot egyben megad� setter-getter
# param: Object-array-ref, attr, methodname, Class
# m�k�d: Object-array-ref-b�l felt�lti az attr t�mb�t,
#        de csak, ha Class oszt�ly� elemekb�l �ll
#        �zenetben, mint methodname eml�ti mag�t
# nem j� a sima _sg, mert az ugye b�rmit megenged
sub _sg_objectlist {
  my $self = shift;
  my $seq = shift;
  my $attr = shift;
  my $method_name = shift;
  my $req_class = shift;
  my $ok = 1;
  if ( defined $seq ) { # azaz ha akarunk �rt�ket adni
    if ( ref( $seq ) ne 'ARRAY' ) {
      $ok = '';
    } else {
      for ( my $i = 0; $i < @{ $seq }; ++$i ) {
        my $x = ${ $seq }[$i];
        $ok = '' if not $x->isa( $req_class );
      }
    }
  }
  $ok
    ? $self->_sg( $seq, $attr )
    : "$Exception::msg " . ref( $self ) .
      "::$method_name requires a $req_class-array-ref.";
}

# --- �ltal�nos objectlist-attrib�tumot egy elemmel megtold� setter
# param: Object, attr, methodname, Class
# m�k�d: Object-et beteszi az attr t�mb v�g�re,
#        de csak, ha Class oszt�ly�
#        �zenetben, mint methodname eml�ti mag�t
sub _sg_add_objectlistelem {
# XXX ez duplik�lt k�d - kiv�lthat� egy _sg_arr_add_objectlistelem h�v�ssal
# XXX nem �rtem, hogy ez a 3 sor itt mi�rt nem stimmel
#  my $self = shift;
#  $self->_sg_arr_add_objectlistelem(
#    shift, $self->{shift}, shift, shift );
#  # ugye sima t�mbref helyett itt
#  # az attrib�tum �ltal megadott t�mbrefet adn�k meg
  my $self = shift;
  my $obj = shift;
  my $attr = shift;
  my $method_name = shift;
  my $req_class = shift;
  $obj->isa( $req_class )
    ? push ( @{ $self->{$attr} }, $obj )
    : "$Exception::msg " . ref( $self ) . 
      "::$method_name requires a $req_class.";
}

# --- �ltal�nos t�mbh�z hozz�ad� setter
# param: Object, arr (t�mbref), methodname, Class
# m�k�d: Object-et beteszi az @{arr} t�mb v�g�re,
#        de csak, ha Class oszt�ly�
#        �zenetben, mint methodname eml�ti mag�t
sub _sg_arr_add_objectlistelem {
  my $self = shift;
  my $obj = shift;
  my $arr = shift;
  my $method_name = shift;
  my $req_class = shift;
  $obj->isa( $req_class )
    ? push ( @{ $arr }, $obj )
    : "$Exception::msg " . ref( $self ) . 
      "::$method_name requires a $req_class.";
}

sub _isinteger {
  my $self = shift;
  ( shift =~ m/^[0-9]+$/ );
}

1;

