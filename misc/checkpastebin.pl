# use Modern::Perl;
# use LWP; #I should really have used WWW:Mechanize for this
# use File::Slurp;
# use Tie::YAML;
# use URI::Find;

# my $debug = 1;

# my $ua = LWP::UserAgent->new();
# my $uri = URI::Find->new(sub { return $_[1]; });
# tie my %log, 'Tie::YAML', 'ddls.po' or die $!;

# my $megaddl = qr{https?://mega\.co\.nz/#![-_0-9a-zA-Z]{8}![-_0-9a-zA-Z]{43}};
# my $mfddl = qr{https?:(?:www\.)?mediafire\.com/(?:download\.php)?\?[0-9a-z]{5,}};
# # should be valid, but the API doesn't think trends is real
# # my $resp = $ua->post(
# #     'http://pastebin.com/api/api_post.php',
# #     'api_dev_key'   =>  '771e32e1fa0c1377acc7c278509eeefb',
# #     'api_option'    =>  'trends'
# # );

# # write_file('trends.xml', $resp->decoded_content);


# # extract all 18(?) trending pastes and the 8 most recent public ones
# sub get_pastes {
#     if ($debug){ say "get_pastes called."; }
#     my $resp = $ua->get('http://pastebin.com/trends');
#     return $resp->code unless $resp->is_success;

#     my @links = map { $_ = 'http://pastebin.com/raw.php?i='.$_; } ($resp->decoded_content =~ m!href="/([[:alnum:]]{8})"!gi);
#     die unless @links;
#     if ($debug){ say $_ for @links; }
#     return @links;
# }
# sub get_links {
#     if ($debug){ say "get_links called."; }
#     my @pastes = get_pastes();
#     if (scalar @pastes == 1){ #that one's an error code
#         return 'Error '.$pastes[0];
#     }

#     my @links;
#     for my $paste (@pastes){
#         sleep ((int(rand(8)))+2);
#         my $resp = $ua->get($paste);
#         unless ($resp->is_success){
#             say "Fail: $paste" if $debug;
#             push @links, $resp->code;
#             next;
#         }

#         for (scrape_for_ddls($resp->decoded_content)){
#             push @links, $_;
#         }
#     }
#     return @links;
# }
# sub get_title {
#     my $string = shift;
#     if ($debug){ say "get_title called for $string"; }
#     my ($title, $url);
#     if ($string =~ $mfddl){
#         #error.php / "Free Online Storage" for takedowns
#         $url = $string;
#         my $resp = $ua->get($string);
#         if (! $resp->is_success){
#             $title = $resp->code;
#         } else {
#             ($title) = ($resp->decoded_content =~ m!<META NAME="description" CONTENT="(.+?)"/>!);
#             if ($title =~ /MediaFire is/){ $title = '404'; }
#         }
#     } elsif ($string =~ $megaddl){
#         ($title, $url) = ($string =~ /^(.+?)\s*($megaddl)/gms);
#     }

#     $log{$url} = $title;
#     tied(%log)->save;
#     return ($url,$title);
# }
# sub scrape_for_ddls {
#     if ($debug){ say "scrape called."; }
#     my $html = shift;

#     #there doesn't seem to be a way to request filenames from mega, so I'll have to grab some of the surrounding text?
#     # my (@mega) = ($html =~ m!^((?:\w+\s+)+\s$megaddl)$!gms);
#     # # my (@mega) =
#     # my (@mefi) = ($html =~ m!($mfddl)!g);

#     # my @out = map { (get_title($_))[0] } @mega;
#     # push @out, map { (get_title($_))[0] } @mefi;
#     my @out = $uri->find(\$html);
#     if ($debug){ say "\tfound: ".$_ for @out; }
#     return @out;
# }


# my @links = get_links();
# if (scalar @links == 1){
#     warn "some sort of fuckup";
# }

use LWP;
use URI::Find;
use Modern::Perl;
use Tie::YAML;
use File::Slurp;
use HTML::ExtractMeta;

my $ua = LWP::UserAgent->new(timeout => 20);
my $megaddl = qr{https?://mega\.co\.nz/#![-_0-9a-zA-Z]{8}![-_0-9a-zA-Z]{43}};
my $mfddl = qr{https?://(?:www\.)?mediafire\.com/(?:download\.php)?\?[0-9a-z]{5,}};
my @ddls;
my $uri = URI::Find->new(sub {
    if ($_[0] =~ /$mfddl|$megaddl/){
        say "\tfound: $_[0]";
        push @ddls, $_[0];
        return $_[0];
    } else {
        return "";
    }
});
#cache ddl links, cache checked pastebin urls
tie my %log, 'Tie::YAML', 'checkpastebin.po' or die $!;




my $index = $ua->get('http://pastebin.com/trends');
die $index->code unless $index->is_success;
say "Index retrieved.";

my @pastes = map { $_ = 'http://pastebin.com/raw.php?i='.$_; } ($index->decoded_content =~ m!href="/([[:alnum:]]{8})"!gi);
unshift @pastes, "http://pastebin.com/raw.php?i=MgLzE2HV";
die unless $#pastes > 0;

my $test = 5;
for my $paste (@pastes){ #scrape for links
    last unless $test;
    # if ($#ddls >= 0){ warn "already have $#ddls links to play with"; last; }
    if (scalar keys %log > 0){
        next if grep $paste eq $_, (values %log);
    }
    say ((substr $paste, -8)." ripping.");
    # $test--;
    my $resp = $ua->get($paste);
    unless ($resp->is_success){
        warn "fail: $paste\n";
        next;
    }
    $log{$paste} = $paste;

    my $ttl = $uri->find(\$resp->decoded_content);

    say ("Found $ttl URLs (unfiltered).");
    sleep 5;
}
tied(%log)->save;

if (@ddls){
    write_file('ddls_raw_'.time.'.txt', @ddls);
} else {
    die "no links, apparently";
}

my @out;
say "Title-checking DDLs:";
for my $url (@ddls){
    if (scalar keys %log > 0){
        next if grep $url eq $_, (keys %log);
    }
    my $resp = $ua->get($url);
    unless ($resp->is_success){
        warn $resp->code.' for '.$url;
        next;
    }
    my $title = HTML::ExtractMeta->new(html => $resp->decoded_content)->get_description();
    if ($title && $title =~ /^\s*MediaFire\s*$|free online storage/i){ #check whether extractmeta can see the canon url. it'll be an error
        $title = "404";
        ###MEDIAFIRE CHANGED SOMETHING: IT ALL READS AS DEFAULT TITLE NOW. (or is it UA sniffing?)
    } elsif (!$title && $url =~ /$megaddl/){
        $title = "Mega";
    }
    $log{$url} = $title;
    push @out, "$url :: $title\n";
    say "$url :: $title";
    sleep 5;
}
tied(%log)->save;

if (@out){
    write_file('ddls_checked_'.time.'.txt', @out);
}
