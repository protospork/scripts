use Modern::Perl;
use TMDB;
use Data::Dumper;

#test script for themoviedb's api

my $apikey = 'b81be5d4198bd2e0af932afbc4d80ac4';

my $tmdb = TMDB->new({api_key => $apikey});

# my @res = $tmdb->search->movie(join ' ', @ARGV);
# foreach my $res (@res) {
	# my $out = $res->{name}.': '.$res->{url}.' ('.$res->{year}.')';
	# 
	# say $out;
# }
my $in = join ' ', @ARGV;
say $in;
my $search = $tmdb->search->person($in);

open my $file, '>', 'info.'.$ARGV[0].'1.txt';
print $file Dumper $search;

my $movie = $tmdb->person($search->[0]{id});
my $info = $movie->info();

open my $file2, '>', 'info.'.$ARGV[0].'2.txt';
print $file2 Dumper $info;