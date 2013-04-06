#HELLO, I AM AN XCHAT SCRIPT! YOU NEED PERL FOR ME!
use strict;
use warnings;
use Xchat qw( :all );
use v5.10;
my $ver = 1.110;
register('parentheses', $ver, "does a lot more than fix parentheses in URLs", \&unload);
hook_print("Channel Message", \&everything, {priority => PRI_LOW});
hook_print("Channel Msg Hilight", \&hilight, {priority => PRI_LOW});
hook_print("Channel Action", \&acting, {priority => PRI_LOW});
hook_print("Channel Action Hilight", \&actinghigh, {priority => PRI_LOW});

#COLORS
my $sprinkles = 1; #make this 0 to turn every color effect into boring green
my $boring = 0;    #make this 1 to disable all color effects, even the green
#re: those past two options - greentext is enabled no matter what, but it turns to nick-color if $sprinkles = 1
my $colornicks = 1;#will find <quotes> and @mentions and color the nicks as xchat would
my $BNCfix = 1;    #talking from two clients on a BNC? this'll treat any line from your nick as from your client

#LINKS
my $ytshorten = 1; #make this 0 to leave youtube urls completely untouched
my $ytembed = 1;   #make this 1 to rewrite youtube urls to the fullscreen /embed/ version. overrules ytshorten
my $wikimobile = 0;#rewrite wikipedia links to use the (nicer) mobile layout
my $deHTTPS = 1;   #fix for opera's installer being slightly stupid
my $intents = 1;   #convert twitter userpage links into twitter intent links. usually all you need anyway
my $linkbucks = 1; #many (all?) linkbucks links are just some junk prepended to a valid URL. this'll strip that

my $deshortentwitter = 1; #not perfect, but does what it does solely through text manipulation (no web calls, no UI lag)

#ELSE
my $hideDCC = 1;   #I don't need to see what people are downloading.
my $badcracks = 1;
my $hilights = 1; #you'll need to change $server and $homechan in &highlighter


#I'm sure there's a nicer way to do this bit
my ($red,$action) = (0,0);
sub everything {
	($red,$action) = (0,0);
	magic_happens(@{$_[0]});
}
sub hilight {
	($red,$action) = (1,0);
	magic_happens(@{$_[0]});
}
sub acting {
	($red,$action) = (0,1);
	magic_happens(@{$_[0]});
}
sub actinghigh {
	($red,$action) = (1,1);
	magic_happens(@{$_[0]});
}

sub magic_happens {
	my $channel = get_info('channel');
	my $mynick = get_info('nick');
	my $net = get_info('network') || 'none';
	my ($nick,$message) = ($_[0],$_[1]);
	return EAT_NONE unless $message;

	if ($red && $hilights){ highlighter($nick,$message); }

	return EAT_NONE if $channel =~ /tosho-api|newsflash/;
	return EAT_NONE if $message =~ /^\[(\d\d:){2}\d\d\]/; #znc playback

	my $clr = 23;
	if ($sprinkles){ $clr = xccolor($nick) }

	if ($badcracks && $message =~ /^(Under SEH Team$|\x{41c}\x{44b}|Ìû(?:\x{18}|[^ -~]))$/){
		$nick =~ s/^\x03\d\d?//;
		prnt("\x0326,20".$net.':'.$channel." \x03".xccolor($nick).',26<'.$nick.">\x07\x0301,26".$message, '#fridge', 'irc.adelais.net');
		command("msg $nick Your shitty XChat crack is spamming us.\x07Install the free build from http://www.hexchat.org/");
		command("notice $nick Your shitty XChat crack is spamming us.\x07Install the free build from http://www.hexchat.org/");
		return EAT_NONE;
	}

	if ($deshortentwitter){
		$message =~ s{https?://t\.co/\S+ <([^>\x{2026}]+)>}{http://$1}g;
	}

	if ($ytembed){
		$message =~ s{(?:https?://)?(?:(?:www\.)?youtube.com/watch\?v=|youtu.be/)([^\s&#]{11})[^\s>#]*}{http://youtube.com/embed/$1}g;
	} elsif ($ytshorten){
		$message =~ s{(?:https?://)?(?:www\.)?youtube.com/watch\?v=([^\s&#]{11})[^\s>#]*}{http://youtu.be/$1}ig;
	}

	if ($wikimobile){
		$message =~ s{(?:https?://)?en\.wikipedia\.org/wiki/(\S+)}{http://en.m.wikipedia.org/wiki/$1}gi;
	}
	if ($deHTTPS){
		$message =~ s{https://}{http://}g; #sometimes opera won't default itself for https urls
	}
	if ($hideDCC){
		$message =~ s/^[!.@](list|find|\w+?\d\d?|crc).*$//i if $net =~ /rizon/i; #dirty leechers
	}
	if ($intents){
		$message =~ s{http://(?:www\.)?twitter\.com/([^/?#]+)(?=\s|$)}{http://twitter.com/intent/user?screen_name=$1}g;
	}
	if ($linkbucks){
		if ($message =~ s{https?://(?:[0-9a-f]+\.)?linkbucks\.com/url/(http://\S+)}{$1}g){
			$message =~ s/%([0-9A-Fa-f]{2})/$1 eq '20' ? '%'.$1	: chr(hex($1))/eg; #this regex is at the core of URI::Escape
		}
	}

	$message =~ s/=([<>^_-]{3,})=/$1/g;	#keitoshi
	$message =~ s/\b:C\b/:(/ig; #also keitoshi
	$message =~ s/(\s?)(http\S+?)\((.+?)\)(.*)\s?/$1$2\%28$3\%29$4/g; #urls with parentheses in them
	$message =~ s/[\x{201c}\x{201d}]/"/g; #god knows whether this actually works


	#ascii:
	#[:alpha:] [:alnum:] [:digit:] [:punct:]
	#unicode:
	#\p{L} matches anything intended as a letter
	#\p{P} for punctuation
	#\p{S} random symbols not in {P}
	#[\p{Hiragana}\p{Katakana}\p{Han}] should match all japanese script

	#colored >quotes
	$message =~ s/^>(?![._]>)(.+)$/\x03$clr>$1\x0F/;
	#colored symbols (hey why not)
	unless ($message =~ /\x{03}|^\s*$/ #don't code colors if colors were already coded
	|| $net =~ /freenode|criten|none/i #or if it's going to kill readability
	|| $red							   #or if you've been highlighted
	|| $nick =~ /\Q$mynick\E/ 		   #or if it'll interfere with $BNCfix
	|| $boring == 1					   #or if you don't like fun
	){
		my @end;
		for (split /\s+/, $message){ #what if I split on /\b/?
			if (/\x{02}/){ push @end, $_; next; }
			if (/^http|^www|^ed2k/i){ #MOTHERFUCKING URLS
				s/^([<(]+)((http|www)\S+\.\S+)$/\003$clr$1\x0F$2/ig; #working around outstanding firefox bugs woo
				s/(http\S+?)([)>]+)$/$1\003$clr$2\x0F/ig;
				push @end, $_;
				next;
			}

			#todo: avoid applying this regex to anyone in /names. can that be done efficiently?
			#- it needs to pull names anyway for ln156 so w/e
			s/(
				^[<(](?=http)|
				^[^[:alnum:]#@]+(?=[[:alnum:]])|
				^D:$|
				^[><_]{3,}$|
				(?<=[[:alnum:]])[^[:alnum:]]+$|
				[^[:alnum:]#@_]+|
				(?<=[:;<=])[PpDoOVv3](?!\d))
			/\x{03}$clr$1\017/gx unless /^(?:[."]?[<@])\S+[>:,]$/; #why is the second-to-last match block there?

			s/(?<=\d\d)\x03$clr:\x0F(?=\d\d)/:/g; #don't like the colored : in timestamps


			#I'm trying to avoid checking every word against /names, which wouldn't work in #twitter anyway
			if (/^(?:[."]?\@|<[~&!@%+ ]?)([[:alnum:]|\[\]_`-]++)(?:[>:,]$|\x03\d\d)?/ && $colornicks){ #quotes are already color quoted so that first bit doesn't work
				$_ = "\x03".($sprinkles ? xccolor($1) : 23).$_."\x0F";
			}

			push @end, $_;
		}
		$" = ' '; #p sure this is the default, dunno if other scripts share the builtin vars
		$message = "@end";

		#this is halfassed as shit fix it later
		if ($message =~ /\x03(\d\d)(\w+)\x0F \x03(\d\d)/){
			if ($1 eq $3){ #I'm trying to be nice to WDK's text renderer, god knows it's retarded enough without my help
				my ($one,$two) = ($1,$2); #so redundant colorcodes need to be stripped, although
				$message =~ s/$&/\x03$one$two /g; #this method only grabs the first redundant one
			}
		}
	}

	if ($nick =~ /\Q$mynick\E$/ && $BNCfix){ #fixed events for 2+ clients on a bnc
		if ($action == 1){ emit_print('Your Action', $mynick, $message, $_[2]); }
		else { emit_print('Your Message', $mynick, $message, $_[2], $_[3]); }
		return EAT_ALL;
	}
	if ($channel eq '#tac'){
		no warnings 'uninitialized';
		my $term = "\x03";
		if ($message =~ /\x030?1,0?1/){
			$term = "\x0301,01";
		}

		given ($nick){
			when (/aria/i){
				$message =~ s/cock/\x03,20the$term/gi;
				$message =~ s/schlick(ed)?/if ($1 eq 'ed'){ "\x03,20fapped$term" } else { "\x03,20fap$term" }/eg;
			}
			when (/shou|murasa/i){
				$message =~ s/hold(ing)? hands/\x03,20fuck$1$term/gi; #holded hands or hold handsed?
				$message =~ s/(?<=god )kiss|kiss(?= it)/\x03,20damn$term/gi;
				$message =~ s/cute butt/\x03,20shit$term/gi; #why
				$message =~ s/(?<=what the )Gensokyo/\x03,20hell$term/gi;
			}
			default {
				#nothing
			}
		}
		use warnings 'uninitialized';
	}

	unless ($message =~ /^\s*$/){
		if ($action == 1 && $red == 1){ emit_print('Channel Action Hilight', $nick, $message, $_[2]); }
		elsif ($action == 1){ 			emit_print('Channel Action', $nick, $message, $_[2]); }
		elsif ($red == 1){ 				emit_print('Channel Msg Hilight', $nick, $message, $_[2], $_[3]); }
		else { 							emit_print('Channel Message', $nick, $message, $_[2], $_[3]); }
	}
	return EAT_ALL;
}
sub highlighter {
	my ($whom,$text) = @_;
	my $dest = get_info('channel');
	my $serv = get_info('server');
	my ($server,$homechan) = ('irc.adelais.net','#fridge');
	prnt("\x03".xccolor($whom).$whom."\x0F\t".$text." (\x0304".$dest."\x0F, \x0304".$serv."\x0F)", $homechan, $server);
	return;
}
sub xccolor { 	#this is a translation of xchat's nick coloring algorithm
	my $string = shift;
	my $clr = 0;
	$string =~ s/\x03\d{1,2}|\x0F//g;
	$clr += ord $_ for (split //, $string);
	$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];
}
sub unload {
	prnt("paren $ver unloaded");
}
prnt("parentheses $ver loaded");
