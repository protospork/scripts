use Xchat;	#don't do qw( :all ), it applies to the content of eval
use utf8;	#?

my $ver = '0.7';
Xchat::register('eval', $ver, 'this is a terrible idea', \&unload);
Xchat::hook_command('perl', \&something); Xchat::hook_command('eval', \&something);

Xchat::hook_command('curs', \&squiggles); 
Xchat::print "eval $ver loaded";

sub something {
	my $code = $_[1][1];
	$code =~ s/\bprint\b/Xchat::print/ig;
	my $out = eval $code;
	if ($@) { Xchat::print $@; }
#	else { prnt $out; }
	return EAT_XCHAT;
}
sub squiggles {
	my $str = $_[1][1]; 
	$str =~ tr/A-Za-z0-9/\x{1D4D0}-\x{1D503}\x{1D7EC}-\x{1D7F5}/; 
	Xchat::command("say $str");
	return EAT_XCHAT;
}

sub unload { Xchat::print "eval $ver unloaded"; }