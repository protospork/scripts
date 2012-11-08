use Modern::Perl;
use File::Slurp;
use URI::Escape;
use JSON;
use LWP;

#grab twitter's search api response, maybe do some filtering, dump them in a text file
#YOU WILL NEED TO EDIT THE FINAL LIST. Foreigners use twitter too. Also I never added any dupe detection.

#the only line you need to change.
my $mode = 0;

my @modes = (
	["#natesilverfacts", "#natesilverfacts -RT since=2012-11-06", "X:\\My Dropbox\\Public\\misc\\txt\\natesilver.txt"],
);

my $url = "http://search.twitter.com/search.json?q=".uri_escape_utf8($modes[$mode][1]);

my $req = LWP::UserAgent->new()->get($url);
die $req->status_line unless $req->is_success;

my $mess = decode_json $req->decoded_content; #I think it's a hashref
my $results = $mess->{'results'}; #but this should be an arrayref

#say $results->[$_]{'text'} for (0..$#{$results});
say $#{$results}." results";

my (@facts, @todo);
push @todo, $results->[$_]{'text'} for (0..$#{$results});

for (@todo){
	s/$modes[$mode][0]//is; #strip hashtag
	s/\s+/ /g; #strip doublespaces from last line, and any newlines
	
	s/(?<!\n)$/\n/;
	
	if (/https?:/){ #news stories are boring
		next;
	} else {
		push @facts, $_;
	}
}

#now write that file
write_file($modes[$mode][2], {append => 1, binmode => ':utf8'}, @facts);