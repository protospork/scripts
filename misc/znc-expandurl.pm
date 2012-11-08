# look up full-length URLs for tinyurls
#note to myself: ZNC modlib is in /usr/lib/znc

use LWP;
use Modern::Perl;
use URI; #another dependency :(
package expandurl;
use base 'ZNC::Module';



#doesn't need to be a global. w/e
my @abouttext =	("This module quietly looks up shortened URLs and replaces them in chat ".
				"with their full-length targets.", "This will introduce latency, so you ".
				"may not want it active in every channel - I wrote it specifically for ".
				"twitter in Bitlbee and that's what the defaults reflect.");
				
my $debug = 0; #just for testing
my @last50;

sub description {
    "Deshortens short URLs"
}
sub OnChanMsg {
    my $self = shift;
    my ($nick, $chan, $msg) = @_;
	my $outmask = $nick->GetNick.'!'.$nick->GetIdent.'@'.$nick->GetHost;	
	my $ua = LWP::UserAgent->new( max_size => 450); 
	
	$chan = $chan->GetName; #does a channel object even have any other methods?
	
	#todo: make this loop. right now it only fixes the first link
	if ($msg =~ m{(http://\S+)}){
		my $url = $1;
		
		$self->PutModule("$outmask: $url") if $debug;
		
		my $req = $ua->head($url);
		if (!$req->is_success){
			$self->PutModule($url.': HTTP '.$req->code) if $debug;
		}
		my ($orig_url,$second_last);
		for ($req->redirects){ #iterate over the redirect chain, but only keep the final one
			if ($_->header('Location') =~ m[nytimes.com/glogin]i){ 
				#NYT paywall redirects you according to some arcane logic that changes every week.
				#Upshot: the final hop is worthless and extremely long.
				last;
			} else {
				$second_last = $orig_url;
				$orig_url = $_->header('Location');
			}
		}
		if ($orig_url =~ m{^(?:\.\.)?/}){ #sometimes relative links with .., generally just ^/ (absolute)
			#grab the domain from last hop and stick it here.
			$orig_url = URI->new_abs($orig_url, $second_last)->canonical;
		}
		if (! $orig_url){
			$self->PutModule("$url is actual url") if $debug;
			return $ZNC::CONTINUE;
		}
		if (length $orig_url > 140){ 
			$self->PutModule("$orig_url is too long: ".(length $orig_url)."ch") if $debug;
			#-strip all queries (they tend to help so I'd rather leave them if possible)
			$orig_url->query(undef);
			$orig_url->query_form(undef); #isn't query() supposed to be a catch-all?
			#-check length again
			if (length $orig_url > 140){ 
				return $ZNC::CONTINUE; 
				$self->PutModule("$orig_url is still too long: ".(length $orig_url)."ch") if $debug;
			}

		}
		
		$self->PutModule(' => '.$orig_url) if $debug;
		$self->PutModule(scalar($req->redirects).' redirects') if $debug;
		
		#bitlbee returns the (incomplete and useless) preview url in angle brackets after the t.co one
		$msg =~ s/$url(?: <[^>]+>)?/$orig_url/; 

		#add this URL to history and drop the oldest entry if necessary
		push @last50, [$url, $orig_url];
		shift @last50 if $#last50 > 49;
		
		#IRC output
		$self->PutUser(":$outmask PRIVMSG $chan :$msg");
		return $ZNC::HALT;
	} else {
		return $ZNC::CONTINUE;
	}
}
#in-irc config
sub OnModCommand {
	my ($self,$cmd) = @_;
	if ($cmd =~ /debug/i){
		$debug++;
		$debug %= 2;
		$debug 
		  ? $self->PutModule('Debug Enabled')
		  : $self->PutModule('Debug Disabled');
	} elsif ($cmd =~ /recent/i){
		$self->PutModule('Printing the 50 most recent URLs, oldest first.');
		$self->PutModule($_->[0].' => '.$_->[1]) for @last50;
	} else {
		$self->PutModule($_) for @abouttext;
	}
}

#todo: 
#-option to look up just t.co, known hosts, or check all links
#-input for user to edit known hosts
#-actually fucking figure out how the web interface builds pages seriously what the hell
sub GetWebMenuTitle { 
    "ExpandURL"
}



1;