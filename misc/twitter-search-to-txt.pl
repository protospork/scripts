use Modern::Perl;
use File::Slurp;
use URI::Escape;
use JSON;
use LWP;

#grab twitter's search api response, maybe do some filtering, dump them in a text file
#YOU WILL NEED TO EDIT THE FINAL LIST. Foreigners use twitter too. Also I never added any dupe detection.

#also what the fuck why did it stop working

my $mode = $ARGV[0];

my @modes = (
	["#natesilverfacts", "#natesilverfacts -RT since=2012-11-06", "X:\\My Dropbox\\Public\\misc\\txt\\natesilver.txt"],
	["#drunknatesilver", "#drunknatesilver -RT since=2012-11-06", "X:\\My Dropbox\\Public\\misc\\txt\\drunknatesilver.txt"],
);

my $url = "http://search.twitter.com/search.json?q=".uri_escape_utf8($modes[$mode][1]);

my $req = LWP::UserAgent->new(agent => 'Mozilla/5.0 (X11; U; Linux; i686; en-US; rv:1.9.0.13) Gecko/2009073022 Firefox/3.0.13')->get($url);
die $req->status_line unless $req->is_success;


my $mess = decode_json $req->decoded_content; #I think it's a hashref
my $results = $mess->{'results'}; #but this should be an arrayref

my (@facts, @todo);
push @todo, $results->[$_]{'text'} for (0..$#{$results});

say $_ for (0..$#todo);
say $#todo." results";

for (@todo){
	s/$modes[$mode][0]//is; #strip hashtag
	s/\s+/ /g; #strip doublespaces from last line, and any newlines
	
	s/(?<!\n)$/\n/;
	
	if (/https?:/){ #news stories are boring
		print "Skipped: ".$_;
		next;
	} else {
		push @facts, $_;
	}
}

#now write that file
write_file($modes[$mode][2], {append => 1, binmode => ':utf8'}, @facts);