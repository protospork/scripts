#test script for figuring out the anidb http api
use Modern::Perl;
use File::Slurp;
use XML::Twig;
use URI::Encode qw(uri_encode uri_decode);
use LWP;
use experimental qw(smartmatch switch); #it's complete bullshit that I even have to do this

my $debug = 1;
my $version = 1181530;
my $query = uri_encode(join ' ', @ARGV);

my $xml = XML::Twig->new(pretty_print => 'indented_close_tag');
my $ua = LWP::UserAgent->new(
    agent => 'anidb_api.pl protospork@gmail.com',
    timeout => 6,
    protocols_allowed => ['http', 'https'],
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Language' => 'en-us,en;q=0.5',
);
write_file('anidb_results'.$ARGV[0].'.txt', {binmode => ':utf8'}, search_title($query));
sub search_title {
    my @results;
    my $resp = $ua->get('http://anisearch.outrance.pl/index.php?task=search&langs=en,x-jat,ja&query='.$_[0]);
    say $resp->status_line if $debug;
    # output unformatted xml to make sure you actually got it
    # write_file('anidb_api'.time.'.xml', {binmode => ':utf8'}, $resp->decoded_content) if $debug;
    $xml->parse($resp->decoded_content);
    # output formatted xml to make sure the parser didn't stroke out
    write_file('anidb_api_twig'.time.'.xml', {binmode => ':utf8'}, $xml->sprint) if $debug;
    my @shows = $xml->get_xpath("/animetitles/anime");
    say scalar @shows ." found" if $debug;
    for (@shows){
        my $this = $_;
        say $this->att('aid') if $debug;
        my @titles;
        for ($this->get_xpath('./title[@lang=~/en|x-jat|ja/]')){
            push @titles, $_->sprint;
        }
        my $out = 'http://anidb.net/a'.$this->att('aid');
        $out .= sort_titles(@titles);
        push @results, "$out\n";
    }
    @results = reverse sort @results;
    return @results[0..4]; #todo: add more weight to AIDs with more short titles, find a way to filter sequels
}
sub sort_titles {
    my $sorted = ' ';
    for (@_){
        my ($en,$tl,$jp);
        my $str = $_;
        $str =~ s{^.*<title }{};
        $str =~ s{]]></title>.*$}{};
        if ($str =~ /lang="en"/ && !$en){
            $en = $str;
            $en =~ s{.+CDATA.}{};
            $sorted .= "[$en]";
        } elsif ($str =~ /lang="ja"/ && !$jp){
            $jp = $str;
            $jp =~ s{.+CDATA.}{};
            $sorted .= "[$jp]";
        } elsif ($str =~ /lang="x-jat"/ && $str =~ /type="short"/ && length $sorted < 300){
            $tl = $str;
            $tl =~ s{.+CDATA.}{};
            $sorted .= "[$tl]"
        } else {
            next;
        }
    }
    $sorted =~ s/\n|\[\]//gs; #wtf
    return $sorted;
}
