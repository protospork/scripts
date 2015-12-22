use Modern::Perl;
use Xchat qw':all';

register('fuckyouretna', time, "fuck you retna", \&unload);
hook_print("Kick", \&everything, {priority => PRI_LOW});

sub unload { prnt "nsfw"; }
prnt "fuck you retna";


sub everything {
	my ($nick, $reason) = ($_[0], $_[-1]);

	prnt($nick);
	prnt($reason);

	if ($nick =~ /retna|niacin|opioid|holiday.*nick/i && $reason =~ /language/){
		command("kick $nick");
	}
	return EAT_NONE;
}