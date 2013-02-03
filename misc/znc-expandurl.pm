# look up full-length URLs for tinyurls
#note to myself: ZNC modlib is in /usr/lib/znc

use LWP;
use Modern::Perl; #replace this with `use strict; use warnings;` if you don't have cpan access
use HTML::ExtractMeta; #new
use URI;
package expandurl;
use base 'ZNC::Module';



#this doesn't need to be a global. w/e
my @abouttext =	("This module quietly looks up shortened URLs and replaces them in chat ".
				"with their full-length targets.", "This will introduce latency, so you ".
				"may not want it active everywhere - especially if you're running znc on".
				" a residential connection.", "When loaded on a network, link unwrapping".
				" will (currently) be active in every channel.");
				
my $debug = 0; #these two do need to be globals
my @last50;
my $ua = LWP::UserAgent->new( max_size => 450); 

sub description {
    "Deshortens short URLs"
}
sub OnChanMsg {
    my $self = shift;
    my ($nick, $chan, $msg) = @_;
	my $outmask = $nick->GetNick.'!'.$nick->GetIdent.'@'.$nick->GetHost;	
	
	$chan = $chan->GetName; #does a channel object even have any other methods?
	
	#todo: make this loop. right now it only fixes the first link
	if ($msg =~ m{(http://\S+)}){
		my $url = $1;
		
		$self->PutModule("$outmask: $url") if $debug;
		
		my $req = $ua->head($url);
		if (!$req->is_success){
			$self->PutModule($url.': HTTP '.$req->code) if $debug;
		}
		
		my $meta = HTML::ExtractMeta->new(html => $req->decoded_content);
		my $orig_url = $meta->get_url(); #nice and all, but doesn't work enough of the time
		
		if (!$orig_url){
			my ($orig_url,$second_last);
			for ($req->redirects){ #iterate over the redirect chain, but only keep the final one
				if ($_->header('Location') =~ m[nytimes.com/glogin|unsupportedbrowser]i){ 
				# NYT paywall redirects you according to some arcane logic that changes every week.
				# so the final hop (if you've been paywalled) is worthless and extremely long.
				# I don't look forward to adding special cases for 35253423 sites
					last;
				} else {
					$second_last = $orig_url;
					$orig_url = $_->header('Location');
				}
			}
			if ($orig_url =~ m{^(?:\.\.)?/}){ #sometimes relative links with .., generally just ^/ (absolute)
				# grab the domain from last hop and stick it here.
				$orig_url = URI->new_abs($orig_url, $second_last)->canonical;
			}
			if (! $orig_url){
				$self->PutModule("$url is actual url") if $debug;
				return $ZNC::CONTINUE;
			}
		}
		
		if (length $orig_url > 140){ 
			$self->PutModule("$orig_url is too long: ".(length $orig_url)."ch") if $debug;
			#-strip all queries (they tend to help so I'd rather leave them if possible)
			$orig_url->query(undef);
			$orig_url->query_form(undef); #isn't query() supposed to be a catch-all?
			#-check length again
			if (length $orig_url > 140){ 
				$self->PutModule("$orig_url is still too long: ".(length $orig_url)."ch") if $debug;
				return $ZNC::CONTINUE; 
			}

		}
		
		## trailing quote fix
		$orig_url =~ s/("|\x{2019}|\x{201d})$/ $1/;
		
		$self->PutModule(' => '.$orig_url) if $debug;
		$self->PutModule(scalar($req->redirects).' redirects') if $debug;
		
	# bitlbee returns the (incomplete and useless) preview url in angle brackets after the t.co one
	# in any other situation this should just do the replace without touching the rest of the line
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
#-I have no idea how znc builds web pages. (maybe http://people.znc.in/~psychon/znc/doc/classCWebSubPage.html is relevant?)
sub GetWebMenuTitle { 
    "ExpandURL"
}



1;