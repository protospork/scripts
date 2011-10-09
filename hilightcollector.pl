use strict;
use warnings;
my $ver = 0.7;

Xchat::register("Highlight Collect", $ver, "Collects Highlights", \&unload);
Xchat::hook_print("Channel Msg Hilight", "highlighter");
Xchat::hook_print("Channel Action Hilight", "highlighter");

sub highlighter {
my $whom = $_[0][0];						# The nick of the person tabbing me
my $text = $_[0][1];						# The message
my $dest = Xchat::get_info('channel');
my $serv = Xchat::get_info('server');
my $server = 'irc.adelais.net';				# These two lines tell the script where to relay the messages.
my $homechan = '#fridge';					# #fridge is a channel I registered for my own use, it's private and locked to other users.
Xchat::print("\00311$whom\017\t$text (\00304$dest\017, \00304$serv\017)", $homechan, $server); # This line does all the work. \003## and \017 control the color scheme. \t is the margin line.
return Xchat::EAT_NONE;
}

Xchat::print("Highlight Collector $ver Loaded");	# Triggered when the script is loaded

sub unload {										# Triggered if you unload the script
Xchat::print("Highlight Collector $ver Unloaded");
}
