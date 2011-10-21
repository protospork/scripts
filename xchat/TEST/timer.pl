use Modern::Perl;
use Xchat ':all';
use diagnostics;

my $ver = 0.1;
register('timer test', $ver, 'THIS MAKES NO SENSE', sub { prnt 'timer test unloaded'; });
prnt 'timer test loaded.';

hook_command('test', \&do_this);
sub do_this {
	my $timer = hook_timer(5000, sub { place_timer(); return REMOVE; });
	prnt 'timer no. '.$timer;
}
sub place_timer {
	command('msg #fridge hello', '#fridge', 'irc.adelais.net');
#	return REMOVE; 
}