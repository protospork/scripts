package Protospork::Misc v0.0.2;
use Exporter::Easy (EXPORT => [qw(waaai unwrap_shortener xcc)]);

use LWP;
use URI;
use Modern::Perl;


my $debug = 1;
my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:10.0.7) Gecko/20100101 Firefox/10.0.7',
	max_size => 50000,
	timeout => 10,
	protocols_allowed => ['http', 'https'],
	'Accept-Encoding' => 'gzip,deflate',
	'Accept-Language' => 'en-us,en;q=0.5'
);


#link shortener
# waaai($url)
sub waaai {
	my $req = $ua->get('http://waa.ai/api.php?url='.$_[0]);
	if ($req->is_success && length $req->decoded_content < 24){
		say $_[0] if $debug;
		say "Shortened to ".$req->decoded_content if $debug;
		return $req->decoded_content;
	} else {
		warn "Shorten failed: HTTP ".$req->code." / ".$req->content_length."\n";
		return $_[0];
	}
}

#link deshortener
# unwrap_shortener($url)
#returns input url if something breaks, to avoid breaking anything else
sub unwrap_shortener {
	my $url = shift;
	
	my $req = $ua->head($url);
	if (!$req->is_success){
		warn 'Error '.$req->status_line if $debug; 
		return $url;	
	}
	my ($orig_url,$second_last);
	for ($req->redirects){ #iterate over the redirect chain, but only keep the final one
		if ($_->header('Location') =~ m[nytimes.com/glogin]i){ 
			#NYT paywall redirects you according to some arcane logic that changes every week.
			#so the final hop is worthless and extremely long.
			last;
		} else {
			$second_last = $orig_url;
			$orig_url = $_->header('Location');
		}
	}
	if (! $orig_url){
		$orig_url = $url;
	}
	
	print $url.' => '.$orig_url if $debug;
	
	#another script had an issue where the final link was often relative. 
	#this either prevents that or breaks everything
	if ($second_last){
		$orig_url = URI->new_abs($orig_url, $second_last)->canonical;
	}
		
	if (length $orig_url < 200){
		return $orig_url;
	} else {
		$orig_url->query(undef);
		$orig_url->query_form(undef);
		if (length($orig_url) < 200){
			return $orig_url;
		} else { 
			return $orig_url->host;
		}
	}
}

#xchat-alike nick coloring

# call with xcc($string) to just color the entire string that way (for <nick>)

# or call with xcc($string, {string => $string2}) to color $string2 whatever color 
# $string would have been (to semi-anonymize things I guess)

# or call with xcc($string, {raw => 1}) to just return the color code
sub xcc { 
	my ($source,$clr,$string,$brk) = (shift,0);
	
	my $opts = {};
	if (@_){ 
		$opts = shift; 
		if ($opts->{string}){
			$string = $opts->{string};
		}
	}
	if (! $string){
		$string = $source; 
		$brk++; #"brackets"
	}
	
	$clr += ord $_ for (split //, $source); 
	$clr = sprintf "%02d", qw'19 20 22 24 25 26 27 28 29'[$clr % 9];
	return $clr if $opts->{raw};
		
	if ($brk){ 
		$string = "\x03$clr<$string>\x0F"; 
	} else { 
		$string = "\x03$clr$string\x0F"; 
	}
		
	return $string;
}
'very yes';