use Modern::Perl;
use Text::Unidecode;
use YAML qw'DumpFile';
binmode STDOUT, ":utf8";

no warnings 'utf8'; #to shut it up about wide characters

#helper script for the kana irc quiz: takes edict and returns a yaml structure hopefully
#(loading the full 12mb edict file in (he)?xchat makes windows think the client died)

#you might want to run this in puttycyg or something (teh unicodes)

#THIS SCRIPT WILL LOOK UNRESPONSIVE AFTER IT'S SCANNED THE WHOLE INPUT.
#RELAX, IT'S JUST TAKING A WHILE TO FORMAT THE OUTPUT FILE

my %entries;
my $time = time;

load_dict("X:/My Dropbox/Public/GIT/scripts/misc/edict");

sub load_dict {
	open my $file, '<:encoding(euc-jp)', $_[0] || die "Edict not found.";

	my $re = qr/[^\p{Katakana}\p{Hiragana}\x{30FC}]/; #to remove kanji and whatever


	my $count = 0;
	#build the dictionary
	while (<$file>){
		my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
		next unless defined $term;
		if ($term =~ $re || $def =~ /[(,](?:obsc?|Buddh|comp|geom|gram|ling|math|physics|exp)[,)]/i){ 
			next; 
		} else { 
			$entries{$term} = $def; 
		}
		#unidecode is a compromise b/c cmd hates nonascii and my cygperl install is broken
		unless ($count % 250){
			say unidecode($term)." = $entries{$term}";
		}
		$count++;
	}
	say ((scalar keys %entries).' terms in dictionary.');
	DumpFile('kana_library.po', \%entries) || die $!;
}
say 'Took '.(time - $time).' seconds holy hell';
exit;