use Irssi;
use Irssi::Irc;
use LWP::UserAgent;
use URI::Escape;
use File::Path qw'make_path';
use Tie::YAML;
use URI;
use Modern::Perl;
use warnings;
no warnings qw'uninitialized';
use utf8;
use vars qw'$VERSION %IRSSI';
use POSIX qw'strftime';

$VERSION = "0.1.1";
%IRSSI = (
    authors => 'protospork',
    contact => 'protospork\@gmail.com',
    name => 'rehost',
    description => 'better than imgur'
);

my $archive_dir = "/www/img";
my $public_pref = "http://proto.tea.jp/img";

#build the directory for the index if necessary
unless (-e $archive_dir){
    make_path($archive_dir);
}

my $debugmode = 1;

my %cache; my %lastlink;
tie my %mirrored, 'Tie::YAML', $ENV{HOME}.'/.irssi/scripts/cfg/img_mirror.po' or die $!;

my ($lasttitle, $lastchan, $lastcfgcheck, $lastsend, $tries) = (' ', ' ', ' ', (time-5),0);
my $cfgurl = 'http://dl.dropbox.com/u/48390/GIT/scripts/irssi/cfg/gettitle.pm';

Irssi::signal_add_last('message public', 'pubmsg');
Irssi::signal_add_last('message irc action', 'pubmsg');
Irssi::signal_add_last('message private', 'pubmsg');
Irssi::command_bind('mirror_conf_reload', \&loadconfig);

my $ua = LWP::UserAgent->new(
    agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:17.0) Gecko/20100101 Firefox/17.0',
    max_size => 8388608,
    timeout => 13,
    protocols_allowed => ['http', 'https'],
    'Accept-Encoding' => 'gzip,deflate',
    'Accept-Language' => 'en-us,en;q=0.5',
);


sub pubmsg {
    my ($server, $data, $nick, $mask, $target) = @_;
    unless (defined($target)){ $target = $nick; }

    my $stop = 0;
    # if (grep $target eq $_, (@offchans)){ $stop++; } #check channel blacklist
    if ($nick =~ m{(?:Bot|Serv)$|c8h10n4o2}i){ $stop++; }   #quit talking to strange bots
    # if (grep $nick eq $_, (@ignorenicks)){ $stop++; }

    return if $stop;
    return unless $data =~ m{(?:^|\s)(https?://(?:boards|images|thumbs)\.\S+chan\.org.+(?:jpe?g|gif|png))}ix;
    my $url = $1;
    $url =~ s/\d+\.thumbs/images/;
    $url =~ s{thumb/(\d+)s\.}{src/$1.};

    print $target.': '.$url if $debugmode;

    my @req_data = download_image($url);

    if ($req_data[0] eq 'error'){
        print "error: ".$req_data[1];
        return;
    } elsif ($req_data[0] eq 'exists'){
        print "exists: ".$req_data[1];
        # return;
    }

    #bookkeeping
    if (ref $mirrored{$url}){
        #only update count
        $mirrored{$url}{'pcnt'}++;
    } else {
        $mirrored{$url} = {
            'path' => $req_data[1],
            'nick' => $nick,
            'chan' => $target,
            'size' => $req_data[2],
            'code' => $req_data[3],
            'time' => time,
            'pcnt' => 1,
        };
        $mirrored{$url}{'short'} = waaai($public_pref.$mirrored{$url}{'path'});
    }
    tied(%mirrored)->save;

    #records
    my $logged = "msg botserv say #wat ".$target." || ".$public_pref.$mirrored{$url}{'path'}.
        " / ".$mirrored{$url}{'short'};
    $logged .= " || \00304Posted ".$mirrored{$url}{'pcnt'}." times.\017" if $mirrored{$url}{'pcnt'} > 1;
    $server->command($logged);

    #todo: slap the 'repost' nag in here
    my $return = $mirrored{$url}{'short'}.' || '.
        (sprintf "%.0f", (($mirrored{$url}{'size'} || -s $archive_dir.$mirrored{$url}{'path'})/1024)).'KB';
        #for some reason I can't pull 'size' for reposts
    $server->command("msg $target $return");

    return;
}

sub download_image {
    my $url = $_[0];

    my $path = [split /\//, $url];
    my $board = $path->[-3];

    my $date = strftime "/%Y-%b/", gmtime;
    $path = $date.$board.'/'.$path->[-1];


    unless (-e $archive_dir.$date.$board){
        print "making ".$archive_dir.$date.$board if $debugmode;
        make_path($archive_dir.$date.$board);
    }

    if (-e $archive_dir.$path){
        return ('exists', $path);
    }

    my $req = $ua->mirror($_[0], $archive_dir.$path);

    unless ($req->is_success){
        return ('error', $req->code);
    }

    return ('success', $path, $req->content_length, $req->code);
}

sub upload_index {
    my $url = $_[0];

    # later
}
sub waaai {
    my $req = $ua->get('http://waa.ai/api.php?url='.$_[0]);
    if ($req->is_success && length $req->decoded_content < 24){
        print $_[0] if $debugmode;
        print "Shortened to ".$req->decoded_content if $debugmode;
        return $req->decoded_content;
    } else {
        print "Shorten failed: HTTP ".$req->code." / ".$req->content_length;
        return $_[0];
    }
}
