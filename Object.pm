package Object;

use strict;

# --- konstr nincs (!)
# ez a csomag csak az általános metódusokat ad

# --- általános egy attribútumot megadó setter-getter
sub _sg {
  my $self = shift;
  my $val = shift;
  my $attr = shift;
  if ( defined $val ) { $self->{$attr} = $val; }
  $self->{$attr};
}

# --- általános objectlist-attribútumot egyben megadó setter-getter
# param: Object-array-ref, attr, methodname, Class
# mûköd: Object-array-ref-bõl feltölti az attr tömböt,
#        de csak, ha Class osztályú elemekbõl áll
#        üzenetben, mint methodname említi magát
# nem jó a sima _sg, mert az ugye bármit megenged
sub _sg_objectlist {
  my $self = shift;
  my $seq = shift;
  my $attr = shift;
  my $method_name = shift;
  my $req_class = shift;
  my $ok = 1;
  if ( defined $seq ) { # azaz ha akarunk értéket adni
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

# --- általános objectlist-attribútumot egy elemmel megtoldó setter
# param: Object, attr, methodname, Class
# mûköd: Object-et beteszi az attr tömb végére,
#        de csak, ha Class osztályú
#        üzenetben, mint methodname említi magát
sub _sg_add_objectlistelem {
# XXX ez duplikált kód - kiváltható egy _sg_arr_add_objectlistelem hívással
# XXX nem értem, hogy ez a 3 sor itt miért nem stimmel
#  my $self = shift;
#  $self->_sg_arr_add_objectlistelem(
#    shift, $self->{shift}, shift, shift );
#  # ugye sima tömbref helyett itt
#  # az attribútum által megadott tömbrefet adnék meg
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

# --- általános tömbhöz hozzáadó setter
# param: Object, arr (tömbref), methodname, Class
# mûköd: Object-et beteszi az @{arr} tömb végére,
#        de csak, ha Class osztályú
#        üzenetben, mint methodname említi magát
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

