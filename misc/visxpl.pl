use Modern::Perl;
use LWP;
use File::Path qw(make_path);
use HTML::TreeBuilder;
use Text::Unidecode;
use File::Slurp;

#script similar to imgur.pl for use with more sites

#todo:
# - merge w/imgur
# - motherless http://motherless.com/G5148014

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox 17.0',
    # timeout => 25,
);
my $post = $ARGV[-1];
my $start = time;
my ($title, @imgs) = grab_index($post);
my $out1 = download_album($title, @imgs);
my $out2 = dump_to_txt($title, @imgs); #test
say $out2.' ('.(time-$start).' secs)';

sub grab_index {
    given ($_[0]){
        when (/visualxpleasure/){
            make_path("_VXP");
            chdir("_VXP");
            return grab_vxp_index($_[0]);
        }
        when (/xhamster/){
            make_path("_XHAMSTER");
            chdir("_XHAMSTER");
            return grab_xh_index($_[0]);
        }
        default { die "unsupported host"; }
    }
}


sub grab_vxp_index { # http://visualxpleasure.blogspot.com/
    print "Fetching ";

    my $resp = $ua->get($_[0]);
    die $resp->code unless $resp->is_success;

    my $title = $_[0];
    $title =~ s{^.+/([^/]+)\.html$}{$1}
    || die 'oh no';

    say $title;

    my $page = HTML::TreeBuilder->new_from_content($resp->decoded_content);

    my @rows = $page->look_down(_tag => 'a', 'href' => qr/imagebam/);
    say ((scalar @rows)." images found. Parsing.");
    map { $_ = rewrite_imagebam($_->attr('href')) } @rows;

    $page->delete();
    say ((scalar @rows)." images verified.");
    return ($title, @rows);
}
sub rewrite_imagebam { #given an image landing page, return the direct link
    my $req = $ua->get($_[0]);
    warn $req->code unless $req->is_success;

    my $img = HTML::TreeBuilder->new_from_content($req->decoded_content)->look_down(_tag => 'img', 'alt' => 'loading')->attr('src');

    print '.';
    return $img;
}
sub grab_xh_index {
    print "Fetching ";

    my $resp = $ua->get($_[0]);
    die $resp->code unless $resp->is_success;

    my $title = $_[0];
    $title =~ s{^.+/([^/]+)\.html$}{$1}
    || die 'oh no';
    $title =~ s/_/-/g;

    say $title;

    my $page = HTML::TreeBuilder->new_from_content($resp->decoded_content);

    my @rows = $page->look_down(_tag => 'div', 'id' => qr/i_\d+/);
    my @imgs;
    say ((scalar @rows)." images found. Parsing.");
    for (@rows){
        my $tmp = $_->look_down(_tag => 'a')->attr('href');
        die 'uhoh' unless $tmp;
        $tmp = rewrite_xhamster($tmp);
        push @imgs, $tmp;
    }

    my $multipage = $page->look_down(_tag => 'div', 'class' => 'pager');
    if ($multipage){
        my @pages = $multipage->look_down(_tag => 'a');
        map { $_ = $_->attr('href') } @pages;

        my %dupe_filter;
        $dupe_filter{$_}++ for @pages;
        @pages = keys %dupe_filter;

        say ((scalar @pages)." additional pages found.");

        for (@pages){
            my @tmp = grab_xh_pages($_);
            push @imgs, @tmp;
        }
    }

    $page->delete();
    say ((scalar @imgs)." images verified.");
    return ($title, @imgs);
}
sub grab_xh_pages { #parse subsequent pages in an album
    my $req = $ua->get($_[0]);
    warn $req->code unless $req->is_success;

    my $page = HTML::TreeBuilder->new_from_content($req->decoded_content);

    my @rows = $page->look_down(_tag => 'div', 'id' => qr/i_\d+/);
    my @imgs;
    for (@rows){
        my $tmp = $_->look_down(_tag => 'a')->attr('href');
        die 'uhoh' unless $tmp;
        $tmp = rewrite_xhamster($tmp);
        push @imgs, $tmp;
    }

    $page->delete();
    return @imgs;
}
sub rewrite_xhamster { #given an image landing page, return the direct link
    my $req = $ua->get($_[0]);
    unless ($req->is_success){
        warn $req->code." ($_[0])";
        return "ERROR";
    }

    my $img = HTML::TreeBuilder->new_from_content($req->decoded_content)->look_down(_tag => 'img', 'id' => 'imgSized')->attr('src');

    print '.';
    return $img;
}


##output methods
sub dump_to_txt {
    my ($albumname, @urls) = @_;

    write_file('files.txt', (join "\n", @urls))
    || die $!;

    return $albumname;
}
sub download_album {
    my ($albumname, @urls) = @_;
    #for some reason mkdir doesn't work.
    make_path($albumname);

    chdir($albumname);
    my @files = glob "*";   #dupe detection database
    my ($counter, $dupe) = (0, 0);
    for (@urls){
        my $newfilename = $_;
        $newfilename =~ s{^.+?([^/]+)$}{$1};
        $counter += 1;
        $newfilename = ((sprintf "%03d", $counter) . "_" . $newfilename);
        for(@files){
            next if $_ ne $newfilename;
            $dupe = 1;
        }
        if ($dupe == 1){ print("$newfilename :: Duplicate\n"); $dupe = 0; next; }
        my $img = $ua->mirror($_, $newfilename);

        if (! $img->is_success){
            warn $img->code;
            next;
        }

        say($newfilename.' :: '.$img->code.' :: '.(sprintf "%.02d", ($img->content_length / 1024)).' kB');
        # sleep 1;
    }
    return $albumname;
}
