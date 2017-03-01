use Modern::Perl;
use Digest::ED2K;
use File::Slurp qw'write_file';
use File::Copy;
#gonna periodically run this in my 'seen' anime folder to update my anidb mylist
#ed2k://|file|[HorribleSubs] One Room - 01 [720p].mkv|57435410|c93527b64b5b64528a17f28dfaeaceab|
my $debug = 1;

my @files;
my @links;
if (@ARGV){
    #I guess make it run on any specified files?
    @files = @ARGV;
}
if (!@files || $files[0] eq ''){
	@files = glob "*.mkv *.mp4 *.avi"; #lol avi
}

mkdir "_parsed";

for my $this (@files){
    say "$this => " if $debug;
    if ($this !~ /(m(kv|p4)|a(vi|ss)|ts|webm)$/i){ #required since I'm invoking this from a dumbass batch script
        say 'unsupported file' if $debug;
        next;
    }
    my $link = 'ed2k://|file|'.$this;
	open my $file, $this || die $!;
	binmode($file);
	my $donk = Digest::ED2K->new;
	while(<$file>){ $donk->add($_); }
	close $file;
	my $hash = $donk->hexdigest;

    $link .= '|'.(stat $this)[7].'|'.$hash."|"; #that's filesize in bytes

    say $link;
    push @links, $link;

    move $this, "_parsed";
}

write_file('pushme.txt', {append => 1 }, map { "$_\n" } @links);
write_file('chii.txt', {append => 1 }, map { "!addfile $_ w deleted\n" } @links);
