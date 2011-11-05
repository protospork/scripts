use Irssi;
use strict;
use warnings;
use LWP;
use URI::Escape qw'uri_escape_utf8 uri_unescape';
use utf8;
use vars qw($VERSION %IRSSI);
use JSON;

use vars qw($botnick $botpass $owner $animulistloc $maxdicedisplayed %timers @offchans @meanthings @repeat @animuchans @dunno $debug $cfgver);	##perl said to use 'our' instead of 'use vars'. it doesnt work.

#you can call functions from this script as Irssi::triggers->function(); or something

$VERSION = "2.20.21";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'triggers',
    description => 'a trigger script',
    license => 'like I care'
);

my $json = JSON->new->utf8;
my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1',
	max_size => 15000,
	timeout => 10,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5'
);
my ($lastreq,$lastcfgcheck,$animulastgrab) = (0,time,0);	#sheen is the only one that uses lastreq, roll probably should
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/triggers.pm'; #should I change this to github?

sub loadconfig {
	my $req = $ua->get($cfgurl, ':content_file' => $ENV{HOME}."/.irssi/scripts/cfg/triggers.pm");	#you have to manually create ~/.irssi/scripts/cfg
		unless ($req->is_success){ print $req->status_line; return; }

	do $ENV{HOME}.'/.irssi/scripts/cfg/triggers.pm';
		unless ($cfgver){ print "error loading variables from triggers cfg: $@" }

	print "triggers: config $cfgver successfully loaded";
	$lastcfgcheck = time;
}
loadconfig();

sub event_privmsg {
	my ($server, $data, $nick, $mask) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	my $return;
	
	loadconfig() if time - $lastcfgcheck > 86400;
	return if grep lc $target eq lc $_, (@offchans);
	
	return if $text !~ /^\s*\.(.+?)\s*$/;

	my @terms = split /\s+/, $1;
	
	#a 'trigger' doesn't have any additional info after it (needless distinction? probably)
	my %triggers = (
#'toss me some random numbers'
		flip		=>	\&dice('flip'),
		rose		=>	\&dice('rose'),
		sins		=>	\&choose('sins'),
		'sin'		=>	\&choose('sins'),		
#'grab things from a text file'
		farnsworth	=>	\&farnsworth, #ideally move the case check into the sub
		FARNSWORTH	=>	\&farnsworth(1),
		anime		=>	\&animu($target), #needs channel check moved into the sub, currently does nothing with that $target
		animu		=>	\&animu($target),
		stats		=>	\&stats($target),
		identify	=>	\&ident($server)		
	);
	my %calls = (
		when		=>	\&countdown(@terms), #can only handle a single word
		roll		=>	\&dice(@terms),
		choose		=>	\&choose(@terms),
		gs			=>	sub { shift @terms; uri_escape_utf8($_) for @terms; return ('http://gog.is/'.(join '+', @terms)); },
		'hex'		=>	sub { return ($nick.': '.(sprintf "%x", $terms[1])); },
		help		=>	sub { return 'https://github.com/protospork/scripts/blob/master/irssi/README.mkd'; }, #check out github pages
		
		c			=>	\&conversion(@terms), #augh
		calc		=>	\&conversion(@terms),
		'x'			=>	\&conversion(@terms),
		xe			=>	\&conversion(@terms),
		cvt			=>	\&conversion(@terms)
	);
	
	if (scalar @terms == 1){
		$return = ($triggers{$terms[0]} || sub { return 'NO'; })->();
	} else {
		$return = ($calls{$terms[0]} || sub { return 'STILL NO'; })->(@terms);
	}
	$server->command('msg '.$target.' '.$return);
}

sub choose { 
	my $call = shift;
	my @choices;
	if ($call =~ /sins?/){
		@choices = qw'greed gluttony wrath sloth lust envy pride';
	} elsif ((join ' ', (@_)) =~ /,/){
		@choices = (split /,\s*/, (join ' ', (@_)));
	} else {
		@choices = @_;
	}
	
	return 'gee I don\'t know, '.$meanthings[(int rand scalar @meanthings)-1] 
		if scalar @choices == 1;
	
	my %chcs; #choose 1, 1, 1, 1, 1
	for (@choices){ $chcs{$_}++; }
	if (scalar keys %chcs == 1){
		return ':| '.$meanthings[(int rand scalar @meanthings)-1];
	}
	
	#hehe
	return 'Nah' if int rand 100 <= 4;
	
	return $choices[(int rand ($#choices + 1))-1];
}

sub countdown {
	if (! @_){ #help message
		return (join ', ', keys %timers);
	}
	print $_[-1] if $debug;
	print $timers{uc $_[-1]}.' - '.time || 'AAAH';
	if ($timers{uc $_[-1]}){
		my $until = $timers{uc $_[-1]} - time;
		my $string;
		if ($until > 604800){ $string = int($until / 604800).' weeks '; $until = $until % 604800; }
		if ($until > 86400){ $string .= int($until / 86400).' days '; $until = $until % 86400; }
		if ($until > 3600){ $string .= int($until / 3600).' hours '; $until = $until % 3600; }
		if ($until > 60){ $string .= int($until / 60).' minutes '; $until = $until % 60; }
		return ($string.'until '.$_[-1]);
	} else {
		return $dunno[(int rand $#dunno +1) -1];
	}
}

sub conversion { #this doens't really work except for money
	#only works with three inputs
#	my ($trig, $in, $out) = @_;
	my @terms = @_;
	if (scalar @terms >= 4 && lc $terms[0] =~ /^(xe?|cvt)$/i){ 
		@terms = ($terms[0], (join '', @terms[1..($#terms-1)]), $terms[-1]); 
	}
	if (scalar @terms > 2 && lc $terms[0] =~ /^c(alc)?$/i){ 
		@terms = ($terms[0], (join '', @terms[1..$#terms])); 
	}

	#works with two or three inputs
	my $trig = uc $terms[0];
	my $in = uc $terms[1];
	$in =~ s/to$//;
	my $out;
	print join ', ', ($trig,$in) if $debug;
	if (defined $terms[0] && $debug == 1){ $out = uc $terms[0]; print '=> '.$out; }
	
	if ($in =~ /BTC$/ || $out eq 'BTC'){
		my $prices = $ua->get('http://bitcoincharts.com/t/weighted_prices.json');
		return $prices->status_line unless $prices->is_success;
		
		my $junk = $json->decode($prices->decoded_content) || return 'uhoh';
		my $num; ($num,$in) = ($in =~ /(\d+)\s*(\D+)/);
		if (uc $in eq 'BTC'){
			my $multi = ($junk->{$out}->{'24h'} || $junk->{$out}->{'7d'} || $junk->{$out}->{'30d'})
			|| return 'something seems to have exploded';
			
			my $product = $num * $multi;
			return $num.' '.$in.' is '.$product.' '.$out if $product;
			return ':(';
		} else {
			my $divide = ($junk->{$in}->{'24h'} || $junk->{$in}->{'7d'} || $junk->{$in}->{'30d'})
			|| return 'something is on fire';
			
			my $product = $num / $divide;
			return $num.' '.$in.' is '.$product.' '.$out if $product;
			return ':<';
		}
	}
	
	my $construct = 'http://www.google.com/ig/calculator?q='.uri_escape_utf8($in);
	$construct .= '=?'.uri_escape_utf8($out) if defined $out;
	
	print $construct if $debug;	
	
	my $req = $ua->get($construct);
	return $req->status_line unless $req->is_success;
	
	my $output = $req->decoded_content;
	print $output if $debug;
	#it's not actually real JSON :(
	#try $json->allow_barekey(1) ?
	$output =~ /lhs: "(.*?)",rhs: "(.*?)",error: "(.*?)"/i || return 'regex error';
	my ($from,$to,$error) = ($1,$2,$3);
	
	#\x3c / \x3e are <>. \x25#215; is &#215; is ×
	$to =~ s/\\x22/\"/g;
	$to =~ s/\\x26#215;/\*/g;
	$to =~ s/\\x3csup\\x3e/\^/g;
	$to =~ s/\\x3c\/sup\\x3e/ /g;
	
	unless ($error){ return $from.' = '.$to; }
	$error =~ s/\\x22/"/g;
	#4 is "I don't know what that unit is" or something
	$error = $dunno[rand(scalar(@dunno))-1] if $error =~ /(?:Error: )?4/i;
	return $error;
}
sub utfdecode { #why
	my $x = my $y = uri_unescape($_[0]);
	return $x if utf8::decode($x);
	return $y;
}
my @prev3 = ('heads','tails','heads');
sub dice {
	my $flavor = lc $_[0];
	if ($flavor eq 'rose'){
		return join ' ', roll(5,6);
	} elsif ($flavor eq 'flip'){
		my $toss = int(rand(30)+1);	#&roll seems to be unreliable for tiny numbers. not that this isn't.
		if (($toss % 2) == 1){
			$toss = 'heads';
		} else {
			$toss = 'tails';
		}
		
		#can't remember why I'm doing this @prev3 shit
		if ($toss eq $prev3[0] && $toss eq $prev3[1]){
			push @prev3, $toss;
			$toss .= ' '.$repeat[int(rand($#repeat))];
		} else {
			push @prev3, $toss;
		}
		shift @prev3;	#throw away the oldest toss
		
		return $toss;
	} elsif ($flavor eq 'roll'){
		my @xdy = split /d/i, $_[1];
		my @throws = roll(@xdy);
		my $total;
		for (@throws){
			$total += $_;
		}
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] <= 1;
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] > 300;
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[0] > 300;
		return $throws[0] if $xdy[0] == 1;
		if ($xdy[0] <= $maxdicedisplayed){
			return (join ' + ', @throws)." = $total";
		} else {
			return $total;	
		}
	}
}
sub roll {
	my $numdice = $_[0];
	my $sides = $_[1];
	my @numbers = ( );
	while ( $numdice != 0 ) {
		push (@numbers, int(rand($sides))+1);
		$numdice--;
	}
	return @numbers;
}
sub ident {
	my $server = $_[0];
	$server->command("nick".$botnick);
	sleep 4;
	$server->command("msg nickserv identify ".$botpass);
}
sub animu { #I'm not sure this needs to bother holding back on the downloads
	my @lines;
	if (time - $animulastgrab > 172800){
		print 'downloading animu.txt';
		my $resp = $ua->get($animulistloc, ':content_file' => '/home/proto/.irssi/scripts/cfg/animu.txt');	#you need to create animu.txt yourself
		return 'error: '.$resp->status_line unless $resp->is_success;
		$animulastgrab = time;
	}
	
	open my $word, '<', '/home/proto/.irssi/scripts/cfg/animu.txt' or die $!;	#die? does that... die?
	@lines = <$word>;
		
	if (scalar @lines == 0){ return '@lines is empty'; }
	
	my $num = int rand scalar @lines;
	return $lines[$num].' (#'.($num + 1).')';
}
sub farnsworth {
	my $req = $ua->get('http://dl.dropbox.com/u/48390/misc/txt/farnsworth.txt');
	return 'error: '.$req->status_line unless $req->is_success;
	
	my @lines = split /[\r\n]+/, $req->content;
	return 'error: protospork is retarded' if scalar @lines == 1;
	my $line = $lines[(int rand ($#lines + 1) - 1)];
	$line = uc $line if $_[0];
	return $line;
}
sub stats {
	my ($chan) = @_;
	return if $chan !~ /(anime|moap|cfounders|programming)/i;
	$chan = $1; $chan =~ s/anime/animu/;
	$chan eq 'programming' ? return 'http://www.galador.org/irc/'.$chan.'.html' : return 'http://protospork.moap.net/'.$chan.'.html';
}

#note that this sub isn't attached to anything - I'm still using weatherbot.pl and can't remember what's broken here
my %place;
sub weather {	
# timestamp | degrees F | windchill | ? | humidity | dewpoint | windchill | barometer | conditions | visibility | sunrise | sunset |
# ? | ? | ? | ? | ? | ? | town | state | moonrise | moonset | closest airport | UV index
#there isn't really a linebreak there

#	my ($nick,$trigger,$place) = ($_[0],$_[1],$_[]);
	my $nick = shift; my $trigger = pop;
	my $place = join ' ', @_;
	unless (defined $place && $place ne ' '){ exists $place{$nick} ? $place = $place{$nick} : return 'where?'; }
	
	$place =~ s/ /_/g; $place =~ s/,//g;
	my $req = $ua->get('http://38.102.136.104/auto/raw/'.$place);
	
	unless ($req->is_success){ return 'uh oh'; }
	return 'http://www.faacodes.com/' if $req->content =~ /[<>]/;
	
	my @w = split /\s*[|]\s*/, $req->content;
	my $time = $w[0];
	$time =~ s/(\d\d?:\d\d \wM \w\w\w).+/$1/;
	my ($town, $state, $weather, $ftemp, $hum, $bar, $wind, $windchill,$ctemp) = ($w[18],$w[19],$w[8],$w[1],$w[4],$w[7],$w[6],$w[2],'-');
	unless ($w[1] == "") { $ctemp = sprintf( "%4.1f", ($w[1] - 32) * (5 / 9)); } $ctemp =~ s/ //g;
	
	if ($wind !~ / 0$/){
		if ($ftemp < 40 && $windchill !~ /N.A/){
			$place =~ /^\d{5}$/ 
			? return "\002$town, $state\002 ($time): $ftemp\x{00B0}F/$ctemp\x{00B0}C - $weather | Windchill $windchill\x{00B0}F | Wind $wind MPH"
			: return "\002$town, $state\002 ($time): $ctemp\x{00B0}C/$ftemp\x{00B0}F - $weather | Windchill $windchill\x{00B0}F | Wind $wind MPH";
		} else {
			$place =~ /^\d{5}$/
			? return "\002$town, $state\002 ($time): $ftemp\x{00B0}F/$ctemp\x{00B0}C - $weather | $hum Humidity | Wind $wind MPH"
			: return "\002$town, $state\002 ($time): $ctemp\x{00B0}C/$ftemp\x{00B0}F - $weather | $hum Humidity | Wind $wind MPH";
		}
	} else {
		$place =~ /^\d{5}$/
		? return "\002$town, $state\002 ($time): $ftemp\x{00B0}F/$ctemp\x{00B0}C - $weather | $hum Humidity | Barometer: $bar"
		: return "\002$town, $state\002 ($time): $ctemp\x{00B0}C/$ftemp\x{00B0}F - $weather | $hum Humidity | Barometer: $bar";
	}
}
Irssi::signal_add("event privmsg", "event_privmsg");
