#!perl

use Modern::Perl;
use File::Slurp;
use File::Util;
use Number::Bytes::Human 'format_bytes';
use LWP;
use Cwd 'cwd';

# scrape the directory for txt files, pull all the URLs from them, save those files

my $debug = 1;

my $fu = File::Util->new();
my $ua = LWP::UserAgent->new(
	agent => 'grabber.pl is not a bot (protospork@gmail.com)'
);
my $root = cwd;

my @lists = <*.txt>;

for (@lists){
	my $dir = create_dir($_);
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

		my $size = format_bytes(length $resp->content);
		say "grabbed $name // $size" if $debug;

		$out{$url} = [$resp->code, $size];
	}

	write_summary(\%out);

	chdir $root;
	unlink $_ unless $debug;
}

sub create_dir {
	my $dir = $_[0];
	$dir =~ s/\.txt$//;

	say "creating $dir" if $debug;

	$fu->make_dir($dir, undef, '--if-not-exists')
		or die "somehow unable to create folders: $!";
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