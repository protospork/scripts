use Modern::Perl;
use LWP;
use URI;

say "throw in a phrase to jumble";
my $text = <STDIN>;

my $ua = LWP::UserAgent->new('show_progress' => 1);

my $url = URI->new('http://wordsmith.org/anagram/anagram.cgi?t=900&a=n&anagram='.(join '+', (split /\s+/, $text)))->canonical;
say $url;

my $req = $ua->get($url);
die $req->status_line unless $req->is_success;

$req->decoded_content =~ m!Displaying first \d+00:\n</b><br>(.+?)<br>\s+<bottomlinks>!s;
my @results = (split /\n?<br>\n?/, $1);

say "searchword?";
my $search = <STDIN>;
$search =~ /\s+/gs;
chomp $search;

if ($search eq 'no'){
	say "printing first 25";
	for (@results[0..25]){
		say $_;
	}
} else {
	say "looking";
	my $count = 1;
	for (@results){
		exit "limit hit" if $count > 25;
		if ($_ =~ /$search/i){
			$count++;
			say $_;
		}
	}
}