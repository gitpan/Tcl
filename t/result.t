#!./perl
# $Id: result.t,v 1.2 1994/11/12 23:30:28 mbeattie Exp $
BEGIN { push @INC, qw(. .. ../lib ../../lib ../../../lib) }

use Tcl;

print "1..5\n";

sub foo {
    my $interp = $_[1];
    $i->SetResult("ok 2");
    return undef;
}

$i = new Tcl;


$i->Eval('expr 10 + 30');
print $i->result == 40 ? "ok 1\n" : "not ok 1\n";

$i->CreateCommand("foo", \&foo);
$i->Eval('if {[catch foo res]} {puts $res} else {puts "not ok 2"}');

$i->ResetResult();
@qlist = qw(a{b  g\h  j{{k}  l}m{   \}n);
foreach (@qlist) {
    $i->AppendElement($_);
}

if ($i->result eq 'a\{b {g\h} j\{\{k\} l\}m\{ {\}n}') {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

@qlistout = $i->SplitList($i->result);
if ("@qlistout" eq "@qlist") {
    print "ok 4\n";
} else {
    print "not ok 4\n";
}

if ($i->SplitList('bad { format')) {
    print "not ok 5\n";
} else {
    print "ok 5\n";
}
