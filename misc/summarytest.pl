use Modern::Perl;
use HTML::TreeBuilder;
use LWP;
use File::Slurp;
use utf8;


my $url = $ARGV[0] || die $!;

my $ua = LWP::UserAgent->new();

my $req = $ua->get($url);
die $req->status_code unless $req->is_success;

my $tree = HTML::TreeBuilder->new_from_content($req->decoded_content);
 
#braindead antique module
# use HTML::Summary;
# my $summarizer = HTML::Summary->new(
    # LENGTH      => 900,
    # USE_META    => 0,
# );

# my $summary = $summarizer->generate( $tree );

# say $summary;

#braindead original code
#todo: look at divs first and nuke anything related to comments
#todo: oh right headings
#my @paragraphs = $tree->find('h1','h2','h3','h4','h5','h6');
my @paragraphs = $tree->find('p');
say $#paragraphs.' paragraphs';
my @sents;
for (@paragraphs){
	# my $augh = split /[[:punct:]]\s*/, $_->as_text; #fuck it good enough
	# $augh =~ s/[^[:ascii:]]//g; #WHY.
	# push @sents, $augh;
	
	my $why = $_->as_text;
	$why =~ s/[^[:ascii:]]//g;
	push @sents, $why;
}
say 'sample: '.$sents[12];
my $summary = join '. ', @sents; $summary .= '.';
#$summary = utf8::encode($summary); #WHY.
write_file('summ-raw-'.time.'.txt', $summary);
#die length $summary;

#now destroy what's left of my soul
use Text::Summarize;
use Data::Dump qw(dump);
#I dunno
# my $listOfSentences = [
  # { id => 0, listOfTokens => [qw(all people are equal)] },
  # { id => 1, listOfTokens => [qw(all men are equal)] },
  # { id => 2, listOfTokens => [qw(all are equal)] },
# ];
my $listOfSentences;
my $sub = 0;
for my $sen (@sents){
	my @tokens = split /\s+/, $sen;
	for (@tokens){ shift if /[<>]/; } #shouldn't be necessary anymore
	$listOfSentences->[$sub]{'listOfTokens'} = \@tokens;
	$listOfSentences->[$sub]{'id'} = $sub;
	$sub++;
}
my $fuckingmess = getSumbasicRankingOfSentences(listOfSentences => $listOfSentences, textRankParameters => {directedGraph => 1});
write_file('summ-'.time.'.txt', (dump $fuckingmess));

my @sentences;
for (my $i = 0; $i > 10; $i++){
	my $id = $fuckingmess->[$i][0];
#	push @sentences, ((ucfirst(join ' ', @{$listOfSentences->[$id]{'listOfTokens'}})).'.');
	push @sentences, $sents[$id];
}

say 'derp: ';
say join ' ', @sentences;