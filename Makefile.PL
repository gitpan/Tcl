use ExtUtils::MakeMaker;
WriteMakefile(LIBS => ["-ltcl -lm"],
	      INC => "-I/usr/local/include -I/usr/include/tcl");
