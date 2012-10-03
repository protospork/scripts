use Irssi;
use strict;
use warnings;
use LWP;
use URI;
use URI::Escape qw'uri_escape_utf8 uri_unescape';
use HTML::Scrape 'put';
use HTML::Entities;
use utf8;
use vars qw($VERSION %IRSSI);
use JSON;
use feature 'switch'; #for reference, Modern::Perl does enable 'switch'
use Tie::File;
use TMDB;

use vars qw($botnick $botpass $owner $listloc $tmdb_key $maxdicedisplayed %timers @yield_to
				@offchans @meanthings @repeat @animuchans @donotwant @dunno $debug $cfgver);	##perl said to use 'our' instead of 'use vars'. it doesnt work because I am retarded

#you can call functions from this script as Irssi::Script::triggers::function(); or something
#protip: if you're storing nicks in a hash, make sure to `lc` them
#todo: re-add the config rehash trigger

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text

$VERSION = "2.6.1";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'triggers',
    description => 'a trigger script',
    license => 'MIT/X11'
);

my $json = JSON->new->utf8;
my $ua = LWP::UserAgent->new(
#	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1',
	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7',
	max_size => 15000,
	timeout => 10,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5'
);
my ($lastreq,$lastcfgcheck,$animulastgrab) = (0,time,0);	#sheen is the only one that uses lastreq, roll probably should
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/triggers.pm';

sub loadconfig {
	my $req = $ua->get($cfgurl, ':content_file' => $ENV{HOME}."/.irssi/scripts/cfg/triggers.pm");	#you have to manually create ~/.irssi/scripts/cfg
		unless ($req->is_success){ die $req->status_line; }

	do $ENV{HOME}.'/.irssi/scripts/cfg/triggers.pm';
		unless ($cfgver =~ /./){ print "error loading variables from triggers cfg: $@" }

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
	
	my @terms;
	if ($text =~ /^\s*\.(.+?)\s*$/){ #make sure it's a trigger
		@terms = split /\s+/, $1;
	} elsif ($text =~ /$botnick/i){
		if ($text =~ /^\s*$botnick[:,]\s*(\w+.*)\?\s*$/i){ #I hate you, future self
			my $choices = $1;
			my @query = split /\s+/, $choices;
			if ($choices =~ s/\s+or\s+/, /ig){ #shortcut to .choose
				$server->command('msg '.$target.' '.(choose('choose', (split /\s+/, $choices))));
			} elsif ($query[0] =~ /wh([oy]|at|e(n|re))|how/){ #stupid 8ball
				$server->command('msg '.$target.' '.(choose(qw'8ballunsure some junk data'))); 
			} else { #straightup 8ball
				$server->command('msg '.$target.' '.(choose(qw'8ball some junk data'))); 
			}
			return;
		} elsif ($text =~ /^\s*\w+.+\s+$botnick\?\s*$/i){ #this needs to be re-integrated with the last regex sometime
			$server->command('msg '.$target.' '.(choose(qw'8ball some junk data'))); 
			return;
		} else { 
			return; 
		}
	} else {
		return;
	}

	given ($terms[0]){
		when (/^flip$|^ro(ll|se)$/i){	$return = dice(@terms); }
		when (/^sins?$|^choose$|^8ball$/i){	$return = choose(@terms); }
		when (/^(farnsworth|anim[eu])$/i){ $return = readtext(@terms); }
		when (/^stats$/i){			$return = status($target); }
		when (/^identify$/){		$return = ident($server); }
		when (/^when$/i){			$return = countdown(@terms); }
#		when (/^gs$|^ddg$/i){		shift @terms; uri_escape_utf8($_) for @terms; $return = ('http://ddg.gg/?q='.(join '+', @terms)); }
		when (/^!\S+$|^gs$|^ddg$/i){$return = ddg(@terms); }
		when (/^hex$/i){			$return = ($nick.': '.(sprintf "%x", $terms[1])); }
		when (/^help$/i){			$return = 'https://github.com/protospork/scripts/blob/master/irssi/README.md' }
		when (/^c(alc|vt)?$|^xe?$/){$return = conversion(@terms); }
		when (/^airtimes/){			$return = airtimes(@terms); }
		when (/^w(eather)?$/){		$return = weather($server, $nick, @terms); }
	#crashy	when (/^isup$/){			$return = Irssi::Script::gettitle::get_title('http://isup.me/'.$terms[-1]); $return =~ s/(Up|Down).++$/$1./; } 
		when (/^anagram$/){			return; }#$return = anagram(@terms); }
		when (/^ord$|^utf8$/i){		$return = codepoint($terms[1]); }
	#api is down?	when (/^tmdb/i){			moviedb($server, $target, @terms); return; } #multiline responses
		when (/^lastfm/i){			$return = lastfm($server, $nick, @terms); }
		default { return; }
	}
	if (! defined $return){
		return;
	}
	elsif (ref $return){
		for (@$return[0..3]){
			$server->command('msg '.$target.' '.$_);
		}
	}
	else {
		$server->command('msg '.$target.' '.$return);
	}
}


sub ddg {
	my $trigger = shift @_;
	my @terms = @_;
	if ($trigger =~ /^!/){ #whoops put trigger back if it's part of the query
		unshift @terms, $trigger;
	}
	my $feelinglucky;
	
	if ($trigger =~ /^ddg$/ && $terms[0] !~ /^[!\\]/){ #.ddg = first result; .gs = index
		$terms[0] = '\\'.$terms[0];
	}
	if ($terms[0] =~ /^[\\!]/){
		$feelinglucky++;
	}
	uri_escape_utf8($_) for @terms;
	my $query = ('http://ddg.gg/?q='.(join '+', @terms).'&kp=-1'); #kp=-1 is to disable safesearch, I hope
	
	if (! $feelinglucky){
		return $query;
	}
	
	my $req = $ua->get($query);
	if (!$req->is_success){
		print ('DDG: '.$query.': HTTP '.$req->code) if $debug;
		return $query;
	}
	my $orig_url = $query;
	
	if ($req->header('Refresh')){ #duckduckgo uses a soft redirect (to record impressions?) so we need to grab html
		$orig_url = $req->header('Refresh');
		$orig_url =~ s/^.*?(http\S+).*?$/$1/i;
	}
	$req = $ua->get($orig_url); #now grab that url and follow its redirects, because it's probably a landing page
		
	for ($req->redirects){
		unless ($_->header('Location') =~ /duckduckgo/){
			$orig_url = $_->header('Location');
		}
	}
	
	return $orig_url;
}


my %lastfms;
tie my @lastfmmemory, 'Tie::File', $ENV{HOME}.'/.irssi/scripts/cfg/lastfm.cfg' 
	or die $!;
for (@lastfmmemory){ my @why = split /::/, $_; $lastfms{$why[0]} = $why[1]; } #why not just tie a hash?

sub lastfm {	
	my ($server,$nick) = (shift, lc shift);
	my $text = '';
	shift; #dump the trigger
	$text = shift;
	my $location;
	if (! $text || $text eq ''){ 
		if (exists $lastfms{$nick}){
			$location = $lastfms{$nick}
		} else {
			$location = $nick;
			$lastfms{$nick} = $nick;
			# return; 
		} 
	} else { 
		$location = $text; 
	}
	my $results = $ua->get('http://ws.audioscrobbler.com/1.0/user/'.$location.'/recenttracks.rss');

	if (! $results->is_success || $results->content eq 'No user exists with this name.') {
		$server->command("notice $nick Shit's broke. Are you sure that was a valid last.fm username?");
		return;
	} else {
		my $memstring = (join '::', $nick, $location);
		unless (grep $memstring eq $_, @lastfmmemory){ push @lastfmmemory, $memstring; }
		$lastfms{$nick} = $location;
		
		my $chunk = (split /<item>/, $results->content)[1];
		my ($title, $date) = ($chunk =~ m{<title>([^<]+)</title>.+?<pubDate>\w{3,4}, \d+ \w{3,4} \d{4} ((?:\d\d:){2}\d\d) \+0000}is);
		
		$title = encode_entities($title);
		$title =~ s/&ndash;/-/g;
		$title = decode_entities($title);
		return 'http://last.fm/user/'.$location.' last played '.$title;
	}
}

sub moviedb {
	my ($server, $target) = (shift, shift);
	my $call = shift;
	my $query = join ' ', @_;
	print $query if $debug;
	my ($person, $full, $id);
	given ($call){
		when (/:person/){ $person++; $full++; }
		when (/:full/){ $full++; }
	}
	if ($query =~ /^\d+$/){ $id = $query; $full++; }
	
	my $tmdb = TMDB->new({api_key => $tmdb_key});
	if (! $person){
		my @out;
		if (! $id){
			my @res = $tmdb->search->movie($query);
			if (scalar @res == 1){ $full++; }
			for my $res (@res) {
				push @out, $res->{name}.' ['.$res->{year}.']('.$res->{url}.')';
			}
			$id = $res[0]->{id};
		}
		if (! $full){
			my $out = shift @out;
			while (length $out < 300 && @out){
				$out .= ', '.(shift @out);
			}
			$server->command('msg '.$target.' '.$out) if $out;
			return;
		} else {
			my $det = $tmdb->movie($id);
			$det = $det->info();
			# print keys %$det if $debug;
			
			my $out = '<'.$det->{name}.'>';
			if ($det->{released}){
				$out .= ' Released:[ '.$det->{released}.' ]';
			}
			if ($det->{certification}){
				$out .= ' Rating:[ '.$det->{certification}.' ]';
			}
			if ($det->{genres}){
				$out .= ' Genre:[ ';
				
				my $i = 0;
				while ($i < 5 && $i <= $#{$det->{genres}}){
					$out .= ', ' unless $i == 0;
					$out .= $det->{genres}[$i]{name};
					$i++;
				}
				
				$out .= ' ]';
			}
			if ($det->{trailer}){
				my $trl = $det->{trailer};
				$trl =~ s!http://www.youtube.com/watch?v=!http://youtu.be/!;
				$out .= ' Trailer:[ '.$trl.' ]';
			}
			if ($det->{url}){
				$out .= ' Link:[ '.$det->{url}.' ]'
			}
			$server->command('msg '.$target.' '.$out);
			return;
		}
	} else {
		return; #only works for madonna and cher for some stupid reason
		my @rep = $tmdb->search->person($query);
		my $them = $rep[0]->{id};
		print $query.': '.$rep[0]->{id} if $debug;
		$them = $tmdb->person($them);
		$them = $them->info();
		
		my $out = '<'.$them->{name}.'>';
		if ($them->{known_movies}){
			$out .= ' Total Movies:[ '.$them->{known_movies}.' ]';
		}
		if ($them->{filmography}){
			$out .= ' Movies:[ ';
			my $i = 0;
			while ($i < 5 && $i <= $#{$them->{filmography}}){
				$out .= ', ' unless $i == 0;
				if ($them->{filmography}[$i]{job} eq 'Actor'){
					$out .= $them->{filmography}[$i]{name}.' ('.$them->{filmography}[$i]{character}.')';
				} else {
					$out .= $them->{filmography}[$i]{name};
				}
				$i++;
			}
		}
		if ($them->{url}){
			$out .= ' Link:[ '.$them->{url}.' ]';
		}
		$server->command('msg '.$target.' '.$out);
		return;
	}
	
}

sub codepoint {
	my $char = $_[0];
	$char =~ s/^(.).*$/$1/;
	
	my $out = sprintf "HEX %x / DEC ", ord $char;
	$out .= ord $char;
}

#these airtime bits are mostly code by tristan.willy@gmail.com
sub airtimes {
	my $max = $_[-1];
	my $scraper = new HTML::Scrape(
	Machine =>
		[
			{ 'label'   => 'top',
			'tag'     => 'table',
			'require' => { 'summary' => qr/currently airing/i } },
			{ 'tag'     => 'table' },
			{ 'tag'     => 'th' },

			[ { 'label'   => 'next_row',
			'tag'     => 'tr' },
			{ 'tag'     => 'table',
			'goto'    => 'top' }
			],
			{ 'label'   => 'td_nr',
			'tag'     => 'td' },
			{ 'text'    => put('nr') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('series') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('season') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('station') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('company') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('airtime') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('ETA') },
			{ 'tag'     => 'td' },
			{ 'text'    => put('eps') },
			[ 
			{ 'tag'     => 'a',
			'require' => { 'href' => qr/anidb.info/i },
			'attr'    => { 'href' => put('anidb_url') },
			'commit'  => 1,  # commit happens when leaving state
			'goto'    => 'next_row' },
			{ 'tag'     => 'tr',
			'commit'  => 1,
			'goto'    => 'td_nr' },
			{ 'tag'     => 'table',
			'goto'    => 'top' }
			]
		]
	) or die;
	my $page = $ua->get('http://www.mahou.org/Showtime/');
	die $page->status_line unless $page->is_success;
	if ($max =~ /\D/){
		return tsv(4, $scraper->scrape($page->decoded_content, 1));
	} elsif ($max == 0 || $max < 13) {
		return tsv($max-1, $scraper->scrape($page->decoded_content, 1));
	}
}
sub tsv {
  my %header;
  my $max = shift;
  foreach my $item (@_){
    $header{$_} = 1 foreach (keys %$item);
  }
  my @order = sort keys %header;

  my %inorder;
#  $inorder{sprintf "%020d", 1} = sprintf "%-12s%-18s%-25s%-18s%-4s%4s %-10s%-30s%s", @order[0..$#order]; #header, not sure if necessary
  
  foreach my $item (@_){
	
    my %ditem = fillkeys($item, @order);
	
	my @out;
	for (@order[0..$#order]){
		$ditem{$_} =~ s{^http://anidb\S+?(\d+)$}{http://anidb.net/a$1};
		push @out, $ditem{$_};
	}
	my $time = $ditem{$order[0]};
	$time =~ s/(?:(\d+)d\s*)?(?:(\d+)h\s*)?(\d+)m/(($1 ? $1 * 1440 : 0)+($2 ? $2 * 60 : 0)+($3))/e; #convert '1d 3h 33m' to '1653' (minutes)
	$time = sprintf "%020d", $time; #crude, but it makes sort stop being retarded
#	$inorder{$time} = sprintf "%-12s%-18s%-25s%-18s%-4s%4s %-10s%-30s%s", @out;
	$inorder{$time} = $out[0].' until '.$out[-2];
  }
  my @output;
  for ((sort keys %inorder)[0..$max]){
	push @output, $inorder{$_}."\n"
  }
  return \@output;
}
sub fillkeys {
  my $href = shift;
  return map { ($_, defined $href->{$_} ? $href->{$_} : '') } @_;
}

sub readtext {
	my $tgt;
	given ($_[0]){
		when (/farnsworth/i){	$tgt = $listloc.'farnsworth.txt'; } #todo: make one $listloc in config
		when (/anim[eu]/i){		$tgt = $listloc.'animu.txt'; }		#and keep all the textfiles there
		default { return; }
	}
	my $req = $ua->get($tgt);
	return 'error: '.$req->status_line 
		unless $req->is_success;
	
	my @lines = split /[\r\n]+/, $req->content;
	return 'error: protospork is retarded' 
		if scalar @lines == 1;
	my $line = $lines[(int rand ($#lines + 1) - 1)];
	($line = uc $line) if ($_[0] eq uc $_[0]);
	
	#turns out URLs don't like to be uppercased
	$line =~ s/(HTTP\S+)/lc $1/eg;
	
	return $line;
}

sub anagram {
	my (@terms,@search);
	shift;
	for (@_){
		/^\+/ ? push @search, $_ : push @terms, $_;
	}
	
	my $url = URI->new('http://wordsmith.org/anagram/anagram.cgi?t=900&a=n&anagram='.(join '+', @terms))->canonical;
	print 'triggers: '.$url;
	my $req = $ua->get($url);
	return unless $req->is_success;
	
	$req->decoded_content =~ m!Displaying first \d+00:\s+</b><br>(.+?)<br>\s+<bottomlinks>!s;
	my @results = (split /\n?<br>\n?/, $1);
	print $#results;
	
	my @spam;
	if ($#search){
		my $count = 1;
		for (@results){
			last if $count > 10;
			if ($_ =~ /$search[0]/i){ #yeah, so I'm ignoring any other searches
				$count++;
				push @spam, $_;
			}
		}
	} else {
		@spam = @results[0..10];
	}
	$#spam ? return join ', ', @spam : return;
}

sub choose { 
	my $call = shift;
	my (@choices, $pipes);
	if ($call =~ /sins?/){
		@choices = qw'greed gluttony wrath sloth lust envy pride';
	} elsif ($call =~ /8ball$/i && $#choices){
		@choices = (
			"It is certain", "It is decidedly so", "Without a doubt", "Yes definitely",
			"You may rely on it", "As I see it, yes", "Most likely", "Outlook good", "Signs point to yes", "Very doubtful",
			"Yes", "Reply hazy, try again", "Ask again later", "Better not tell you now", "Cannot predict now",
			"Concentrate and ask again", "Don't count on it", "My reply is no", "My sources say no", "Outlook not so good"
		);
	} elsif ($call =~ /8ballunsure/i && $#choices){
		@choices = (
			"Reply hazy, try again", "Ask again later", "Better not tell you now", "Cannot predict now",
			"Concentrate and ask again"
		);
	} elsif ((join ' ', @_) =~ /\|/){
		@choices = (split /\|\s*/, (join ' ', @_));
		$pipes++;
	} elsif ((join ' ', (@_)) =~ /,/){
		@choices = (split /,\s*/, (join ' ', (@_)));
	} else {
		scalar @_ >= 2 ? @choices = @_ : return 'it helps to have something to choose from';
	}
	#halve the likelihood of choosing something awful
	my @choices2 = @choices; #infinite loop otherwise (OOPS LMAO)
	for my $choice (@choices2){
		push @choices, $choice unless grep $choice =~ /$_/i, @donotwant;
	}
	
	return 'gee I don\'t know, '.$meanthings[(int rand scalar @meanthings)-1] 
		if scalar @choices == 1;
	
	my %chcs; #choose 1, 1, 1, 1, 1
	for (@choices){ $chcs{$_}++; }
	if (scalar keys %chcs == 1){
		return ':| '.$meanthings[(int rand scalar @meanthings)-1];
	}
	
	#hehe
	# return 'Nah' if int rand 100 <= 4;
	
	my $return = $choices[(int rand ($#choices + 1))-1];
	if ($return =~ /,/ && $pipes){ return choose('choose', (split /, /, $return)); } # now choices can be nested!
	else { return $return; }
}

sub countdown {

	if (! @_ || scalar @_ == 0){ #help message
		return (join ', ', keys %timers);
	}
	print $_[-1] if $debug;
	print $timers{uc $_[-1]}.' - '.time || 'AAAH';
	if ($timers{uc $_[-1]}){
		my $until = $timers{uc $_[-1]} - time;
		return $_[-1].' already happened' if $until < 0;
		my $string;
		if ($until > 604800){ $string = int($until / 604800).' weeks '; $until = $until % 604800; }
		if ($until > 86400){ $string .= int($until / 86400).' days '; $until = $until % 86400; }
		if ($until > 3600){ $string .= int($until / 3600).' hours '; $until = $until % 3600; }
		if ($until > 60){ $string .= int($until / 60).' minutes '; $until = $until % 60; }
		return ($string.'until '.$_[0]);
	} else {
		return lc(join ', ', keys %timers);
	}
}

sub conversion { #this doens't really work except for money
	#only works with three inputs
#	my ($trig, $in, $out) = @_;

	#works with two or three inputs
	my $trig = uc shift;
	my $in = uc shift;
	$in =~ s/to$//; #wha
	my $out;
	print join ', ', ($trig,$in) if $debug;
	if (defined $_[0] && $debug == 1){ $out = uc $_[0]; print '=> '.$out; }
	
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
	} elsif ($out eq 'MSP'){
		my $num; ($num,$in) = ($in =~ /([\d.]+)\s*(\D+)/);
		if ($in =~ /USD$/){
			my $base = ($num/4.99);
			if ($base < 1){
				return ((sprintf "%d", (($base)*400)).'MSP, but you\'d need to buy at least 400 for $4.99');
			} else {
				my $ideal = (sprintf "%d", (($base)*400));
				my $real = (sprintf "%d", ((($base)*400)-((($base)*400)%400)+400));
				my $realcost = (sprintf "%.02f", (($real/400)*4.99));
				
				($real-400) == $ideal 
					? return $num.$in.' is '.$real.'MSP'
					: return $num.$in.' is ideally '.$ideal.'MSP, but here in reality you\'ll pay '.$realcost.'USD for '.$real.'MSP';
			}
			return ':<';
		} else {
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
	
	#\x3c / \x3e are <>. \x25#215; is &#215; is �
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
	$server->command("nick ".$botnick);
	sleep 4;
	$server->command("msg nickserv identify ".$botpass);
}
sub stats {
	my ($chan) = @_;
	return if $chan !~ /(anime|moap|cfounders|programming)/i;
	$chan = $1; $chan =~ s/anime/animu/;
	$chan eq 'programming' ? return 'http://www.galador.org/irc/'.$chan.'.html' : return 'http://protospork.moap.net/'.$chan.'.html';
}

#based on a script called weatherbot.pl by lyz@princessleia.com
my %savedloc;
tie my @memory, 'Tie::File', $ENV{HOME}.'/.irssi/scripts/cfg/weathernicks.cfg' or die $!; #this fucking file is ...interesting. and broken. fix it.
for (@memory){ my @why = split /::/, $_; $savedloc{$why[0]} = $why[1]; } #why not just tie a hash?

sub weather {	
#	my ($server, $nick, $text) = @_;
#	$nick = lc $nick;
	my ($server,$nick) = (shift, lc shift);
	my $text = '';
	$text = join ' ', @_[1..$#_] if $#_ > 0; #huh, typing that made me think twice
	
	my $location;
	if ($text eq ''){ 
		if (exists $savedloc{$nick}){
			$location = $savedloc{$nick}
		} else {
			$server->command("notice $nick Could you please repeat that?"); 
			return; 
		} 
	} else { 
		$location = $text; 
	}
	
	$location =~ s/ /_/g; $location =~ s/,//g;

	my $results = $ua->get("http://38.102.136.104/auto/raw/$location");
	my @badarray = split(/\n/, $results->decoded_content);
	if ( ! $results->is_success ) {
		$server->command ( "notice $nick .w [zipcode|city, state|airport code] - if you can't get anything, search http://www.faacodes.com/ for an airport code" );
		return;
	} elsif ( $results->content =~ /[<>]|^\s*$/ ) {
		$server->command ( "notice $nick .w [zipcode|city, state|airport code] - if you can't get anything, search http://www.faacodes.com/ for an airport code" );
		return;
	} else {
		push @memory, (join '::', $nick, $location); #todo: don't push if it's already in there
		$savedloc{$nick} = $location;
		my @goodarray = split(/[|]\s*/, $results->decoded_content);
		my ($timestamp,$ctemp) = ($goodarray[0],'');
		$timestamp =~ s/(\d\d?:\d\d \wM \w\w\w).+/$1/;
		my ($town, $state, $weather, $ftemp, $hum, $bar, $wind, $windchill) = 
#		($goodarray[18], $goodarray[19], $goodarray[8], $goodarray[1], $goodarray[4], $goodarray[7], $goodarray[6], $goodarray[2]);	#augh
		@goodarray[18,19,8,1,4,7,6,2];
		if ($ftemp ne "") { $ctemp = sprintf( "%4.1f", ($ftemp - 32) * (5 / 9) ); }
		$ctemp =~ s/ //;
		if ($wind !~ / 0$/){
			if ($ftemp < 40 && $windchill !~ /N.A/){
				return ("\002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | Windchill $windchill\xB0F | Wind $wind MPH");
			} else {
				return ("\002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | $hum Humidity | Wind $wind MPH");
			}
		} else {
			return ("\002$town, $state\002 ($timestamp): $ftemp\xB0F/$ctemp\xB0C - $weather | $hum Humidity | Barometer: $bar");
		}
	}
}
Irssi::signal_add("event privmsg", "event_privmsg");
