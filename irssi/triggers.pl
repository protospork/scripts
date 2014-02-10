use Irssi;
use Modern::Perl;
use LWP;
use URI;
use URI::Escape qw'uri_escape_utf8 uri_unescape';
use HTML::TreeBuilder;
use HTML::Query;
use HTML::Entities;
use utf8;
use vars qw($VERSION %IRSSI);
use JSON;
use Tie::YAML;
use File::Path qw'make_path';
use WWW::WolframAlpha;
use URI::Escape;
#use TMDB;

use vars qw($botnick $botpass $owner $listloc $tmdb_key $maxdicedisplayed %timers @yield_to
			@offchans @meanthings @repeat @animuchans @donotwant @dunno $debug $cfgver
			$promoted_bangs $lfm_key $lfm_secret $wa_appid);	# #perl said to use 'our' instead of 'use vars'. it doesnt work because I am retarded

#you can call functions from this script as Irssi::Script::triggers::function(); or something
#protip: if you're storing nicks in a hash, make sure to `lc` them

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text



$VERSION = "2.8.0";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'triggers',
    description => 'a trigger script',
    license => 'MIT/X11'
);

my $json = JSON->new->utf8;
my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox 17.0',
	max_size => 50000,
	timeout => 10,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5'
);
my ($lastcfgcheck,$animulastgrab,$rose) = (0,time,[0,1]);
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/triggers.pm';
my %last; #keep track of the most recent image linked in each channel, for pronoun use
my $tries;

sub loadconfig {
	unless (-e $ENV{HOME}."/.irssi/scripts/cfg/"){ #should I make sure it's a directory as well?
		make_path($ENV{HOME}."/.irssi/scripts/cfg/");
	}
	my $req = $ua->get($cfgurl, ':content_file' => $ENV{HOME}."/.irssi/scripts/cfg/triggers.pm");
		unless ($req->is_success){
			print $req->status_line;
			$tries++;
			loadconfig() unless $tries > 2;
		}

	$tries = 0;
	do $ENV{HOME}.'/.irssi/scripts/cfg/triggers.pm';
		unless ($cfgver =~ /./){ print "error loading variables from triggers cfg: $@" }

	print "triggers: config $cfgver successfully loaded";
	$lastcfgcheck = time;
	return $cfgver;
}
loadconfig();

tie my %rosescores, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/rosescores.po' or die $!;
sub event_privmsg {
	my ($server, $data, $nick, $mask) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	my $return;

	loadconfig() if time - $lastcfgcheck > 86400;
	return if grep lc $target eq lc $_, (@offchans);

	#has .rose timed out yet?
	if (time - $rose->[1] > 1800){
		$rose->[0] = 0;
		$rose->[1] = 1;
	}

	my @terms;
	if ($text =~ /^\s*\.(.+?)\s*$/){ #make sure it's a trigger
		@terms = split /\s+/, $1;
	} elsif ($text =~ /$botnick/i){
		if ($text =~ /^\s*$botnick[:,]\s*(\w+.*)\?\s*$/i){ #I hate you, future self
			my $choices = $1;
			my @query = split /\s+/, $choices;
			if ($choices =~ s/\s+or\s+/, /ig){ #shortcut to .choose
				$server->command('msg '.$target.' '.(choose('choose', (split /\s+/, $choices))));
			} elsif ($query[0] =~ /wh([oy]|at|e(n|re))|how/i){ #stupid 8ball
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
	} elsif (time - $rose->[1] < 1800 && $text =~ /^$rose->[0]$/){ #1/2 hour is still probably too long a timeout
		$rosescores{$target}{$nick}++;
		tied(%rosescores)->save;
		return_rose_scores($target, $nick, $rose, $server);
		$rose = undef;
		return;
	} elsif ($text =~ /\b(http\S+)\b/ig){
		if ($1 =~ /[jpengif]{3,4}(?:\?\S+)?\b/){
			$last{$target}{'img'} = $1;
		} else {
			$last{$target}{'link'} = $1;
		}
		return;
	} else {
		return;
	}

	given ($terms[0]){
		when (/^flip$|^ro(se|ll)$/i){	$return = dice(@terms); }
		when (/^sins?$|^choose$|^guess$|^8ball$/i){	$return = choose(@terms); }
		when (/^(farnsworth|anim[eu]|natesilver(?:facts?)?|krieger|archer|pam|c(?:aro|hery)l|lana)$/i){ $return = readtext(@terms); }
		when (/boobs/i){ 			$return = check_for_submission($server, $nick, @terms); } #prob expand this to quote triggers too eventually
		when (/^identify$/i){		$return = ident($server); }
		when (/^i(?:mgops)?$/){		$return = imgops($target, @terms); }
		when (/^rehash$/i){			$return = loadconfig(); }
		when (/^when$/i){			$return = countdown(@terms); }
		when (/^!\S+$|^gs$|^ddg$/i){$return = ddg($target, @terms); }
		# <sugoidesune> I think I'm going to go through those triggers and remove the ! from the ones that work right
		when ($promoted_bangs){
			$terms[0] = '!'.$terms[0];
			$return = ddg($target, @terms);
		}
		when (/^hex$/i){			$return = ($nick.': '.(sprintf "%x", $terms[1])); }
		when (/^help$/i){			$return = 'https://github.com/protospork/scripts/blob/master/irssi/README.md' }
		when (/^c(alc|vt)?$|^xe?$/i){$return = conversion(@terms); }
		when (/^w(eather)?$/i){		$return = weather($server, $nick, @terms); }
		when (/^isup$/){			$return = isup(@terms); }
		when (/^ord$|^utf8$/i){		$return = codepoint($terms[1]); }
	#api is down?	when (/^tmdb/i){			moviedb($server, $target, @terms); return; } #multiline responses
		when (/^l(?:ast)?fm$/i){	$return = lastfm($server, $nick, @terms); }
		when (/^ai(?:rtimes?)?$/i){ $return = [airtimes(@terms)] unless $target =~ /#tac/i; }
		when (/^drinkify$/i){		$return = drinkify($nick, @terms); }
		when (/^shorten$/i){		$return = waaai($last{$target}{'link'}); }
		when (/^time$/i){			$return = wa(@terms); }
		when (/^mirror$|^gfycat$/){ $return = gfycat($terms[1], $nick, $target, $server); }
		default { return; }
	}
	if (! defined $return){
		return;
	}
	elsif (ref $return){
		my $top = 3;
		if ($#{$return} < $top - 1){ $top = $#{$return}; }
		for (@$return[0..3]){
			$server->command('msg '.$target.' '.$_) if $_;
		}
	}
	else {
		if (int rand 1000 <= 2){ $return =~ s/ /\x{07}/; } # I'm sorry I had to
		$server->command('msg '.$target.' '.$return);
	}
}

sub check_for_submission {	#provides a (really ghetto) item submission routine for the readtext stuff
	my ($server, $nick, $trigger) = (shift, shift, shift);

	if (! $_[0] || ($_[0] =~ /submit|add/ && ! $_[1])){ #I don't expect that second case often, really
		return readtext($trigger);
	} elsif ("@_" !~ /http/){
		return "I don't see a picture.";
	}

	my $nag = 'msg memoserv send '.$owner.' Content submission from '.$nick.' for .'.$trigger.': '."@_";
	if ($server->{usermode} !~ /r/){ #you can't send memos unless you're identified I THINK
		return "Please find protospork, give him your link(s), and make him fix the bot.";
	}

	$server->command($nag);
	return "Submitted, probably.";
}

sub imgops {
	my $query = 'http://imgops.com/';
	if ($_[2]){
		$query .= $_[2];
	} else {
		$query .= $last{$_[0]}{'img'};
	}
	if (length $query > 80){
		$query = waaai($query);
	}
	return $query;
}

my %drinks; #tying this to disk really doesn't seem worthwhile
sub drinkify { #UNIRONICALLY WRITTEN WHILE DRINKING
	my $nick = shift;
	my $terms = join ' ', map { $_ = ucfirst $_ } @_[1..$#_];

	if (! $terms || length $terms < 3){ #<1 would probs work I don't know
		return;
	}

	my $artist = $terms;
	$terms = ('http://drinkify.org/'.(uri_escape_utf8($terms)));
	print $terms if $debug;

	if ($drinks{$terms}){
		if ($drinks{$terms} ne 'nope'){
			return $drinks{$terms};
		} else {
			return;
		}
	} else {
		my $req = $ua->get($terms);
		if (! $req->is_success){
			print 'drinkify: '.$req->code.' uhoh';
			$drinks{$terms} = 'nope';
			return;
		}

		my $page = HTML::TreeBuilder->new_from_content($req->decoded_content);
		my $booze = $page->look_down(_tag => 'ul', class => 'recipe')->as_HTML; #sometimes it's a nested list and man, fuck it
		$booze =~ s{<ul class="recipe">|</ul>}{}g;
		$booze =~ s{(?:</li>)?\s*<li>}{; }g;
		$booze =~ s/\s+/ /g;
		$booze =~ s/^;\s+//g;
		$booze = decode_entities($booze);

		my $recipe = $page->look_down(_tag => "p", class => 'instructions')->as_trimmed_text;
		$recipe =~ s/\n/; /g; $recipe =~ s/\s+/ /g;
		$recipe = decode_entities($recipe);

		$drinks{$terms} = "\x{03}03$artist:[ \x{03}07\x{02}$booze\x{02}:\x{03}03 $recipe ]\x{03}01,01<$terms>";
		return $drinks{$terms};
	}
}
sub isup {
	my $url;
	print $_[-1];
	if ($_[-1] !~ /\./){
		return "That doesn't look like a URL.";
	} else {
		$url = $_[-1];
		$url =~ s{^https?://}{};
	}
	print $url;

	my $req = $ua->get('http://isup.me/'.$url);
	return $req->code.' uhoh' unless $req->is_success;

	my $status = (HTML::Query->new(text => $req->decoded_content)->query('div#container')->get_elements())[0]->as_trimmed_text;
	$status =~ s{^.+?just you[!.] | Check.+$|^Huh? |(?<=interwho\.).+$}{}g;
	return $status;
}
sub airtimes {
	my $trigger = shift;
	my $query = shift || 0;
	my $atdebug = 0;

	print "query = $query" if $atdebug;

	#load mahou
	my $req = $ua->get('http://www.mahou.org/Showtime/?o=ET');
	return $req->code unless $req->is_success;
	print "mahou ".$req->code if $atdebug;

	my $tree = HTML::TreeBuilder->new_from_content($req->decoded_content);
	my $table = $tree->look_down(_tag => 'table', summary => 'Currently Airing')->look_down(_tag => 'table');
	return "proto can't write perl for shit" unless $table;
	#parse it, build a list of shows
	my @rows = $table->look_down(_tag => 'tr');
	print "$#rows rows" if $atdebug;
	my @shows;
	for my $row (@rows){
		next if $row->look_down(_tag => 'th'); #the header row
		my @boxes = $row->look_down(_tag => 'td');
		my $i = 9;
		while ($i){
			$i--;
			eval {
				if ($i == 8){
					if ($boxes[$i]){
						$boxes[$i] = ${$boxes[$i]->extract_links}[0][0]; #how did I get myself into this
						$boxes[$i] =~ s{.+?(\d+)$}{http://anidb.net/a$1};
					} else {
						$boxes[$i] = 'Error';
					}
				} else {
					if (! $boxes[$i] || $boxes[$i]->is_empty){ $boxes[$i] = 'Error'; }
					else { $boxes[$i] = $boxes[$i]->as_trimmed_text; }
				}
			};
			if ($@){
				$tree = $tree->delete;
				return $@;
			}
		}
		eval {
			push @shows, {
					title => ($boxes[1]),
					season => ($boxes[2]),
					station => ($boxes[3]),
					studio => ($boxes[4]),
					slot => ($boxes[5]),
					eta => ($boxes[6]),
					numeps => ($boxes[7]),
					links => ($boxes[8]),
			};
			print "show added: ".$boxes[1] if $atdebug;
		};
		if ($@){
			$tree = $tree->delete;
			return $@;
		}
	}
	#return an array or the top match to the query
	my @retlines;
	my @fmt = qw(Title Slot ETA Links);
	if ($query){
		for (@shows){
			if ($_->{'title'} =~ /$query/i){
				push @retlines, $_;
				print "found match: ".$_->{'title'} if $atdebug;
			}
		}
	} else {
		@retlines = @shows;
	}
	return "no match" unless @retlines;
	for my $line (@retlines){
		my $out;
		for (@fmt){
			$out .= "\x0303".$_.":[\x0307 ".$line->{lc $_}." \x0303] ";
		}
		$line = $out;
	}
	$tree = $tree->delete;
	return @retlines;
}

sub ddg {
	my $target = shift;
	my $trigger = shift;
	my @terms;

	#use the last url posted in the channel as input. really intended for .gis
	if (@_){ #it wouldn't let me use the shorthand for some reason
		@terms = @_;
	} else {
		@terms = ($last{$target}{'img'});
	}

	if ($trigger =~ /^!/){ #whoops put trigger back if it's part of the query
		unshift @terms, $trigger;
	}
	my $feelinglucky;

	if ($trigger =~ /^ddg$/i && $terms[0] !~ /^[!\\]/){ #.ddg = first result; .gs = index
		$terms[0] = '\\'.$terms[0];
	}
	if ($terms[0] =~ /^[\\!]/){
		$feelinglucky++;
	}
	for (@terms){
		print $_;
		$_ =~ s/\+/%2B/g;
		print $_;
	}
	print for @terms;
	my $query = ('http://ddg.gg/?q='.(join '+', @terms).'&kp=-1'); #kp=-1 is to disable safesearch

	if (! $feelinglucky){
		return $query;
	}

	my $skipgrab;
	#time out. google's urls are actually so long they overload the url shortener's API
	if ($trigger =~ /^!gis/i){
		$query = 'http://images.google.com/searchbyimage?image_url='.$terms[1];
		$skipgrab++;
	}

	#k go
	my $orig_url;
	if (! $skipgrab){
		my $req = $ua->get($query);
		if (!$req->is_success){
		print ('DDG: '.$query.': HTTP '.$req->code) if $debug;
		return $query;
		}
		$orig_url = $query;

		if ($req->header('Refresh')){ #duckduckgo uses a soft redirect (to record impressions?) so we need to grab html
		$orig_url = $req->header('Refresh');
		$orig_url =~ s/^.*?(http\S+).*?$/$1/i;
		}
		$req = $ua->get($orig_url); #now grab that url and follow its redirects, because it's probably a landing page

		for ($req->redirects){
			unless ($_->header('Location') =~ /duckduckgo|search?tbs=sbi:/){ #second is google's ridic base64 search page
				$orig_url = $_->header('Location');
			}
		}
	} else {
		$orig_url = $query;
	}

	#I need to scrub the url encoding out of those
	$orig_url = uri_unescape $orig_url;

	if (length $orig_url > 80){
		$orig_url = waaai($orig_url);
	}

	return $orig_url;
}

sub wa { #wolfram alpha, for now just used for .time
# for manually testing new features:
# http://api.wolframalpha.com/v2/query?format=plaintext&input=time%20in%20singapore&appid=
# http://products.wolframalpha.com/api/documentation.html
	my $wa = WWW::WolframAlpha->new(appid => $wa_appid);
	my $input = (join ' ', @_[1..$#_]);
	print $input.' =>';
	if ($input =~ /^\s*$/){ return time; } #return unix time given no options
	my $q = $wa->query(
		input => 'time in '.$input,
		format => 'plaintext',
		podindex => 2
	);

	if ($q->success && $q->datatypes =~ /CalendarEvent/){
		for my $pod (@{$q->pods}){ #there are some boilerplate pods
			my $out = @{$pod->subpods}[0]->plaintext || next;
			print $out;
			return $out;
		}
	} elsif ($wa->error){
		return $wa->errmsg;
	} else {
		return $dunno[int rand $#dunno];
	}
}

sub waaai {
	my $req = $ua->get('http://waa.ai/api.php?url='.uri_escape_utf8($_[0]));
	if ($req->is_success && length $req->decoded_content < 24){
		print $_[0] if $debug;
		print "Shortened to ".$req->decoded_content if $debug;
		return $req->decoded_content;
	} else {
		print "Shorten failed: HTTP ".$req->code." / ".$req->content_length;
		return $_[0];
	}
}

tie my %lastfms, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/lastfm.po' or die $!;
sub lastfm {
	my ($server,$nick) = (shift, lc shift);
	my $text = '';
	shift; #dump the trigger
	$text = shift;
	my $account;
	if (! $text || $text eq ''){
		if (exists $lastfms{$nick}){
			$account = $lastfms{$nick}
		} else {
			$account = $nick;
		}
	} else {
		$account = $text;
	}

	my $title = lastfm_api($account);

	if (! $title || $title eq 'no account'){
		$server->command("notice $nick Shit's broke. Are you sure that was a valid last.fm username?");
		return;
	} else {
		$lastfms{$nick} = $account;
		tied(%lastfms)->save;
		return $title;
	}
}
sub lastfm_api {
	my $user = shift;
	my $url = 'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&limit=1&extended=1';
	$url .= '&user='.$user.'&api_key='.$lfm_key;

	my $req = $ua->get($url);
	return "uh oh" unless $req->is_success;

	my $json;
	eval { $json = JSON->new->utf8->decode($req->decoded_content); };
	if ($@){ return "uh oh - ".$req->status_line; }

	my $return;
	if ($json->{'message'} && $json->{'message'} =~ /no user/i){
		return "no account";
	} elsif ($json->{'recenttracks'}){
		my $recent;
		eval { $recent = $json->{'recenttracks'}{'track'}[0]; };
		if (! $recent || $@){
			eval { $recent = $json->{'recenttracks'}{'track'}; };
			if ($@){ return 'fuck'; }
		}

		my $loved = 0;
		eval { $loved = $recent->{'loved'}; };
		if ($loved){
			$return = "\x{03}13,01http://last.fm/user/".$user;
		} else {
			$return = 'http://last.fm/user/'.$user;
		}

		my $np = 0;
		eval { $np = $recent->{'@attr'}{'nowplaying'}; };
		if ($np){
			$return .= ' is listening to ';
		} else {
			$return .= ' last played ';
		}

		my ($artist,$song) = ('oops!', 'oops!');
		eval {
			$artist = $recent->{'artist'}{'name'};
			$song = $recent->{'name'};
		};
		if ($@){
			return 'no account'; #how did you get this far? what the hell is happening?
		}

		$return .=  $artist;
		if ($loved){
			$return .= " \x{2665} ".$song;
		} else {
			$return .= ' - '.$song;
		}

		return $return;
	} else {
		return 'oh no';
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

	if ($tmdb_key eq 'replaceme'){
		print "c8_tmdb_key not set.";
		return;
	}
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

sub readtext {
	my $tgt;
	given ($_[0]){
		when (/farnsworth/i){	$tgt = $listloc.'farnsworth.txt'; }
		when (/anim[eu]/i){	$tgt = $listloc.'animu.txt'; }
		when (/natesilver/i){ $tgt = $listloc.'natesilver.txt'; }
		when (/krieger/i){ $tgt = $listloc.'krieger.txt'; }
		when (/archer/i){ $tgt = $listloc.'archer.txt'; }
		when (/pam/i){ $tgt = $listloc.'pam.txt'; }
		when (/carol|cheryl/i){ $tgt = $listloc.'carol.txt'; }
		when (/lana/i){ $tgt = $listloc.'lana.txt'; }
		when (/boobs/i){ $tgt = $listloc.'boobs.txt'; }
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

	if (scalar @choices == 2 && int rand 100 <= 4){
		return 'both';
	}

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

	if ($in =~ /BTC$/ || $out eq 'BTC'){ #is bitcoincharts still alive even? because I could just pull this too
		my $prices = $ua->get('http://bitcoincharts.com/t/weighted_prices.json');
		return $prices->status_line unless $prices->is_success;

		my $junk;
		eval { $junk = JSON->new->utf8->decode($prices->decoded_content); };
		if ($@){ return 'BTC - uh-oh ('.$prices->status_line.')'.' '.$prices->content_type; }

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
	} else {
		return "google shut my api off sorry\x{03}01,01 (actually fuck you I'm not sorry)";
	}


	my $construct = 'http://www.google.com/ig/calculator?q='.uri_escape_utf8(lc $in);
	$construct .= '=?'.uri_escape_utf8(lc $out) if defined $out;

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
sub dice {
	my $flavor = lc $_[0];
	if ($flavor eq 'rose'){
		$rose->[0] = 0;
		my @throws = roll(5,6);
		for (@throws){
			$_ == 3
				? $rose->[0] += 2
				: $_ == 5
					? $rose->[0] += 4
					: $rose->[0] += 0;
		}
		$rose->[1] = time;
		return join ' ', @throws;
	} elsif ($flavor eq 'flip'){
		my ($toss) = (roll(1,6)); #6 sides? whatever
		if (($toss % 2)){
			$toss = 'heads';
		} else {
			$toss = 'tails';
		}

		return $toss;
	} elsif ($flavor eq 'roll'){
		my @xdy = split /d/i, $_[1];
		s/\D// for @xdy;
		if (! $xdy[1]){ #assume it's a d6
			$xdy[1] = 6;
		}

		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] <= 1;
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] > 99;
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[0] > 99;

		my @throws = roll(@xdy);
		my $total;

		for (@throws){
			$total += $_;
		}

		if ($xdy[0] == 1){
			return $throws[0];
		} elsif ($xdy[0] <= $maxdicedisplayed){
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
	if ($botpass eq 'replaceme'){
		print 'c8_password not set.';
		return;
	}
	$server->command("msg nickserv identify ".$botpass);
}
sub return_rose_scores {
	$_[-1]->command("msg $_[0] $_[1] is correct: ".$_[2][0]);
	my @out;

	for (keys %{$rosescores{$_[0]}}){
		push @out, ((sprintf "%02d", $rosescores{$_[0]}{$_}).' - '.$_);
	}
	no warnings 'numeric';
	@out = reverse sort { $a <=> $b } @out;
	my $t;
	$#out > 5 ? $t = 5 : $t = $#out;
	$_[-1]->command("msg $_[0] ".(join '; ', @out[0..$t]));
	return;
}

sub gfycat { # http://gfycat.com/api
	my ($url,$nick,$chan,$server) = @_;

	return unless $url =~ /\.gif$/i;

	# $server->command("msg $chan This may take up to 30 seconds");

	# $ua->timeout(30);

	my $fetch = 'http://upload.gfycat.com/transcode/'.((time % 10000).'c8').'?fetchUrl='.(uri_escape_utf8 $url);
	my $req = $ua->get($fetch); #that center stuff is b/c gfycat wants a random string

	# $ua->timeout(13);

	unless ($req->is_success){
		return ("$fetch error: ".($req->status_line).'. Try http://gfycat.com/fetch/'.$url);
	}
	my $slug = $req->content;		

	my ($hash,$size,$oldsize);
	if ($slug =~ /"gfyname":"([^"]+)","gfysize":(\d+),"gifsize":(\d+)/i){ #these params randomly go in/out of camelCase
		($hash,$size,$oldsize) = ($1,$2,$3);
	} else {
		return $slug;
	}

	for ($size,$oldsize){
		$_ /= 1048576;
		if ($_ =~ /\.\d\d(\d)/ && $1 >= 5){ #rounding, poorly
			$_ += 0.01;
		}
		$_ = sprintf "%.2fMB", $_;
	}

	# no longer necessary?
	# my $pub = $ua->get('http://gfycat.com/ajax/publish/'.$hash);
	# return $pub->status_line." while publishing" unless $pub->is_success;
	
	my $gfylink = 'http://gfycat.com/'.$hash;

	$server->command("msg $chan $url ($oldsize) => $gfylink ($size)");
	return;
}

#originally based on an xchat script called weatherbot.pl by lyz@princessleia.com. not sure if it still bears any resemblance
tie my %savedloc, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/weathernicks.po' or die $!;
sub weather {
	my ($server,$nick) = (shift, lc shift);
	my $text = '';
	$text = join ' ', @_[1..$#_] if $#_ > 0; ##pulling from 1 on b/c 0 is the trigger

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
		$server->command(
			"notice $nick .w [zipcode|city, state|airport code] - if you can't ".
			"get anything, search http://www.faacodes.com/ for an airport code"
		);
		return;
	} elsif ( $results->content =~ /[<>]|^\s*$/ ) {
		$server->command(
			"notice $nick .w [zipcode|city, state|airport code] - if you can't ".
			"get anything, search http://www.faacodes.com/ for an airport code"
		);
		return;
	} else {
		$savedloc{$nick} = $location;
		tied(%savedloc)->save;

		my @array = split(/[|]\s*/, $results->decoded_content);
		my ($timestamp,$ctemp) = ($array[0],'');
		$timestamp =~ s/(\d\d?:\d\d \wM \w\w\w).+/$1/;
		my ($town, $state, $weather, $ftemp, $hum, $bar, $wind, $windchill) = @array[18,19,8,1,4,7,6,2];
		$weather =~ s/Drizzle/[Snoop Dogg joke]/ if int rand 100 <= 5;
		$weather =~ s/.*Snow.*/Snowpocalypse/ if int rand 100 <= 10;

		if ($ftemp ne "") { $ctemp = sprintf( "%4.1f", ($ftemp - 32) * (5 / 9) ); }
		$ctemp =~ s/ //;

		my @out;
		if ($wind !~ m/ 0$/){
			if ($ftemp < 40 && $windchill !~ /N.A/){
				push @out,	("\002$town, $state\002 ($timestamp): ",
						" - $weather | Windchill $windchill\xB0F | Wind $wind MPH");
			} else {
				push @out,	("\002$town, $state\002 ($timestamp): ",
						" - $weather | $hum Humidity | Wind $wind MPH");
			}
		} else {
			push @out,	("\002$town, $state\002 ($timestamp): ",
					" - $weather | $hum Humidity | Barometer: $bar");
		}

		if ($array[22] =~ m/^[KP]/){ #america
			return $out[0]."$ftemp\xB0F/$ctemp\xB0C".$out[1];
		} else {
			return $out[0]."$ctemp\xB0C/$ftemp\xB0F".$out[1];
		}
	}
}
Irssi::signal_add("event privmsg", "event_privmsg");
