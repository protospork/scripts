use Digest::MD5;
use String::CRC32;
use Modern::Perl;

$|++;


my @files = glob "*.*";

for (@files){
	say "$_:";
	md5_test($_);
	crc_test($_);
	md5_test($_);
	crc_test($_);
}

sub crc_test {
	my $start = time;
	open my $file, $_[0] || die $!;
	binmode($file);
	
	my $hash = crc32(*$file);
		
	close $file;
	
	$hash =~ s/^(.+)$/uc sprintf "%08x", $1/eg;

	my $elapsed = time - $start;
	say "$hash || $elapsed secs";
	return;
}
sub md5_test {
	my $start = time;
	open my $file, $_[0] || die $!;
	binmode($file);

	my $md5 = Digest::MD5->new;
	# while(<$file>){ $md5->add($_); }
	$md5->addfile($file);
	my $hash = $md5->b64digest;
	
	close $file;	
	

	my $elapsed = time - $start;
	say "$hash || $elapsed secs";
	return;
}