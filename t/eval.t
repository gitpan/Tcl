#!./perl
# $Id: eval.t,v 1.2 1994/11/12 23:30:28 mbeattie Exp $
BEGIN { push @INC, qw(. .. ../lib ../../lib ../../../lib) }

use Tcl;

print "1..5\n";

$i = new Tcl;
Eval $i q(puts "ok 1");
($a, $b) = Eval $i q(list 2 ok);
print "$b $a\n";
eval { Eval $i q(error "ok 3\n") };
print $@;
call $i ("puts", "ok 4");
EvalFileHandle $i 'DATA';
__END__
set foo ok
set bar 5
puts "$foo $bar"
