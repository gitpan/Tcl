#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <tcl.h>

#define Tcl_new(class) Tcl_CreateInterp()
#define Tcl_result(interp) interp->result
#define Tcl_DESTROY(interp) Tcl_DeleteInterp(interp)

typedef Tcl_Interp *Tcl;
typedef AV *Tcl__Var;

static int findexecutable_called = 0;

int Tcl_PerlCallWrapper(clientData, interp, argc, argv)
ClientData clientData;
Tcl_Interp *interp;
int argc;
char **argv;
{
    dSP;
    AV *av = (AV *) clientData;
    I32 count;
    SV *sv;
    int rc;

    /*
     * av = [$perlsub, $realclientdata, $interp, $deleteProc]
     * (where $deleteProc is optional but we don't need it here anyway)
     */

    if (AvFILL(av) != 2 && AvFILL(av) != 3)
	croak("bad clientdata argument passed to Tcl_PerlCallWrapper");

    ENTER;
    SAVETMPS;

    PUSHMARK(sp);
    EXTEND(sp, argc + 2);
    PUSHs(sv_mortalcopy(*av_fetch(av, 1, FALSE)));
    PUSHs(sv_mortalcopy(*av_fetch(av, 2, FALSE)));
    while (argc--)
	PUSHs(sv_2mortal(newSVpv(*argv++, 0)));
    PUTBACK;
    count = perl_call_sv(*av_fetch(av, 0, FALSE), G_SCALAR);
    SPAGAIN;
    if (count != 1)
	croak("perl sub bound to Tcl proc didn't return exactly 1 argument");

    sv = POPs;
    PUTBACK;
    
    rc = SvOK(sv) ? TCL_OK : TCL_ERROR;
    if (rc == TCL_OK)
	Tcl_SetResult(interp, SvPV(sv, PL_na), TCL_VOLATILE);
    /*
     * If the routine returned undef, it indicates that it has done the
     * SetResult itself and that we should return TCL_ERROR
     */

    FREETMPS;
    LEAVE;
    return rc;
}

void
Tcl_PerlCallDeleteProc(clientData)
ClientData clientData;
{
    AV *av = (AV *) clientData;
    
    /*
     * av = [$perlsub, $realclientdata, $interp, $deleteProc]
     * (where $deleteProc is optional but we don't need it here anyway)
     */

    if (AvFILL(av) == 3)
    {
	dSP;

	PUSHMARK(sp);
	EXTEND(sp, 1);
	PUSHs(sv_mortalcopy(*av_fetch(av, 1, FALSE)));
	PUTBACK;
	(void) perl_call_sv(*av_fetch(av, 3, FALSE), G_SCALAR|G_DISCARD);
    }
    else if (AvFILL(av) != 2)
	croak("bad clientdata argument passed to Tcl_PerlCallDeleteProc");

    SvREFCNT_dec((AV *) clientData);
}

void
prepare_Tcl_result(interp, caller)
Tcl interp;
char *caller;
{
    dSP;
    int argc;
    char **argv, **tofree;
    
    if (!GIMME)
	PUSHs(sv_2mortal(newSVpv(interp->result, 0)));
    else
    {
	if (Tcl_SplitList(interp, interp->result, &argc, &argv) != TCL_OK)
	    croak("%s called in list context did not return a valid Tcl list",
		  caller);
	
	tofree = argv;
	EXTEND(sp, argc);
	while (argc--)
	    PUSHs(sv_2mortal(newSVpv(*argv++, 0)));
	ckfree((char *) tofree);
    }
    PUTBACK;
    return;
}

MODULE = Tcl	PACKAGE = Tcl	PREFIX = Tcl_

Tcl
Tcl_new(class = "Tcl")
	char *	class

char *
Tcl_result(interp)
	Tcl	interp

void
Tcl_Eval(interp, script)
	Tcl	interp
	SV *	script
	SV *	interpsv = ST(0);
    PPCODE:
	(void) sv_2mortal(SvREFCNT_inc(interpsv));
	PUTBACK;
	Tcl_ResetResult(interp);
	if (Tcl_Eval(interp, SvPV(sv_mortalcopy(script), PL_na)) != TCL_OK)
	    croak(interp->result);
	prepare_Tcl_result(interp, "Tcl::Eval");
	SPAGAIN;

void
Tcl_EvalFile(interp, filename)
	Tcl	interp
	char *	filename
	SV *	interpsv = ST(0);
    PPCODE:
	(void) sv_2mortal(SvREFCNT_inc(interpsv));
	PUTBACK;
	Tcl_ResetResult(interp);
	if (Tcl_EvalFile(interp, filename) != TCL_OK)
	    croak(interp->result);
	prepare_Tcl_result(interp, "Tcl::EvalFile");
	SPAGAIN;

void
Tcl_GlobalEval(interp, script)
	Tcl	interp
	SV *	script
	SV *	interpsv = ST(0);
    PPCODE:
	(void) sv_2mortal(SvREFCNT_inc(interpsv));
	PUTBACK;
	Tcl_ResetResult(interp);
	if (Tcl_GlobalEval(interp, SvPV(sv_mortalcopy(script), PL_na)) != TCL_OK)
	    croak(interp->result);
	prepare_Tcl_result(interp, "Tcl::GlobalEval");
	SPAGAIN;

void
Tcl_EvalFileHandle(interp, handle)
	Tcl	interp
	FILE *handle
	int	append = 0;
	SV *	interpsv = ST(0);
	SV *	sv = sv_newmortal();
	char *	s = NO_INIT
    PPCODE:
	(void) sv_2mortal(SvREFCNT_inc(interpsv));
	PUTBACK;
        while (s = sv_gets(sv, handle, append))
	{
            if (!Tcl_CommandComplete(s))
		append = 1;
	    else
	    {
		Tcl_ResetResult(interp);
		if (Tcl_Eval(interp, s) != TCL_OK)
		    croak(interp->result);
		append = 0;
	    }
	}
	if (append)
	    croak("unexpected end of file in Tcl::EvalFileHandle");
	prepare_Tcl_result(interp, "Tcl::EvalFileHandle");
	SPAGAIN;

void
Tcl_icall(interp, proc, ...)
	Tcl		interp
	SV *		proc
	Tcl_CmdInfo	cmdinfo = NO_INIT
	int		i = NO_INIT
	static char **	argv = NO_INIT
	static int	argv_cursize = 0;
    PPCODE:
	if (argv_cursize == 0)
	{
	    argv_cursize = (items < 16) ? 16 : items;
	    New(666, argv, argv_cursize, char *);
	}
	else if (argv_cursize < items)
	{
	    argv_cursize = items;
	    Renew(argv, argv_cursize, char *);
	}
	SP++;			/* bypass the interp argument */
	for (i = 0; i < items - 1; i++)
	{
	    /*
	     * Use proc as a spare SV* variable: macro SvPV evaluates
	     * its arguments more than once.
	     */
	    proc = sv_mortalcopy(*++SP);
	    argv[i] = SvPV(proc, PL_na);
	}
	argv[items - 1] = (char *) 0;
	if (!Tcl_GetCommandInfo(interp, argv[0], &cmdinfo))
	    croak("Tcl procedure not found");
	SP -= items;
	PUTBACK;
	Tcl_ResetResult(interp);
	if ((*cmdinfo.proc)(cmdinfo.clientData,interp,items-1, argv) != TCL_OK)
	    croak(interp->result);
	prepare_Tcl_result(interp, "Tcl::call");
	SPAGAIN;

void
Tcl_DESTROY(interp)
	Tcl	interp

void
Tcl_Init(interp)
	Tcl	interp
    CODE:
    	if (!findexecutable_called) {
	    Tcl_FindExecutable("."); /* TODO (?) place here $^X ? */
	}
	if (Tcl_Init(interp) != TCL_OK)
	    croak(interp->result);

void
Tcl_CreateCommand(interp,cmdName,cmdProc,clientData=&PL_sv_undef,deleteProc=Nullsv)
	Tcl	interp
	char *	cmdName
	SV *	cmdProc
	SV *	clientData
	SV *	deleteProc
    CODE:
	if (SvIOK(cmdProc))
	    Tcl_CreateCommand(interp, cmdName, (Tcl_CmdProc *) SvIV(cmdProc),
			      (ClientData) SvIV(clientData), NULL);
	else
	{
	    AV *av = (AV *) SvREFCNT_inc((SV *) newAV());
	    av_store(av, 0, newSVsv(cmdProc));
	    av_store(av, 1, newSVsv(clientData));
	    av_store(av, 2, newSVsv(ST(0)));
	    if (deleteProc)
		av_store(av, 3, newSVsv(deleteProc));
	    Tcl_CreateCommand(interp, cmdName, Tcl_PerlCallWrapper,
			      (ClientData) av, Tcl_PerlCallDeleteProc);
	}
	ST(0) = &PL_sv_yes;
	XSRETURN(1);

void
Tcl_SetResult(interp, str)
	Tcl	interp
	char *	str
    CODE:
	Tcl_SetResult(interp, str, TCL_VOLATILE);
	ST(0) = ST(1);
	XSRETURN(1);

void
Tcl_AppendElement(interp, str)
	Tcl	interp
	char *	str

void
Tcl_ResetResult(interp)
	Tcl	interp

void
Tcl_FindExecutable(argv)
	char *	argv
    CODE:
    	Tcl_FindExecutable(argv);
	findexecutable_called = 1;


char *
Tcl_AppendResult(interp, ...)
	Tcl	interp
	int	i = NO_INIT
    CODE:
	for (i = 1; i <= items; i++)
	    Tcl_AppendResult(interp, SvPV(ST(i), PL_na), NULL);
	RETVAL = interp->result;
    OUTPUT:
	RETVAL

int
Tcl_DeleteCommand(interp, cmdName)
	Tcl	interp
	char *	cmdName
    CODE:
	RETVAL = Tcl_DeleteCommand(interp, cmdName) == 0;
    OUTPUT:
	RETVAL

void
Tcl_SplitList(interp, str)
	Tcl		interp
	char *		str
	int		argc = NO_INIT
	char **		argv = NO_INIT
	char **		tofree = NO_INIT
    PPCODE:
	if (Tcl_SplitList(interp, str, &argc, &argv) == TCL_OK)
	{
	    tofree = argv;
	    EXTEND(sp, argc);
	    while (argc--)
		PUSHs(sv_2mortal(newSVpv(*argv++, 0)));
	    ckfree((char *) tofree);
	}

char *
Tcl_SetVar(interp, varname, value, flags = 0)
	Tcl	interp
	char *	varname
	char *	value
	int	flags

char *
Tcl_SetVar2(interp, varname1, varname2, value, flags = 0)
	Tcl	interp
	char *	varname1
	char *	varname2
	char *	value
	int	flags

char *
Tcl_GetVar(interp, varname, flags = 0)
	Tcl	interp
	char *	varname
	int	flags

char *
Tcl_GetVar2(interp, varname1, varname2, flags = 0)
	Tcl	interp
	char *	varname1
	char *	varname2
	int	flags

int
Tcl_UnsetVar(interp, varname, flags = 0)
	Tcl	interp
	char *	varname
	int	flags
    CODE:
	RETVAL = Tcl_UnsetVar(interp, varname, flags) == TCL_OK;
    OUTPUT:
	RETVAL

int
Tcl_UnsetVar2(interp, varname1, varname2, flags = 0)
	Tcl	interp
	char *	varname1
	char *	varname2
	int	flags
    CODE:
	RETVAL = Tcl_UnsetVar2(interp, varname1, varname2, flags) == TCL_OK;
    OUTPUT:
	RETVAL

MODULE = Tcl		PACKAGE = Tcl::Var

char *
FETCH(av, key = NULL)
	Tcl::Var	av
	char *		key
	SV *		sv = NO_INIT
	Tcl		interp = NO_INIT
	char *		varname1 = NO_INIT
	int		flags = 0;
    CODE:
	/*
	 * This handles both hash and scalar fetches. The blessed object
	 * passed in is [$interp, $varname, $flags] ($flags optional).
	 */
	if (AvFILL(av) != 1 && AvFILL(av) != 2)
	    croak("bad object passed to Tcl::Var::FETCH");
	sv = *av_fetch(av, 0, FALSE);
	if (sv_isa(sv, "Tcl"))
	{
	    IV tmp = SvIV((SV *) SvRV(sv));
	    interp = (Tcl) tmp;
	}
	else
	    croak("bad object passed to Tcl::Var::FETCH");
	if (AvFILL(av) == 2)
	    flags = (int) SvIV(*av_fetch(av, 2, FALSE));
	varname1 = SvPV(*av_fetch(av, 1, FALSE), PL_na);
	RETVAL = key ? Tcl_GetVar2(interp, varname1, key, flags)
		     : Tcl_GetVar(interp, varname1, flags);
    OUTPUT:
	RETVAL

void
STORE(av, str1, str2 = NULL)
	Tcl::Var	av
	char *		str1
	char *		str2
	SV *		sv = NO_INIT
	Tcl		interp = NO_INIT
	char *		varname1 = NO_INIT
	int		flags = 0;
    CODE:
	/*
	 * This handles both hash and scalar stores. The blessed object
	 * passed in is [$interp, $varname, $flags] ($flags optional).
	 */
	if (AvFILL(av) != 1 && AvFILL(av) != 2)
	    croak("bad object passed to Tcl::Var::STORE");
	sv = *av_fetch(av, 0, FALSE);
	if (sv_isa(sv, "Tcl"))
	{
	    IV tmp = SvIV((SV *) SvRV(sv));
	    interp = (Tcl) tmp;
	}
	else
	    croak("bad object passed to Tcl::Var::STORE");
	if (AvFILL(av) == 2)
	    flags = (int) SvIV(*av_fetch(av, 2, FALSE));
	varname1 = SvPV(*av_fetch(av, 1, FALSE), PL_na);
	/*
	 * hash stores have key str1 and value str2
	 * scalar ones just use value str1
	 */
	if (str2)
	    (void) Tcl_SetVar2(interp, varname1, str1, str2, flags);
	else
	    (void) Tcl_SetVar(interp, varname1, str1, flags);
