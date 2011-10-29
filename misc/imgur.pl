use Modern::Perl;
use LWP;
use LWP::Simple;
use File::Path qw(make_path);
use HTML::TreeBuilder;
#imgur album rip script

#todo: can't trigger pages past 1

my $album = $ARGV[0] || die "give it a URL";

if ($album =~ m{/a/}){
	$album =~ s{/\d$|#\w+$}{};	#remove page numbers to get down to the root of the album
	$album .= "/all" unless $album =~ m{/all$}i;	#now go back to the index page
}
say $album;
my $page = LWP::UserAgent->new()->get($album) or die "$!";
die $page->status_line unless $page->is_success;

my $albumname = HTML::TreeBuilder->new_from_content($page->decoded_content)->look_down(_tag => 'title')->as_text;
$albumname =~ s/^\s*(.+?) - Imgur.*$/$1/;

if ($albumname =~ /^(Photo Albums|Album)$/){
	$albumname = $album;
	$albumname =~ s{^.+com/(?:a/)?([^\s/]+)(?:/all)?}{$1}i;	
}
#my @imagehashes = ($page =~ /http\S+\/([a-zA-Z0-9]{5,6})s\.jpg/ig);
my @imagehashes = ($page->decoded_content =~ /<div id="([a-zA-Z0-9]{5})" class="post">/ig);
say ((1 + $#imagehashes).' images');
length $albumname > 120 ? die 'broken albumname parse' : say $albumname;
downloadalbum();

sub downloadalbum {
	make_path("imgur/".$albumname);	#for some reason mkdir doesn't work.
	chdir("imgur/".$albumname);
	my @files = glob "*";	#dupe detection database
	my ($counter, $dupe) = (0, 0);
	for (@imagehashes){ 
		$counter += 1;
		my $newfilename = ((sprintf "%03d", $counter) . "_" . $_ . ".jpg");
		for(@files){ 
			next if $_ ne $newfilename;
			$dupe = 1;
		}
		if ($dupe == 1){ print("$_ :: Duplicate\n"); $dupe = 0; next; }
		my $status = getstore("http://i.imgur.com/" . $_ . ".jpg", $newfilename); 
		print("$_ :: $newfilename :: $status\n");
	}
}
print $albumname;