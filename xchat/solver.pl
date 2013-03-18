use Modern::Perl;
use Xchat qw':all';
use Lingua::JA::Kana;

register('nihongo quiz solver', time, "no seriously what is wrong with me", \&unload);

hook_print('Channel Message', \&where_did_i_go_wrong);

prnt "you are an awful person";
sub unload { prnt "solver unloaded"; }

sub where_did_i_go_wrong {
    my %deets;
    ($deets{'nick'}, $deets{'msg'}) = ($_[0][0], $_[0][1]);
    ($deets{'chan'}, $deets{'srvr'}) = (get_info('channel'), get_info('server'));

    return EAT_NONE unless $deets{'nick'} =~ /nihongobot/;
    return EAT_NONE if get_info('nick') eq $deets{'nick'};

    if ($deets{'msg'} =~ /^Q\d+: ([\p{Hiragana}\p{Katakana}\x{30FC}]+)/){
        my $q = $1;
        my $try = decode_this($q);

        command("timer 1 msg $deets{'chan'} $try");
    } else {
        return EAT_NONE;
    }
    return EAT_NONE;
}
sub decode_this {
    my $roma = kana2romaji($_[0]);

    #FOR THE NEW QUIZ PARSER, THE Y IN THE FIRST TWO RULES IS OPTIONAL
    $roma =~ s/(?<=j)ix[uy]//g; #it romanizes じょ as jixyo, etc.
    $roma =~ s/(?<=ch)ixy//g;
    $roma =~ s/(?<=[hbpkgnmr])ix//g; #and you want to keep the y for most of them

    $roma =~ s/(?<=[td])ex//g;

    $roma =~ s/(?<=v)ux//g; #all V sounds except vu use vowel extensions

    $roma =~ s/dh(?=[ui])/dz/g; #ちぢ つづ

    command("timer 1 echo $_[0] / $roma");
    return $roma;
}


__END__

==head1 UHOHs:

<nihongobot> Q62: ねんびゃくねんじゅう ((adv) throughout the year/all the year round/always)
<hax> nenbakunenjuu

<nihongobot> Q13: ぎょくたい ((n) the Emperor's person or presence)
<hax> gixyokutai

 エーティーエム / eetexiiemu
<nihongobot> Q23: エーティーエム ((n) (1) automatic teller machine/ATM/automated teller machine)
<hax> eetexiiemu

 ヴィタ / vuxita
<nihongobot> Q11: ヴィタ ((n) beta)
<hax> vuxita
