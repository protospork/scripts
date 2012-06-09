use LWP;
use Modern::Perl;
use File::Path qw(make_path);

#general purpose grab script convenient for ripping various walls of links
#feed it a txt of direct file links, one per line, 
#optionally sorted by folder, dirname at beginning of the block

#originally made to pull gifs of sara jean underwood from 
#http://www.reddit.com/r/nsfw/comments/p9lzt/sara_jean_underwood_gif_thread/
#with the help of 
#perl -e "open my $this, '<', 'underwood.htm' || die $!; my @out; 
#for(readline $this){ if ($_ =~ /<p>([ [:alnum:]]+)<\/p>/){ push @out, $1; } 
#elsif ($_ =~ /href=\"(\S+gif)\"/){ push @out, $1; }} close $this; 
#open my $outfi, '>', 'list.txt' || die $!; print $outfi join \"\r\n\", @out;" :3

#TODO: filesize and dl time for each file

open my $queue, '<', 'links.txt' 
	or exit say 'You need to create a links.txt and fill it with download links one-per-line';

my @now = localtime(time);
if ($now[2] >= 7 or $now[2] < 2){
	say 'pausing until after 2am';
	while ((localtime)[2] >= 7 || (localtime)[2] < 2){
		sleep 300;
	}
}

my $currentcat = 'img';
my %cats;
for (readline $queue){
	next if $_ =~ /^\s*$/;
	s/^\s+|\s*$//g;
	unless ($_ =~ /^http/){
		$currentcat = $_;
		$cats{$_} = [];
		next;
	}
	push @{$cats{$currentcat}}, $_;
}
close $queue;

# for (keys %cats){
	# say $_;
	# say join ', ', @{$cats{$_}};
# }

my $ua = LWP::UserAgent->new();
$ua->env_proxy;

for (keys %cats){
	my $dir = $_;
	$dir =~ s/\s+$//g;
	say $dir.'/';
	make_path($dir) or die $!;
	for (@{$cats{$_}}){
		my $name = $_;
		$name =~ s{^.+/([^/]+)$}{$1};
#		say $name;
		my $req = $ua->get($_, ':content_file' => $dir.'/'.$name);
		say $name.' => '.$req->code;
	}
}