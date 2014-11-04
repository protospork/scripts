#!C:\perl\perl\bin
use Modern::Perl;
use Digest::MD5;

my @files;
my $short = 0;
if (@ARGV){
	if ($ARGV[0] =~ /^--short$|^-s$/i){
		shift @ARGV;
		$short++;
	}
	@files = @ARGV;
}
if (!@files){
	@files = glob "*.jpg *.png *.gif";
}

for my $this (@files){
	my ($ext) = $this =~ /\.(\w{2,4})$/;
	
	open my $file, $this || die $!;
	binmode($file);
	my $md5 = Digest::MD5->new;
	while(<$file>){ $md5->add($_); }
	close $file;	
	my $hash = $md5->b64digest;
	
	$hash =~ s/\//_/g;
	my $out = $this.' => '.$hash;

	if ($short){
		$hash =~ s{^.*?([[:alpha:]]{4}).*}{$1};
		if (length $hash > 4){
			$hash =~ s/[+_-]//g;
			$hash =~ s{^.*?([[:alpha:]]{4}).*}{$1};
			if (length $hash > 4){
				$hash =~ s/[0-9]//g;
				$hash =~ s{^.*?([[:alpha:]]{4}).*}{$1};
			}
		}
		$out .= ' => '.$hash;
	}

	say $out;

	rename ($this, $hash.'.'.$ext) || die $!;
}