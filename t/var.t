#!./perl
# $Id: var.t,v 1.2 1994/11/12 23:30:28 mbeattie Exp $
BEGIN { push @INC, qw(. .. ../lib ../../lib ../../../lib) }

require Tcl;

print "1..6\n";

sub foo {
    my $interp = $_[1];
    my $glob = $interp->GetVar("bar", $Tcl::GLOBAL_ONLY);
    my $loc = $interp->GetVar("bar");
    print "$glob $loc\n";
    $interp->GlobalEval('puts $four');
}

$i = new Tcl;

$i->SetVar("foo", "ok 1");
$i->Eval('puts $foo');

$i->Eval('set foo "ok 2\n"');
print $i->GetVar("foo");

$i->CreateCommand("foo", \&foo);
$i->Eval(<<'EOT');
set bar ok
set four "ok 4"
proc baz {} {
    set bar 3
    set four "not ok 4"
    foo
}
baz
EOT

$i->Eval('set a(OK) ok; set a(five) 5');
$ok = $i->GetVar2("a", "OK");
$five = $i->GetVar2("a", "five");
print "$ok $five\n";

print defined($i->GetVar("nonesuch")) ? "not ok 6\n" : "ok 6\n";
