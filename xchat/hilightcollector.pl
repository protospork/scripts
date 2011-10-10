use strict;
use warnings;
use Xchat ':all';
my $ver = 0.8;

#This was pretty much the first useful script I wrote--
#hook any highlights and print them [locally] in my own channel.
#There are dozens of better / more capable scripts to do this,
#I'm just attached to my own.

#fixme: responses are doubled and I have no fucking idea why, setting priority was supposed to fix that

register("Highlight Collect", $ver, "Collects Highlights", \&unload);
hook_print("Channel Msg Hilight", \&highlighter, {priority => PRI_HIGH});
hook_print("Channel Action Hilight", \&highlighter, {priority => PRI_HIGH});

sub highlighter {
	my ($whom,$text) = @{$_[0]};
	my $dest = get_info('channel');
	my $serv = get_info('server');
	my ($server,$homechan) = ('irc.adelais.net','#fridge');
	prnt("\00311$whom\017\t$text (\00304$dest\017, \00304$serv\017)", $homechan, $server);
	return EAT_NONE;
}
sub unload {
	prnt("Highlight Collector $ver Unloaded");
}
prnt("Highlight Collector $ver Loaded");