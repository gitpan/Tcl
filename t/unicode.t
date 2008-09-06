#!perl -w

# Test the transfer of null and various unicode data through assorted APIs.
# The \x{2030} is the permille sign.
#
# On Unix this progam shows different wrong behaviour depending
# on what kind of locale it runs under.

use strict;
use Test qw(plan ok);

plan tests => 6;

use Tcl;

my $int = new Tcl;

my $str = "This is a string\n";
$str .= "This is a string containing NUL (\0) and some other controls (\a\r)\n";
$str .= "\0 \x{2030}\n";
$str .= "[\0 \x{2030}]\n";
$str .= "bytes: " . join("", map chr, 0 .. 255) . "\n";
$str .= "uni: " . join("", map chr, 0 .. 300) . "\n";

my $output = <<"EOT";
This is a string
This is a string containing NUL (\0) and some other controls (\a\r)
\0 \x{2030}
[\0 \x{2030}]
bytes: \0\1\2\3\4\5\6\a\b\t
\13\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35\36\37 !\"#\$%&'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7F\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF
uni: \0\1\2\3\4\5\6\a\b\t
\13\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35\36\37 !\"#\$%&'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\x7F\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF\x{100}\x{101}\x{102}\x{103}\x{104}\x{105}\x{106}\x{107}\x{108}\x{109}\x{10A}\x{10B}\x{10C}\x{10D}\x{10E}\x{10F}\x{110}\x{111}\x{112}\x{113}\x{114}\x{115}\x{116}\x{117}\x{118}\x{119}\x{11A}\x{11B}\x{11C}\x{11D}\x{11E}\x{11F}\x{120}\x{121}\x{122}\x{123}\x{124}\x{125}\x{126}\x{127}\x{128}\x{129}\x{12A}\x{12B}\x{12C}
EOT

my $res = $int->SetVar("unitest", $str);
ok($res, $output);

$res = $int->Eval("append unitest \"\\0\\1\\2\\n\"");
$output .= "\0\1\2\n";

ok($int->result, $output);
ok($res, $output);
ok($int->GetVar("unitest"), $output);

$res = $int->AppendResult("", "\0", "\x{2030}");
$output .= "\0\x{2030}";
ok($res, $output);
ok($int->result, $output);
