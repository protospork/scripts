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
use Math::RPN;
use WWW::Wunderground::API;
use Encode;
use Finance::Quote;
# use Data::Dumper;

use vars qw($botnick $botpass $owner $listloc $tmdb_key $maxdicedisplayed %timers @yield_to
			@offchans @meanthings @repeat @animuchans @donotwant @dunno $debug $cfgver
			$promoted_bangs $lfm_key $lfm_secret $wa_appid $wu_apikey $trusted_masks
            $replace_google);
# #perl said to use 'our' instead of 'use vars'. it doesnt work because I am retarded

#you can call functions from this script as Irssi::Script::triggers::function(); or something
#protip: if you're storing nicks in a hash, make sure to `lc` them

#<alfalfa> obviously c8h10n4o2 should be programmed to look for .au in hostmasks and then return all requests in upsidedown text

# <+Decitron> .spaghettiO
# <+Decitron> Say something.
# <+Decitron> say something
# <SpaghettiO> Beej, really. not i'll go again before Halo 5 chimpout"
# <~anime_reference> I don't have quote submission built into every trigger but that is something possible for the future


$VERSION = "2.11.1";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'triggers',
    description => 'a trigger script',
    license => 'MIT/X11'
);


tie my %lastfms, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/lastfm.po' or die $!;
tie my %savedloc, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/weathernicks.po' or die $!;
tie my %rosescores, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/rosescores.po' or die $!;

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
sub loadgettitle {
	return 'fuck off' unless $_[-1] =~ /$trusted_masks/;
	$_[0]->command('script load gettitle.pl');
	return 'k';
}

sub event_privmsg {
	my ($server, $data, $nick, $mask) = @_;
	my ($target, $text) = split(/ :/, $data, 2);
	my $return;

	loadconfig() if time - $lastcfgcheck > 86400;
	return if grep lc $target eq lc $_, (@offchans);

	#has .rose timed out yet?
	no warnings "uninitialized"; #jesus christ SHUT UP
	if (time - $rose->[1] > 1800){
		$rose->[0] = 0;
		$rose->[1] = 1;
	}
	use warnings "uninitialized";

	my @terms;
	if ($text =~ /^\s*\.(.+?)\s*$/){ #make sure it's a trigger
		@terms = split /\s+/, $1;
	} elsif ($text =~ /$botnick/i){
		if ($text =~ /^\s*$botnick[:,]\s*(\w+.*)\?\s*$/i){ #I hate you, future self
			my $choices = $1;
			my @query = split /\s+/, $choices;
			if ($choices =~ s/\s+or\s+/, /ig){ #shortcut to .choose
				$server->command('msg '.$target.' '.(choose('choose', (split /\s+/, $choices))));
				return;
			} elsif ($query[0] =~ /wh([oy]|at|e(n|re))|how/i){ #stupid 8ball
				$server->command('msg '.$target.' '.(choose(qw'8ballunsure some junk data')));
				return;
			} else { #straightup 8ball
				$server->command('msg '.$target.' '.(choose(qw'8ball some junk data')));
				return;
			}
		} elsif ($text =~ /^\s*\w+.+\s+$botnick\?\s*$/i){ #this needs to be re-integrated with the last regex sometime
			$server->command('msg '.$target.' '.(choose(qw'8ball some junk data')));
			return;
		} else {
			return;
		}
	} elsif (time - $rose->[1] < 1800 && $text =~ /^$rose->[0]$/){ #1/2 hour is still probably too long a timeout
		$rosescores{$target}{$nick}++;
		tied(%rosescores)->save;
		return_rose_scores($target, $nick, $rose, $server, 0);
		$rose = undef;
		return;
	} elsif ($text =~ /\b(http\S+\.[jpengif]{3,4})\b/ig){
		$last{$target} = $1;
		return;
	} elsif ($text =~ /shatter/ && ($text =~ /weed/ || $nick =~ /pieceofnothing/i)){
		$server->command('msg '.$target.' shut up');
		return;
	} else {
		return;
	}

	given ($terms[0]){
		when (/^flip$|^ro(se|ll)$/i){	$return = dice([$target, $nick, $rose, $server],@terms); }
		when (/^sins?$|^choose$|^guess$|^8ball$/i){	$return = choose(@terms); }
		when (/^(farnsworth|bender|anim[eu]|natesilver(?:facts?)?|krieger|archer|pam|c(?:aro|hery)l|lana)|hooters?|homer|swanson|dukesilver$/i){ $return = readtext(@terms); }
		when (/^(boobs|owl|butt)s?$/i){ 	$return = check_for_submission($server, $nick, @terms); } #prob expand this to quote triggers too eventually
		when (/^identify$/i){		$return = ident($server); }
		when (/^i(?:mgops)?$/){		$return = imgops($target, @terms); }
		when (/^rehash$/i){			$return = loadconfig(); }
		when (/^titles$/i){			$return = loadgettitle($server, $mask); }
		when (/^!\S+$|^gs$|^ddg$/i){$return = ddg($target, @terms); }
        when (/^g$|^wiki$|^amzn$|^yt$/i){
            $return = ddg($target, @terms) if $replace_google;
        }
		# <sugoidesune> I think I'm going to go through those triggers and remove the ! from the ones that work right
		when ($promoted_bangs){
			$terms[0] = '!'.$terms[0];
			$return = ddg($target, @terms);
			$return =~ s/ /%20/g;
		}
		when (/^hex$/i){			$return = ($nick.': '.(sprintf "%x", $terms[1])); }
		when (/^help$/i){			$return = 'https://github.com/protospork/scripts/blob/master/irssi/README.md' }
		when (/^cvt$|^xe?$/i){		$return = conversion(@terms); }
		when (/^rpn$/i){			$return = rpn_calc(@terms); }
        when (/^aspect$/i){         $return = aspect(@terms); }
		when (/^w(eather|x)?$/i){
			if ($#terms >= 1 && $terms[1] =~ s/^\@//){
				$nick = pop @terms;
			}
			$return = weather_fallback($server, $nick, @terms);
		}
		when (/^isup$/){			$return = isup(@terms); }
		when (/^ord$|^utf8$/i){		$return = codepoint($terms[1]); }
		when (/^l(?:ast)?fm$/i){	$return = lastfm($server, $nick, @terms); }
		when (/^drinkify$/i){		$return = drinkify($nick, @terms); }
		when (/^time$/i){			$return = wa(@terms); }
		when (/^mirror$|^gfycat$/){ $return = gfycat($terms[1], $nick, $target, $server); }
		when (/^flight$/){			$return = 'https://flightaware.com/live/flight/'.$terms[1]; }
        when (/^space$/){           $return = space(@terms); }
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
sub space {
    my $req = $ua->get("https://launchlibrary.net/1.2/launch/next/8");
    print (length $req->decoded_content) if $debug;

    my $json;
    eval { $json = JSON->new->utf8->decode($req->decoded_content); };
    if ($@){ return "uh oh - ".$req->status_line; }

    my %outlines;
    my $count = $json->{'total'}; #we javascript now
    my $launches = $json->{'launches'};
    #error checking what's that
    while ($count >= 0){
        $count--;
        my $this = $launches->[$count];
        if ($this->{'tbddate'} == 1){ #date isn't actually set, fuck yall
            next;
        }
        my $tmp;
    #    say join ', ', keys %{$this};
        $tmp = $this->{'name'};
        $tmp .= " || ".$this->{'net'};
        $tmp .= " || ".$this->{'location'}{'name'};
        $tmp .= " || ".(join " / ", @{$this->{'vidURLs'}});

        $outlines{$this->{'id'}} = $tmp;
    }
    my @go;
    for (sort keys %outlines){ #I'm having issues with duplicate ID/entries appearing, and with sorting
        unshift @go, $outlines{$_};
    }
    return \@go;
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
sub ddg {
	my $target = shift;
	my $trigger = shift;
	my @terms;

	#use the last url posted in the channel as input. really intended for .gis
	if (@_){ #it wouldn't let me use the shorthand for some reason
		@terms = @_;
	} else {
		@terms = ($last{$target});
	}

	if ($trigger =~ /^!/){ #whoops put trigger back if it's part of the query
		unshift @terms, $trigger;
	}
	my $feelinglucky;

    given (lc $trigger){
        when (/yt/){
            unshift @terms, '\site:youtube.com';
        }
        when (/wiki/){
            unshift @terms, '\site:en.wikipedia.org';
        }
        when (/amzn/){
            unshift @terms, '\site:amazon.com';
        }
        when (/^g$/){
            #why did I do this
            #unshift @terms, '\site:google.com';
        }
        default {
            #nothing changes
        }
    }

	if ($trigger =~ /^g$/i && $terms[0] !~ /^[!\\]/){ #.g = first result; .gs/.ddg = index
		$terms[0] = '\\'.$terms[0];
	}
	if ($terms[0] =~ /^[\\!]/){
		$feelinglucky++;
	}
	for (@terms){ #I don't understand why this exists? why not use an actual url encoder?
     #no seriously, URLs with unicode in them are unclickable in hexchat
		$_ =~ s/\+/%2B/g;
	}
	print "@terms" if $debug;
	my $query = ('http://ddg.gg/?q='.(join '+', @terms).'&kp=-1'); #kp=-1 is to disable safesearch

	if (! $feelinglucky){
		return $query;
	}

	my $skipgrab;
	#time out. google's urls are actually so long they overload the url shortener's API
	# $skipgrab tells the script not to pull the link and follow it through redirects
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
	#and then re-encode spaces wtf
	$orig_url =~ s/\s/%20/g;

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

	if ($_[1] =~ /^\@(\w+)/){
		if (exists $savedloc{$1}){
			$_[1] = $savedloc{$1}
		} else {
			return "who dat";
		}
	}
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
		when (/bender/i){ $tgt = $listloc.'bender.txt'; }
		when (/anim[eu]/i){	$tgt = $listloc.'animu.txt'; }
		when (/natesilver/i){ $tgt = $listloc.'natesilver.txt'; }
		when (/krieger/i){ $tgt = $listloc.'krieger.txt'; }
		when (/archer/i){ $tgt = $listloc.'archer.txt'; }
		when (/pam/i){ $tgt = $listloc.'pam.txt'; }
		when (/carol|cheryl/i){ $tgt = $listloc.'carol.txt'; }
		when (/lana/i){ $tgt = $listloc.'lana.txt'; }
		when (/boobs/i){ $tgt = $listloc.'boobs.txt'; }
		when (/owl/i){ $tgt = $listloc.'owls.txt'; }
		when (/butt/i){ $tgt = $listloc.'dickbutt.txt'; }
		when (/homer/i){ $tgt = $listloc.'homer.txt'; }
		when (/swanson|dukesilver/i){ $tgt = $listloc.'swanson.txt'; }
		when (/hooters?/i){
			if ((int rand 99) % 2){
				$tgt = $listloc.'owls.txt';
			} else {
				$tgt = $listloc.'boobs.txt';
			}
		}
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
sub rpn_calc {
	my @those = @_;
	for (@those){
		s/,//g;
	}
	my $terms = join ',', @those;
	$terms =~ s/rpn,//; #hurr

	if (length $terms > 50){
		return "that looks a little ridiculous";
	}

	my $out;
	eval { $out = rpn($terms); };
	if ($@){ return $@; }

	return $out;
}
sub aspect {
#todo:
#   -highlight if both dimensions are mod16
#   -display a nearby mod16 resolution if not, somehow
    my $in = join ' ', @_;
    my ($dim, $dir, $shape) = ($in =~ /(\d+)([hw])\s*([0-9:-]+)/);
    my ($w, $h) = split /[:-]/, $shape;
    my $out = $dim; my $wid = 0; my $hgt = 0;
    # given (lc $dir){
    #     when('w'){ $out = (sprintf "%02dx%02d", ($dim, ($out / $w * $h))); }
    #     when('h'){ $out = (sprintf "%02dx%02d", (($out / $h * $w), $dim)); }
    #     default { $out = 'what' }
    # }
    # return $out;
    given (lc $dir){
        when ('w'){
            $wid = $dim;
            $hgt = $dim / $w * $h;
        }
        when ('h'){
            $wid = $dim / $h * $w;
            $hgt = $dim;
        }
        default {
            $wid = 'HELP';
            $hgt = 'HELP';
        }
    }
    return (mod16_check($wid).'x'.mod16_check($hgt));
}
sub mod16_check {
    my $n = shift;
    return if $n !~ /^[.\d]+$/;

    my $out = "\x{03}";
    if ($n % 16 == 0){
        $out .= '03';
    } else {
        $out .= '04';
    }
    $out .= sprintf "%02d", $n;
    $out .= "\x{03}";
    return $out;
}

sub conversion { #this is for money
	my $trig = uc shift;
    my $amt = uc shift;
	my ($in,$out) = (0,0);
    for (@_){
        next if $_ =~ /^to$/i;
        if ($in eq '0'){
            $in = $_;
        } else {
            $out = $_;
        }
    }
    if ($out eq '0'){ $out = 'USD'; }

	print join ', ', ($amt,$in, scalar @_) if $debug;
	print '=> '.$out if $debug;

    if (length $in != 3 || length $out != 3){
        return 'you fucked up';
    }

    my $q = Finance::Quote->new();
    my $rate = $q->currency($in, $out);

    if ($rate == 0){
        return 'https://en.wikipedia.org/wiki/ISO_4217#Active_codes';
    }

    return "$amt $in is ".($rate * $amt)." $out probably";
}
sub utfdecode { #why
	my $x = my $y = uri_unescape($_[0]);
	return $x if utf8::decode($x);
	return $y;
}
sub dice {
	my $params = shift;
	my $flavor = lc $_[0];
	if ($flavor eq 'rose'){
		if ($_[1] && $_[1] =~ /score/){
			return_rose_scores(@$params, 1);
			return;
		}
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
        my $die = $_[1];
        if ($die =~ /^d/i){ $die = '1'.$die; } #assume 1 if unspecified
        my @xdy = split /d/i, $_[1];
		s/\D// for @xdy;
		if (! $xdy[1]){ #assume it's a d6
			$xdy[1] = 6;
		}

		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] <= 1;
		return ':| '.$meanthings[int(rand($#meanthings))-1] if $xdy[1] > 999;
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
	if ($_[-1] == 0){
		$_[-2]->command("msg $_[0] $_[1] is correct: ".$_[2][0]);
	} else {
		my @out;

		for (keys %{$rosescores{$_[0]}}){
			push @out, ((sprintf "%02d", $rosescores{$_[0]}{$_}).' - '.$_);
		}
		no warnings 'numeric';
		@out = reverse sort { $a <=> $b } @out;
		my $t;
		$#out > 5 ? $t = 5 : $t = $#out;
		$_[-2]->command("msg $_[0] ".(join '; ', @out[0..$t]));
	}
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
	if ($slug =~ /"gfyname":"([^"]+)"/i){ #these params randomly go in/out of camelCase
		($hash) = ($1);
	} else {
		return $slug;
	}

	# no longer necessary?
	# my $pub = $ua->get('http://gfycat.com/ajax/publish/'.$hash);
	# return $pub->status_line." while publishing" unless $pub->is_success;

	my $gfylink = 'http://gfycat.com/'.$hash;

	$server->command("msg $chan $url => $gfylink");
	return;
}

sub weather_fallback {
	my ($server,$nick) = (shift, lc shift);
	my $text = '';
	if ($#_ > 0){ $text = join ' ', @_[1..$#_]; } ##pulling from 1 on b/c 0 is the trigger
	if ($nick eq '.'){
		$nick = (keys %savedloc)[rand keys %savedloc];
	}

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

	my $w = new WWW::Wunderground::API(
		api_key => $wu_apikey,
		location => $location,
		auto_api => 1,
	);

	# print $w->conditions->location->city || return "fffffffffuck";

	my $when;
	eval { $when = $w->conditions->observation_time; };
	if ($@ || ! $when){ return "$@ ($location isn't a place?)"; }
	$when =~ s/^.+?, //;

	$savedloc{$nick} = $location;
	tied(%savedloc)->save;

	# print Dumper($w->data);

	my $out = "\x{02}".$w->conditions->observation_location->full."\x{02} "."($when): ";

	if ($w->conditions->observation_location->country =~ /^US$/){
		$out .= $w->conditions->temp_f."\x{B0}F/".$w->conditions->temp_c."\x{B0}C - ";
	} else {
		$out .= $w->conditions->temp_c."\x{B0}C/".$w->conditions->temp_f."\x{B0}F - ";
	}

	my $thing = $w->conditions->weather;
	$thing =~ s/Drizzle/[Snoop Dogg joke]/ if int rand 100 <= 5;
	$thing =~ s/.*Snow.*/Snowpocalypse/ if int rand 100 <= 10;
	$thing =~ s/Heavy Rain/Shauuuuuuuuuuuuuuuuuuuuun/ if int rand 100 <= 50;
	$thing =~ s/.*Thunder.*/Thunderbolts and Lightning/ if int rand 100 <= 75;


	$out .= $thing." | ";

	if ($w->conditions->windchill_f =~ /NA/){
		$out .= $w->conditions->relative_humidity.' Humidity | ';
	} else {
		$out .= 'Windchill '.$w->conditions->windchill_f."\x{B0}F | ";
	}

	my $wind = $w->conditions->wind_string;
	$wind =~ s/From the/Wind/;
	$wind =~ s/MPH Gusting to/->/;
	$wind =~ s{([0-9.]+) -> ([0-9.]+) MPH}{$1 eq $2 ? "$1 MPH" : "$1 -> $2 MPH"}e;
	if ($wind =~ /Calm/){
		$wind = "Barometer: ".$w->conditions->pressure_mb;
	}

	$out .= $wind;

	$out = encode('UTF-8', $out);

	return $out;
}
Irssi::signal_add("event privmsg", "event_privmsg");
