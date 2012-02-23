use Xchat;	#don't do qw( :all ), it applies to the content of eval
use utf8;	#?

my $ver = '0.7';
Xchat::register('eval', $ver, 'this is a terrible idea', \&unload);
Xchat::hook_command('perl', \&something); Xchat::hook_command('eval', \&something);

Xchat::print "eval $ver loaded";

sub something {
	my $code = $_[1][1];
	$code =~ s/\bprint\b/Xchat::print/ig;
#	$code =~ s/\bsend\(([^;]+);/Xchat::command("say ".$1);/ig; #didn't bother testing just thought it was a decent idea
	my $out = eval $code;
	if ($@) { Xchat::print $@; }
#	else { prnt $out; }
	return EAT_XCHAT;
}

sub unload { Xchat::print "eval $ver unloaded"; }