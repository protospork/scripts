# timestamp | degrees F | windchill | ? | humidity | dewpoint | windchill | barometer | conditions | visibility | sunrise | sunset | age of moon | ? | ? | ? | ? | ? | town | state | moonrise | moonset | closest airport | UV index

#TODO:
#	-consider preferring metric units for non-US locations

use Irssi;
use LWP::UserAgent;
use Tie::File;

$VERSION = "3.3p";
%IRSSI = (
	author => 'protospork',
	contact => 'protospork\@gmail.com',
	license => 'GNU GPL v2 or later',
	name => 'weatherbot',
	description => 'a weatherbot that provides weather and forecast based on zip code',
	url => 'https://github.com/protospork/scripts'
#   author => 'pleia2',
#   contact => 'lyz\@princessleia.com ',
#   url => 'http://www.princessleia.com'
);

#At this point it doesn't really resemble pleia2's script-
#I don't really know how to handle the GPL thing 'properly'.

my (@memory, %savedloc);
tie @memory, 'Tie::File', '/home/proto/.irssi/scripts/cfg/weathernicks.cfg' or die "Couldn't open weathernicks.cfg ($!)"; #this fucking file is ...interesting. and broken. fix it.
for (@memory){ my @why = split /::/, $_; $savedloc{$why[0]} = $why[1]; } #why not just tie a hash?

sub event_privmsg {
	my ($server, $data, $nick) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	
	$nick = lc $nick;
	
	for (split /,/, Irssi::settings_get_str('trig_offchans')){ return if $target =~ /$_/i; } #I need to stop embedding settings in irssi

	if ( $text =~ /^\s*\.w(?:eather|z)?(?:\s+(.*))?$/i ){
	
		if (! defined $1){ 
			if (exists $savedloc{$nick}){
				$location = $savedloc{$nick}
			} else {
				$server->command("notice $nick Could you please repeat that?"); 
				return; 
			} 
		} else { 
			$location = $1 
		}
		
		$location =~ s/ /_/g; $location =~ s/,//g;
		my $ua = LWP::UserAgent->new();
		$ua->timeout(10);
		my $results = $ua->get("http://38.102.136.104/auto/raw/$location");
		my @badarray = split(/\n/, $results->content);
		if ( ! $results->is_success ) {
			$server->command ( "notice $nick .w [zipcode|city, state|airport code] - if you can't get anything, search http://www.faacodes.com/ for an airport code" );
		} elsif ( $results->content =~ /[<>]/ ) {
			$server->command ( "notice $nick .w [zipcode|city, state|airport code] - if you can't get anything, search http://www.faacodes.com/ for an airport code" );
		} else {
			push @memory, (join '::', $nick, $location);
			$savedloc{$nick} = $location;
			my @goodarray = split(/[|]\s*/, $results->content);
			my $timestamp = $goodarray[0];
			$timestamp =~ s/(\d\d?:\d\d \wM \w\w\w).+/$1/;
			my ($town, $state, $weather, $ftemp, $hum, $bar, $wind, $windchill) = ($goodarray[18], $goodarray[19], $goodarray[8], $goodarray[1], $goodarray[4], $goodarray[7], $goodarray[6], $goodarray[2]);	#augh
			if ($goodarray[1] != "") { $ctemp = sprintf( "%4.1f", ($goodarray[1] - 32) * (5 / 9) ); }
			$ctemp =~ s/ //;
			if ($wind !~ / 0$/){
				if ($ftemp < 40 && $windchill !~ /N.A/){
					$server->command("msg $target \002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | Windchill $windchill\xB0F | Wind $wind MPH");
				} else {
					$server->command("msg $target \002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | $hum Humidity | Wind $wind MPH");
				}
			} else {
				$server->command("msg $target \002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | $hum Humidity | Barometer: $bar");
			}
		}
	} else { 
		return; 
	}
}



Irssi::settings_add_str('misc', 'trig_offchans', '#honobono');
Irssi::signal_add('event privmsg', 'event_privmsg');
