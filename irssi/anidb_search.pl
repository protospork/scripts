use Irssi;
use Modern::Perl;
use LWP;
use utf8;
use XML::Twig;
use URI::Encode qw(uri_encode uri_decode);
use vars qw($VERSION %IRSSI);


$VERSION = "0.1.4";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'anidb',
    description => 'anidb search',
    license => 'MIT/X11'
);
#doesn't actually use the anidb api yet, uses eloyard's external title search
# http://anisearch.outrance.pl/doc.html
my $debug = 1;

my $ua = LWP::UserAgent->new(
    agent => 'anidb_search.pl protospork@gmail.com',
    timeout => 6,
    protocols_allowed => ['http', 'https'],
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Language' => 'en-us,en;q=0.5',
);

sub event_privmsg {
    my ($server, $data, $nick, $mask) = @_;
    my ($target, $text) = split(/ :/, $data, 2);

    my @terms;
    if ($text =~ /^\s*\.a(?:ni)?db\s*/i){ #make sure it's a trigger
        @terms = split /\s+/, $text;
        print join ', ', @terms if $debug;
        shift @terms; #ditch the trigger
    } else {
        return;
    }
    for (@terms){ #the api uses mysql boolean search rather than something sane
        if ($_ ~~ $terms[0]){ next; } #first entry shouldn't have plus? maybe?
        if ($_ =~ m/^-/){
            $_ =~ s/^-/%2D/;
        } else {
            $_ = '%2B'.$_;
        }
    }
    print join ' ', @terms if $debug;
    print uri_encode(join ' ', @terms) if $debug;

    my @return = search_title(join '+', @terms);
    for (@return){
        $server->command('msg '.$target.' '.$_) if $_;
    }
}
sub search_title {
    my @results;
    my $resp = $ua->get('http://anisearch.outrance.pl/index.php?task=search&langs=en,x-jat,ja&query='.$_[0]);
    # print $resp->status_line if $debug;

    my $xml = XML::Twig->new();
    $xml->safe_parse($resp->decoded_content);

    my @shows = $xml->get_xpath("/animetitles/anime");
    print scalar @shows ." found" if $debug;
    for (@shows){
        my $this = $_;
        print $this->att('aid') if $debug;
        my @titles;
        for ($this->get_xpath('./title[@lang=~/en|x-jat|ja/]')){
            push @titles, $_->sprint;
        }
        my $out = "\x0307".'http://anidb.net/a'.$this->att('aid');
        $out .= sort_titles(@titles);
        push @results, "$out\n";
    }
    # @results = reverse @results; #reverse puts more recent items first
    @results = sort_aids(@results);
    return @results[0..4]; #todo: add more weight to AIDs with more short titles, find a way to filter sequels
}
sub sort_titles {
    my $sorted = " \x0303";
    for (@_){
        my ($en,$tl,$jp);
        my $str = $_;
        $str =~ s{^.*<title }{};
        $str =~ s{]]></title>.*$}{};
        if ($str =~ /lang="en"/ && !$en){
            $en = $str;
            $en =~ s{.+CDATA.}{};
            $sorted .= "[\x0307$en\x0303]";
        } elsif ($str =~ /lang="ja"/ && !$jp){
            $jp = $str;
            $jp =~ s{.+CDATA.}{};
            $sorted .= "[\x0307$jp\x0303]";
        } elsif ($str =~ /lang="x-jat"/ && $str =~ /type="short"/){# && length $sorted < 300){
            $tl = $str;
            $tl =~ s{.+CDATA.}{};
            $sorted .= "[\x0307$tl\x0303]" unless length $tl < 1;
        } else {
            next;
        }
    }
    $sorted =~ s/\n//gs; #wtf
    $sorted =~ s{\[(?:\x{03}07\x{03}03)?\]}{}g; #getting empty titles sometimes, somehow
    return $sorted;
}
sub sort_aids {
    my @raw = @_;
    my @sorted;

    for (@raw){
        if ($#raw > 3){
            if ($_ =~ /\b(OVA|[mM]ovie)\b/){ #weed out OVAs in broad searches / prolific series
                next;
            }
            if ($_ =~ /\D\d(?:\x{03}03)?\]/){ #try to remove sequels, too
                next;
            }
        }
        my @num = ($_ =~ m/(\]\[)/g);
        push @sorted, $_;
    }
    @sorted = sort sorter @sorted;
    return @sorted;
}
sub sorter {
    my @one = ($a =~ m/(\]\[)/g);
    my @two = ($b =~ m/(\]\[)/g);
    if ($#one > $#two){
        return -1;
    } elsif ($#two > $#one){
        return 1;
    } else {
        return 0;
    }
}
Irssi::signal_add("event privmsg", "event_privmsg");
