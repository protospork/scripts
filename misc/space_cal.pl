#API exploration for possible .space trigger for c8
#https://launchlibrary.net/1.2/launch/next/8

use Modern::Perl;
use LWP;
use JSON;

my $ua = LWP::UserAgent->new();

my $req = $ua->get("https://launchlibrary.net/1.2/launch/next/8");
print $req->code;
say ": ".(length $req->decoded_content);

my $json;
eval { $json = JSON->new->utf8->decode($req->decoded_content); };
if ($@){ die "uh oh - ".$req->status_line; }

my $count = $json->{'total'}; #we javascript now
my $launches = $json->{'launches'};
#error checking what's that
while ($count >= 0){
    $count--;
    my $this = $launches->[$count];
#    say join ', ', keys %{$this};
    say '=' x 24;
    say $this->{'netstamp'};
    say $this->{'name'};
    say $this->{'location'}{'name'};
    say 'TBD='.$this->{'tbddate'};
    say join ' || ', @{$this->{'vidURLs'}};
}
