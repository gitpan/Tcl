# before running this script make sure you have 'tclsh' in your path, 
# and this 'tcl' distribution is required one.

open TCLSH, "tclsh tclcfg.tcl |";
my $tclcfg = join '', <TCLSH>;
my %tclcfg = $tclcfg =~ /^(\w+)=(.*?)\n/gm;
my $tclver = $tclcfg{tcl_version};
my $libpref = '';

$tclcfg{tcl_library} =~ /^(.*)[\\\/]lib[\\\/]/;
$tclcfg{libpath} = "-L$1/lib";
$tclcfg{incpath} = "-I$1/include";

if ($^O eq 'MSWin32') {
    $tclver=~s/\.//;
}
else {
    $tclver = '';
}

use ExtUtils::MakeMaker;
#print <<"#EOS";
WriteMakefile(
    NAME => "Tcl",
    VERSION_FROM => 'Tcl.pm',
    LIBS => ["$tclcfg{libpath} -l${libpref}tcl$tclver"],
    INC => "$tclcfg{incpath}",
);

#EOS
