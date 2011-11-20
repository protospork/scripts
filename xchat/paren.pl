#HELLO, I AM AN XCHAT SCRIPT! YOU NEED PERL FOR ME!
use strict;
use warnings;
use Xchat qw( :all );
my $ver = 1.70;
register('parentheses', $ver, "fixes parentheses in URLs", \&unload);
hook_print("Channel Message", \&everything, {priority => PRI_LOW});
hook_print("Channel Msg Hilight", \&hilight, {priority => PRI_LOW});
hook_print("Channel Action", \&acting, {priority => PRI_LOW});
hook_print("Channel Action Hilight", \&actinghigh, {priority => PRI_LOW});

my $sprinkles = 1; #make this 0 to turn every color effect into boring green
my $boring = 0;    #make this 1 to disable all color effects, even the green
my $nico = 0;      #make this 1 to translate youtube URLs to niconico ones
my $ytshorten = 1; #make this 0 to leave youtube urls completely untouched

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
	return EAT_NONE if $channel =~ /tosho-api/;
	
	my $clr = 23;
	if ($sprinkles){ $clr = xccolor($nick) }

	if ($nico == 1){
		$message =~ s{(?:http://)?(?:www\.)?youtube.com/watch\?v=([^\s&#]{11})[^\s>#]*}{http://youtu.be/$1 (http://video.niconico.com/watch/ut$1)}ig;
	} elsif ($ytshorten == 1){
		$message =~ s{(?:http://)?(?:www\.)?youtube.com/watch\?v=([^\s&#]{11})[^\s>#]*}{http://youtu.be/$1}ig;
	}
	
	$message =~ s/=([<>^_-]{3,})=/$1/g;	#keitoshi
	$message =~ s/(\s?)(http\S+?)\((.+?)\)(.*)\s?/$1$2\%28$3\%29$4/g; #urls with parentheses in them
	$message =~ s/^[!.@](list|find|\w+?\d\d?|crc).*$//i; #dirty leechers
	$message =~ s/[\x{201c}\x{201d}]/"/g; #god knows whether  this actually works
	
	#ascii:
	#[:alpha:] [:alnum:] [:digit:] [:punct:]
	#unicode: 
	#\p{L} matches anything intended as a letter
	#\p{P} for punctuation
	#\p{S} random symbols not in {P}
	#[\p{Hiragana}\p{Katakana}\p{Han}] should match all japanese script
	
	#colored >quotes
	$message =~ s/^>(?!_>)(.+)$/\x03$clr>$1\x0F/;
	#colored symbols (hey why not)
	unless ($message =~ /\x{03}|^\s*$/ || $net =~ /freenode|none/i || $red || $nick =~ /\Q$mynick\E/ || $boring == 1){ #don't code colors if colors were already coded
		my @end;
		for (split /\s+/, $message){ 
			if (/\x{02}/){ push @end, $_; next; }
			if (/http|^www/i){ #MOTHERFUCKING URLS
				s/^([<(]+)((http|www)\S+\.\S+)$/\003$clr$1\x0F$2/ig; #working around outstanding firefox bugs woo
				s/(http\S+?)([)>]+)$/$1\003$clr$2\x0F/ig;
				push @end, $_; 
				next; 
			}

			
			s/(
				^[<(](?=http)|
				^[^[:alnum:]#@]+(?=[[:alnum:]])|
				^D:$|
				^[><_]{3,}$|
				(?<=[[:alnum:]])[^[:alnum:]]+$|
				[^[:alnum:]#@_]+|
				(?<=[:;<=])[PpDoOVv3](?!\d))
			/\x{03}$clr$1\017/gx unless /^[<@]\S+[>:,]$/; #why is the second-to-last match block there?
			
			s/(?<=\d)\x03$clr:\x0F(?=\d)/:/g; #don't like the colored : in timestamps
			
			
			#I'm trying to avoid checking every word against /names, which wouldn't work in #twitter anyway
			if (/^(?:"?\@|<[~&!@%+ ]?)([[:alnum:]|\[\]_`-]++)(?:[>:,]$|\x03\d\d)?/){ #quotes are already color quoted so that first bit doesn't work
				$_ = "\x03".($sprinkles ? xccolor($1) : 23).$_."\x0F";
			}
			
			push @end, $_; 
		} 
#		$message = join ' ', @end;
		$" = ' '; #p sure this is the default, dunno if other scripts share the builtin vars
		$message = "@end";
		
		if ($message =~ /\x03(\d\d)(\w+)\x0F \x03(\d\d)/){ #this is halfassed as shit fix it later
			if ($1 eq $3){ #I'm trying to be nice to WDK's text renderer, god knows it's retarded enough without my help
				my ($one,$two) = ($1,$2); #so redundant colorcodes need to be stripped, although
				$message =~ s/$&/\x03$one$two /; #this method only grabs the first redundant one
			}
		}
	}
	
	if ($nick =~ /\Q$mynick\E$/){ #fixed events for 2+ clients on a bnc
		if ($action == 1){ emit_print('Your Action', $mynick, $message, $_[2]); } 
		else { emit_print('Your Message', $mynick, $message, $_[2], $_[3]); }
		return EAT_ALL;
	}
	
	unless ($message =~ /^\s*$/){ 
		if ($action == 1 && $red == 1){ emit_print('Channel Action Hilight', $nick, $message, $_[2]); }
		elsif ($action == 1){ 			emit_print('Channel Action', $nick, $message, $_[2]); }
		elsif ($red == 1){ 				emit_print('Channel Msg Hilight', $nick, $message, $_[2], $_[3]); }
		else { 							emit_print('Channel Message', $nick, $message, $_[2], $_[3]); }
	}
	return EAT_ALL;
}
sub xccolor {
	my $string = shift;
	#this is a translation of xchat's nick coloring algorithm
	my $clr = 0;
	$string =~ s/\x03\d{1,2}|\x0F//g;	
	$clr += ord $_ for (split //, $string); 
	$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];	
}
sub unload{
	prnt("paren $ver unloaded");
}
prnt("parentheses $ver loaded");