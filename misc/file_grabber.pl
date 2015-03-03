#!perl

use Modern::Perl;
use File::Slurp;
use File::Util;
use Linux::Inotify2;
use Number::Bytes::Human 'format_bytes';
use LWP;
use Cwd 'cwd';

# scrape the directory for txt files, pull all the URLs from them, save those files

my $debug = 1;

my $inotify = new Linux::Inotify2
	or die "wait what $!";

my $fu = File::Util->new();
my $ua = LWP::UserAgent->new(
	agent => 'grabber.pl is not a bot (protospork@gmail.com)'
);
my $root = cwd;

say "Grabber started.";

$inotify->watch($root, IN_MOVE) #I think dropbox downloads files into temp and then moves them in when complete
	or die "can't watch that";

while () {
	my @events = $inotify->read;
	unless (@events > 0) {
		print "read error: $!";
		last ;
	}
	# printf "mask\t%d\n", $_->mask foreach @events;
	do_shit();
}





sub do_shit {

	my @lists = <*.txt>;

	for (@lists){
		my $dir = create_dir($_) 
			or return cleanup($_);
		chdir $dir;
		
		my @links = extract_links($_);
		my %out;

		for my $url (@links){
			my $name = $url;
			$name =~ s{^.+?/([^/]+)$}{$1}i;
			$name = $fu->escape_filename($name);

			say "grabbing $url" if $debug;

			my $resp = $ua->get($url, ':content_file' => $name);
			if ($resp->is_error){
				warn $url.' is probably broken';
			}

			my $size = $resp->content_length;
			$size = format_bytes($size);

			say "grabbed $name // $size" if $debug;

			$out{$url} = [$resp->code, $size];
		}

		say "batch complete; writing summary";
		write_summary(\%out);
		cleanup($_);
	}
}

sub create_dir {
	my $dir = $_[0];
	$dir =~ s/\.txt$//;

	say "creating $dir" if $debug;

	$fu->make_dir($dir, undef) # ADD AN ACTUAL CHECK WHETHER THE FOLDER ALREADY EXISTS AND DON'T CALL THAT AN ERROR
		or return "000 somehow unable to create folders: $!"; # IDIOT
	return $dir;
}
sub extract_links {
	my $txt = read_file("$root/$_[0]");

	say length $txt if $debug;

	my @links = ($txt =~ /http\S+/g);
	return @links;
}
sub write_summary {
	my $runes = sprintf("%85s | %4s | %10s\n", 'URL', 'HTTP', 'SIZE');
	$runes .= ('-' x 115)."\n";

	for (keys %{$_[0]}){
		$runes .= sprintf("%85s | %4s | %10s\n", $_, $_[0]{$_}[0], $_[0]{$_}[1]);
	}
	my $name = time . '.log';

	write_file($name, $runes);
}
sub cleanup {
	chdir $root;
	rename($_[0], $_[0].'.done');
}