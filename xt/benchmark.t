use Mojo::Base -strict;
use Test::More;
use Benchmark qw{cmpthese timethese :hireswallclock};
use Capture::Tiny qw(capture);

my $original = "one\ntwo\nthree\nfour\nfive\nsix\r\n" x 10;
my $regex    = qr/(.*?)(\x0D?\x0A)/;

my $assign = sub {
  my $string = {buffer => $original};
  my $pos    = 0;
  while ( $string->{buffer} =~ m/\G$regex/gs ) {
    $pos = pos($string->{buffer});
  }
  $string->{buffer} = substr($string->{buffer}, $pos);
};

my $assign_fewer_hash = sub {
  my $hash   = {buffer => $original};
  my $string = $hash->{buffer};
  my $pos    = 0;
  while ( $string =~ m/\G$regex/gs ) {
    $pos = pos($string);
  }
  $string = substr($string, $pos);
};

my $assign_forloop = sub {
  my $string = {buffer => $original};
  my $pos;
  for ( $pos = 0 ; $string->{buffer} =~ m/\G$regex/gs ;
        $pos = pos($string->{buffer}) ) {
  }
  $string->{buffer} = substr( $string->{buffer}, $pos );
};

my $assign_string = sub {
  my $hash   = {buffer => ''};
  my $string = $original;
  my $pos    = 0;
  while ( $string =~ m/\G$regex/gs ) {
    $pos = pos($string);
  }
  $string = substr($string, $pos);
};

my $forloop = sub {
  my $string = {buffer => $original};
  my $pos;
  for ( $pos = 0 ; $string->{buffer} =~ m/\G$regex/gs ;
        $pos = pos($string->{buffer}) ) {
  }
  substr( $string->{buffer}, 0, $pos ) = '';
};

my $inplace  = sub {
  my $string = {buffer => $original};
  my $pos    = 0;
  while ( $string->{buffer} =~ m/\G$regex/gs ) {
    $pos = pos($string->{buffer});
  }
  substr( $string->{buffer}, 0, $pos, '' );
};

my $lvalue = sub {
  my $string = {buffer => $original};
  my $pos    = 0;
  while ( $string->{buffer} =~ m/\G$regex/gs ) {
    $pos = pos($string->{buffer});
  }
  substr( $string->{buffer}, 0, $pos ) = '';
};

my $subst = sub {
  my $string = {buffer => $original};
  while ( $string->{buffer} =~ s/^$regex//s ) { }
};

my $stdout = capture {
  cmpthese(timethese(1e5, {
    INPLACE    => $inplace,
    ASSIGN     => $assign,
    LVALUE     => $lvalue,
    FORLOOP    => $forloop,
    SUBSTITUTE => $subst,
    ASSIGN_STR => $assign_string,
    ASSIGN_FOR => $assign_forloop,
    ASSIGN_LESS => $assign_fewer_hash,
  }));
};

diag $stdout;

pass 'benchmark';

done_testing;
