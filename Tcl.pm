package Tcl;
use Carp;

=head1 NAME

Tcl - Tcl extension module for Perl

=head1 SYNOPSIS

    use Tcl;

    $interp = new Tcl;
    $interp->Eval('puts "Hello world"');

=head1 DESCRIPTION

The Tcl extension module gives access to the Tcl library with
functionality and interface similar to the C functions of Tcl.
In other words, you can

=over 8

=item create Tcl interpreters

The Tcl interpreters so created are Perl objects whose destructors
delete the interpreters cleanly when appropriate.

=item execute Tcl code in an interpreter

The code can come from strings, files or Perl filehandles.

=item bind in new Tcl procedures

The new procedures can be either C code (with addresses presumably
obtained using I<dl_open> and I<dl_find_symbol>) or Perl subroutines
(by name, reference or as anonymous subs). The (optional) deleteProc
callback in the latter case is another perl subroutine which is called
when the command is explicitly deleted by name or else when the
destructor for the interpreter object is explicitly or implicitly called.

=item Manipulate the result field of a Tcl interpreter

=item Set and get values of variables in a Tcl interpreter

=item Tie perl variables to variables in a Tcl interpreter

The variables can be either scalars or hashes.

=back

=head2 Methods in class Tcl

To create a new Tcl interpreter, use

    $i = new Tcl;

The following methods and routines can then be used on the Perl object
returned (the object argument omitted in each case).

=over 8

=item Init ()

Invoke I<Tcl_Init> on the interpeter.

=item Eval (STRING)

Evaluate script STRING in the interpreter. If the script returns
successfully (TCL_OK) then the Perl return value corresponds to
interp->result otherwise a I<die> exception is raised with the $@
variable corresponding to interp->result. In each case, I<corresponds>
means that if the method is called in scalar context then the string
interp->result is returned but if the method is called in list context
then interp->result is split as a Tcl list and returned as a Perl list.

=item GlobalEval (STRING)

Evalulate script STRING at global level. Otherwise, the same as
I<Eval>() above.

=item EvalFile (FILENAME)

Evaluate the contents of the file with name FILENAME. Otherwise, the
same as I<Eval>() above.

=item EvalFileHandle (FILEHANDLE)

Evaluate the contents of the Perl filehandle FILEHANDLE. Otherwise, the
same as I<Eval>() above. Useful when using the filehandle DATA to tack
on a Tcl script following an __END__ token.

=item call (PROC, ARG, ...)

Looks up procedure PROC in the interpreter and invokes it directly with
arguments (ARG, ...) without passing through the Tcl parser. For example,
spaces embedded in any ARG will not cause it to be split into two Tcl
arguments before being passed to PROC.

=item result ()

Returns the current interp->result field. List v. scalar context is
handled as in I<Eval>() above.

=item CreateCommand (CMDNAME, CMDPROC, CLIENTDATA, DELETEPROC)

Binds a new procedure named CMDNAME into the interpreter. The
CLIENTDATA and DELETEPROC arguments are optional. There are two cases:

(1) CMDPROC is the address of a C function

(presumably obtained using I<dl_open> and I<dl_find_symbol>. In this case
CLIENTDATA and DELETEPROC are taken to be raw data of the ClientData and
deleteProc field presumably obtained in a similar way.

(2) CMDPROC is a Perl subroutine

(either a sub name, a sub reference or an anonymous sub). In this case
CLIENTDATA can be any perl scalar (e.g. a ref to some other data) and
DELETEPROC must be a perl sub too. When CMDNAME is invoked in the Tcl
interpeter, the arguments passed to the Perl sub CMDPROC are

    (CLIENTDATA, INTERP, LIST)

where INTERP is a Perl object for the Tcl interpreter which called out
and LIST is a Perl list of the arguments CMDNAME was called with.
As usual in Tcl, the first element of the list is CMDNAME itself.
When CMDNAME is deleted from the interpreter (either explicitly with
I<DeleteCommand> or because the destructor for the interpeter object
is called), it is passed the single argument CLIENTDATA.

=item DeleteCommand (CMDNAME)

Deletes command CMDNAME from the interpreter. If the command was created
with a DELETEPROC (see I<CreateCommand> above), then it is invoked at
this point. When a Tcl interpreter object is destroyed either explicitly
or implicitly, an implicit I<DeleteCommand> happens on all its currently
registered commands.

=item SetResult (STRING)

Sets interp->result to STRING.

=item AppendResult (LIST)

Appends each element of LIST to interp->result.

=item AppendElement (STRING)

Appends STRING to interp->result as an extra Tcl list element.

=item ResetResult ()

Resets interp->result.

=item SplitList (STRING)

Splits STRING as a Tcl list. Returns a Perl list or the empty list if
there was an error (i.e. STRING was not a properly formed Tcl list).
In the latter case, the error message is left in interp->result.

=item SetVar (VARNAME, VALUE, FLAGS)

The FLAGS field is optional. Sets Tcl variable VARNAME in the
interpreter to VALUE. The FLAGS argument is the usual Tcl one and
can be a bitwise OR of the constants $Tcl::GLOBAL_ONLY,
$Tcl::LEAVE_ERR_MSG, $Tcl::APPEND_VALUE, $Tcl::LIST_ELEMENT.

=item SetVar2 (VARNAME1, VARNAME2, VALUE, FLAGS)

Sets the element VARNAME1(VARNAME2) of a Tcl array to VALUE. The optional
argument FLAGS behaves as in I<SetVar> above.

=item GetVar (VARNAME, FLAGS)

Returns the value of Tcl variable VARNAME. The optional argument FLAGS
behaves as in I<SetVar> above.

=item GetVar2 (VARNAME1, VARNAME2, FLAGS)

Returns the value of the element VARNAME1(VARNAME2) of a Tcl array.
The optional argument FLAGS behaves as in I<SetVar> above.

=item UnsetVar (VARNAME, FLAGS)

Unsets Tcl variable VARNAME. The optional argument FLAGS
behaves as in I<SetVar> above.

=item UnsetVar2 (VARNAME1, VARNAME2, FLAGS)

Unsets the element VARNAME1(VARNAME2) of a Tcl array.
The optional argument FLAGS behaves as in I<SetVar> above.

=back

=head2 Linking Perl and Tcl variables

You can I<tie> a Perl variable (scalar or hash) into class Tcl::Var
so that changes to a Tcl variable automatically "change" the value
of the Perl variable. In fact, as usual with Perl tied variables,
its current value is just fetched from the Tcl variable when needed
and setting the Perl variable triggers the setting of the Tcl variable.

To tie a Perl scalar I<$scalar> to the Tcl variable I<tclscalar> in
interpreter I<$interp> with optional flags I<$flags> (see I<SetVar>
above), use

	tie $scalar, Tcl::Var, $interp, "tclscalar", $flags;

Omit the I<$flags> argument if not wanted.

To tie a Perl hash I<%hash> to the Tcl array variable I<array> in
interpreter I<$interp> with optional flags I<$flags>
(see I<SetVar> above), use

	tie %hash, Tcl::Var, $interp, "array", $flags;

Omit the I<$flags> argument if not wanted. Any alteration to Perl
variable I<$hash{"key"}> affects the Tcl variable I<array(key)>
and I<vice versa>.

=head2 AUTHOR

Malcolm Beattie, mbeattie@sable.ox.ac.uk, 23 Oct 1994.

=cut

use DynaLoader;
@ISA = qw(DynaLoader);

sub OK ()	{ 0 }
sub ERROR ()	{ 1 }
sub RETURN ()	{ 2 }
sub BREAK ()	{ 3 }
sub CONTINUE ()	{ 4 }

sub GLOBAL_ONLY ()	{ 1 }
sub APPEND_VALUE ()	{ 2 }
sub LIST_ELEMENT ()	{ 4 }
sub TRACE_READS ()	{ 0x10 }
sub TRACE_WRITES ()	{ 0x20 }
sub TRACE_UNSETS ()	{ 0x40 }
sub TRACE_DESTROYED ()	{ 0x80 }
sub INTERP_DESTROYED ()	{ 0x100 }
sub LEAVE_ERR_MSG ()	{ 0x200 }

sub LINK_INT ()		{ 1 }
sub LINK_DOUBLE ()	{ 2 }
sub LINK_BOOLEAN ()	{ 3 }
sub LINK_STRING ()	{ 4 }
sub LINK_READ_ONLY ()	{ 0x80 }

bootstrap Tcl;

package Tcl::Var;

sub TIESCALAR {
    my $class = shift;
    my @objdata = @_;
    Carp::croak 'Usage: tie $s, Tcl::Var, $interp, $varname [, $flags]'
	unless @_ == 2 || @_ == 3;
    bless \@objdata, $class;
}

sub TIEHASH {
    my $class = shift;
    my @objdata = @_;
    Carp::croak 'Usage: tie %hash, Tcl::Var, $interp, $varname [, $flags]'
	unless @_ == 2 || @_ == 3;
    bless \@objdata, $class;
}

1;
__END__
