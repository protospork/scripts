#±¦ 3126 U53f3 B30 G1 S5 F602 J4 N878 V700 H2975 DK1888 L78 K503 O171 DO88 MN3250 MP2.0769 E2 IN76 DS19 DF33 DH22 DT38 DC384 DJ35 DB3.12 DG277 DM78 P3-2-3 I3d2.15 Q4060.0 DR1477 Yyou4 Wu ¥¦ ¥æ¥¦ ¤ß¤® T1 ¤¢¤­ ¤¹¤± {right}


use Modern::Perl;
# use Text::Unidecode;
use YAML qw'DumpFile';
binmode STDOUT, ":utf8";

no warnings 'utf8'; #to shut it up about wide characters

#helper script for the kana irc quiz: takes edict and returns a yaml structure hopefully
#(loading the full 12mb edict file in (he)?xchat makes windows think the client died)

#you might want to run this in puttycyg or something (teh unicodes)

#THIS SCRIPT WILL LOOK UNRESPONSIVE AFTER IT'S SCANNED THE WHOLE INPUT.
#RELAX, IT'S JUST TAKING A WHILE TO FORMAT THE OUTPUT FILE

#KANJI EDITION

my %entries;
my $time = time;

load_dict($ARGV[0]);

sub load_dict {
    open my $file, '<:encoding(euc-jp)', $_[0] || die "Kanjidic not found.";

    my $count = 0;
    while (<$file>){
        $count++;
        next if $count == 1;
        my %stuff = parse($_);
        if ($stuff{"grade"} != 1){
            $count--;
        } else {
            say "Attr Dump:";
            for my $thing (keys %stuff){
                if ($thing eq 'meanings'){
                    say "$thing => ".(join ', ', @{$stuff{$thing}});
                } else {
                    say "$thing => ".$stuff{$thing};
                }
            }
            say "==";
        }
        exit if $count > 20;
    }
    # my $re = qr/[^\p{Katakana}\p{Hiragana}\x{30FC}]/; #to remove kanji and whatever

    # my $count = 0;
    # #build the dictionary
    # while (<$file>){
    #     my ($term, $def) = ($_ =~ m!^.+?\[([^;]+?)(?:;[^\]]+)*\]\s+/(.+?)(?:/\(2\).+)?/$!);
    #     next unless defined $term;
    #     if ($term =~ $re || $def =~ /[(,](?:obsc?|Buddh|comp|geom|gram|ling|math|physics|exp)[,)]/i){
    #         next;
    #     } else {
    #         $entries{$term} = $def;
    #     }
    #     #unidecode is a compromise b/c cmd hates nonascii and my cygperl install is broken
    #     unless ($count % 250){
    #         say unidecode($term)." = $entries{$term}";
    #     }
    #     $count++;
    # }
    say ((scalar keys %entries).' terms in dictionary.');
    DumpFile('kanji_library.po', \%entries) || die $!;
}
say 'Took '.(time - $time).' seconds holy hell';
exit;


sub parse {
    my $text = $_[0];

    my ($quote, $t1,$last, @out);
    for my $ch (split //, $text){
        given ($ch){
            when ('{'){
                $quote = 1;
                $t1 .= $ch;
            }
            when ('}'){
                $quote = 0;
                $t1 .= $ch;
            }
            when (' '){
                if ($quote){
                    $t1 .= $ch;
                } else {
                    push @out, $t1;
                    $t1 = '';
                }
            }
            default {
                $t1 .= $ch;
            }
        }
        $last = $ch;
    }
    push @out, $t1;
    my %entry = hashify(@out);
    # return @out;
    return %entry;
}
sub hashify {
    my @items = @_;
    my %out;

    $out{"char"} = shift @items; #literal character
    shift @items; #I'm taking a leap of faith here and assuming the JIS code is always second
    $out{"meanings"} = [];

    my $readings_exist = 0;
    for (@items){
        given ($_){
            when (/^U([0-9a-fA-F]+)/){ #unicode point
                $out{"code"} = $1;
            }
            when (/^G(\d+)/){
                $out{"grade"} = $1;
            }
            when (/^F(\d+)/){
                $out{"freq"} = $1;
            }
            when (/^\{([^}]+)\}/){
                push @{$out{"meanings"}}, $1;
            }
            when (/\p{Katakana}/){
                if (!$readings_exist){
                    $out{"reading_on"} = $_;
                }
            }
            when (/\p{Hiragana}/){
                if (!$readings_exist){
                    $out{"reading_kun"} = $_;
                }
            }
            when (/^T/){
                $readings_exist++;
            }

        }
    }

    #sanity
    if (!$out{"grade"}){
        $out{"grade"} = 20;
    }
    return %out;
}
