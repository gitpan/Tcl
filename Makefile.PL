use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => "Tcl",
    VERSION => "b3",
    LIBS => ["-ltcl -lm"],
    INC => "-I/usr/local/include -I/usr/include/tcl"
);
