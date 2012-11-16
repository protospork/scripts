#GUItweaks:
#drop any code that changes the behavior of the display itself in here. WB probably belongs here, actually
use Modern::Perl;
use Xchat qw  (:all);
no warnings;

register('GUItweaks', 1, 'random shit to change/fix xchats general behavior', \&unload);
prnt('GUItweaks loaded');
sub unload { prnt 'GUItweaks unloaded'; }

#activity in the specified channels shouldnt make the tab red
hook_print($_, \&color_change) foreach('Channel Message', 'Channel Action');
my @chan = qw(#idlerpg #tokyotosho-api #anidb-spam);
sub color_change {
        command('gui color 1') if (grep(lc get_info('channel') eq $_, @chan));
        return EAT_NONE;
}




hook_command('verspam', \&verspam);
sub verspam {
#	my %target = {nick => shift, network => shift};
	my $target = $_[0][1];
	my %responses;
	my $i = 16;
	while ($i){
		my $ver = randver();
		$responses{$ver}++;
		$i--;
	}
	for (keys %responses){
#		prnt $_;
		command("nctcp $target VERSION $_");
	}
	return EAT_ALL;
}
sub fmt {
	my $fmt = $_[0];
	given ($fmt){
		when ('ghz'){
			my $raw = (105 + rand(999)) / 100;
			$raw = sprintf "%.02f", $raw;
			return $raw.'Ghz';
		} when ('mirc'){
			my $raw = (600 + rand(130)) / 100;
			$raw = sprintf "%.02f", $raw;
			return "v$raw";
		} when ('xos'){
			my @wos = ('8', '7', '6.1', 'Vista', 'XP', '2000'); #hexchat correctly sees 6.1 as 7, I need to code that
			return "Windows ".$wos[rand @wos];
		} when ('warch'){
			my @arch = ('x86', 'x64');
			return $arch[rand @arch];
		} when ('oem'){
			my @oem = (qw'AMD Intel');
			return $oem[rand @oem];
		} when ('xhex'){
			my $raw;
			if ($_[1]){ #xchat or silverex or something
				$raw = int((50 + rand(45)) / 10);
			} else {	#hexchat
				$raw = int((80 + rand(13)) / 10);
			}
			$raw = "2.".(sprintf "%.01f", $raw);
			
			if (rand(3) <= 1 && $_[1]){ #hexchat's versions never held a -2. is it a silverex thing?
				return $raw.'-2';
			} else {
				return $raw
			}
		} when ('lime'){
			my $raw = rand(240) / 100;
			$raw = sprintf "%0.02f", $raw;
			return $raw;
		} when ('kv'){
			my @builds = (
				" 4.0.4 svn-5646 'Insomnia' 20110308 - build 2011-03-19 23:10:52 UTC ",
				" 4.2.0 svn-6190 'Equilibrium' 20120701 - build 2012-07-04 14:48:08 UTC "
			);
			return $builds[rand @builds];
		} when ('kvos'){
			my $path = int rand 7;
			my $out;
			if ($path == 0){
				$out = 'Windows XP Service Pack '.(1 + (int rand 3)).' (Build 2600)';
			} else {
				$out = 'Windows 7 ';
				my @w7b = ('Professional', 'Home Premium', 'Ultimate', 'Home Basic', 'Enterprise');
				$out .= $w7b[$path - 1].' ('.fmt('warch').') ';
				
				#service pack
				my $sp = int rand 2;
				$sp == 1
					? $out .= 'Service Pack 1 (Build 7601)'
					: $out .= ' (Build 7600)'; #yes the double space is canon
			}
			return $out;
		} default {
			return 0;
		}
	}
}

sub randver {
	my @base = (qw'mIRC KVIrc irssi PieSpy xchat Xchat-WDK HexChat', "X-Chat Aqua", "LimeChat for Mac");
	my $out = $base[rand @base];
	
	given ($out){
		when ('xchat'){
			$out .= ' '.fmt('xhex', 1).' '.fmt('xos').' ['.fmt('oem').'/'.fmt('ghz').']';
		} when ('Xchat-WDK'){
			$out .= ' '.int(1480 + rand(28)).' ['.fmt('warch').']';
			$out .= ' / '.fmt('xos').' ['.fmt('ghz').']';
		} when ('HexChat'){
			$out .= ' '.fmt('xhex', 0).' ['.fmt('warch').'] / '.fmt('xos', 'h').' ['.fmt('ghz').']';
		} when ('mIRC'){
			$out .= ' '.fmt('mirc').' Khaled Mardam-Bey';
		} when ('irssi'){
			$out .= ' v0.8.15';
		} when (/^LimeChat/){
			$out .= ' '.fmt('lime');
		} when ('KVIrc'){
			$out .= fmt('kv').fmt('kvos');
			if ($out =~ /4\.0\.4/){
				$out =~ s/Windows 7 //;
			}
		} default {
			#will I even need a default?
			$out = 'irssi v0.8.15';
		}
	}
	return $out;
}
	
	
	
	
	
	
	
	
	
__END__

-penguins- VERSION eMule0.50a(SMIRCv00.69)

-sinecurist- VERSION Colloquy 1.3.5 (5534) - iPhone OS 6.0 (ARM) - http://colloquy.mobi

<%Tar> add mibbit
<%Tar> "irssi v0.8.12"
<%Tar> also "Purple IRC"

-shiroi|yaiba- VERSION Konversation 1.4 (C) 2002-2011 by the Konversation team

-denpa- VERSION HydraIRC v0.3.165 (12/December/2008) by Dominic Clifton aka Hydra - #HydraIRC on EFNet

-arcwest1- VERSION IRCCloud:irccloud.com:team@irccloud.com

-Ben13- VERSION ( NoNameScript 4.22 :: www.nnscript.com :: www.esnation.com )
-Mondlied- VERSION ( NoNameScript 4.22 :: www.nnscript.com :: www.esnation.com )

-Hakase- VERSION AndChat 1.4.1 http://www.andchat.net

-eragon22- VERSION Nettalk  6.7.14  (c)2002-2012 by Nicolas Kruse (www.ntalk.de)

-[Yusuke]- VERSION SysReset 2.53.27
-Nebby- VERSION SysReset 2.55.3. Running Addons: System Information 1.18 + Messages Addon 1.01 + File Server Tracker 1.17 + File Server Browser 1.17 + Web Update 1.22
-Cowboy_Bebop- VERSION SysReset 2.55.2. Running Addons: Web Update 1.22

-D-ion- VERSION xchat 2.8.8 Linux 3.0.17-tuxonice-r1-k8-28 [i686/800.50MHz/SMP]
-ELSR- VERSION xchat 2.8.8 Linux 3.4.2-1.fc16.x86_64 [x86_64/1.20GHz/SMP]
-nbk|miniITX- VERSION xchat 2.8.8 Linux 3.6.6-1.fc17.x86_64 [x86_64/1.60GHz/SMP]

-mattbox- VERSION X-Chat Aqua 0.16.0 (xchat 2.6.1) Darwin 10.8.0 [i386/2.33GHz/SMP]

-Loli_Lord- VERSION (SysInfo) Autor [>-]~SkG~[-->] Version [6.2.2] Fecha [10/01/2010]
-Fuyuki^Hyourin- VERSION PChat 1.4 Windows 6.1 [x86/2.92GHz]
-torchlight- VERSION HexChat 2.9.4 / Linux 3.5.0-17-generic [x86_64/1.20GHz/SMP]
-blarp- VERSION ZNC 0.205 - http://znc.in

=bots

-Hybrid|Senomiya-Akiho- VERSION iroffer-dinoex 3.28 Beta7 (Win32) 1.7.9, http://iroffer.dinoex.net/ - CYGWIN_NT-5.2 1.7.9(0.237/5/3) - geoip,upnp,gnutls,ruby
-Kaitou|Asuna- VERSION iroffer-dinoex 3.29 Beta3, http://iroffer.dinoex.net/ - openssl
-Invasion- VERSION iroffer-dinoex 3.28, http://iroffer.dinoex.net/ - geoip6,curl,openssl,ruby
-Hybrid|Saten-san- VERSION iroffer-dinoex 3.27 (Win32) 1.7.9, http://iroffer.dinoex.net/ - CYGWIN_NT-5.2 1.7.9(0.237/5/3) - geoip,upnp,gnutls,ruby
-IB|Merry- VERSION iroffer-dinoex 3.28, http://iroffer.dinoex.net/ - curl,openssl
-[TS]Yuuki-chan- VERSION iroffer-dinoex 3.28, http://iroffer.dinoex.net/ - Linux 2.6.18-308.el5.028stab099.3 - curl,openssl

-Neko-chan- VERSION PircBot 1.5.0 Java IRC Bot - www.jibble.org
-C0Rt3X- VERSION PircBot 1.5.0 Java IRC Bot - www.jibble.org

-cakesleuth- VERSION PieSpy 0.4.0 http://www.jibble.org/piespy/

-ChanStat- VERSION ChanStat version 329 from Wed Sep 19 182210 2012 -0400 by Adam <Adam@anope.org> - running on Linux amd64

-Seven- VERSION eggdrop v1.6.20 (with trivia.tcl 1.3.4 (release) from www.eggdrop.za.net)

<%Tar> oh this is a good one "TwitterBot 1.6.1 (http://mike.verdone.ca/twitter)"


=DONE
-Mr_CandyFLYP- VERSION mIRC v7.27 Khaled Mardam-Bey
-Cullen- VERSION mIRC v7.25 Khaled Mardam-Bey
-hal9000- VERSION mIRC v7.22 Khaled Mardam-Bey
-Retna- VERSION mIRC v6.16 Khaled Mardam-Bey
-Sophi- VERSION mIRC v7.22 Khaled Mardam-Bey
-SFLegend- VERSION mIRC v6.35 Khaled Mardam-Bey

-BreadOfWonder- VERSION XChat-WDK 1507 [x86] / Windows 7 [2.49GHz]
-blink348- VERSION XChat-WDK 1500 [x86] / Windows 7 [3.29GHz]
-dogchow- VERSION XChat-WDK 1489 / Windows 7 [2.65GHz]
-void- VERSION XChat-WDK 1500 [x64] / Windows 7 [3.39GHz]

-lunar- VERSION HexChat 2.9.0 [x86] / Windows XP [2.79GHz]
-cephalopods- VERSION HexChat 2.9.1 [x86] / Windows 7 [3.19GHz]
-Dark- VERSION HexChat 2.9.1 [x64] / Windows 7 [3.82GHz]
-I5Y- VERSION HexChat 2.9.1 [x64] / Windows 7 [2.49GHz]
-Fogun- VERSION HexChat 2.9.1 [x64] / Windows 7 [3.83GHz]

-DominoEffect- VERSION xchat 2.8.6-2 Windows Vista [Intel/2.50GHz]
-Wintermote- VERSION xchat 2.8.6-2 Windows XP [Intel/3.00GHz]
-hawk__- VERSION xchat 2.8.6-2 Windows Vista [AMD/3.68GHz]
-John__- VERSION xchat 2.8.6-2 Windows Vista [AMD/3.41GHz]
-HWJohn- VERSION xchat 2.8.6-2 Windows Vista [AMD/3.41GHz]

-Tar- VERSION irssi v0.8.15 - running on Linux i686
-hlmtre- VERSION irssi v0.8.15
-Jason- VERSION irssi v0.8.15 - running on Linux armv5tel
-HunterX11- VERSION irssi v0.8.15 - running on Darwin Power Macintosh
-c8h10n4o2- VERSION irssi v0.8.15
-Lucifer7- VERSION irssi v0.8.15
-Peron- VERSION irssi v0.8.15 - running on Linux i686
-Lupe- VERSION irssi v0.8.15 - running on Linux x86_64

-Silver- VERSION LimeChat for Mac 2.28

-MostHated- VERSION KVIrc 4.0.4 svn-5646 'Insomnia' 20110308 - build 2011-03-19 23:10:52 UTC -  (x64) Service Pack 1 (Build 7601)
-Piplup- VERSION KVIrc 4.0.4 svn-5646 'Insomnia' 20110308 - build 2011-03-19 23:10:52 UTC - Ultimate Edition (x64) Service Pack 1 (Build 7601)
-Geth_R- VERSION KVIrc 4.0.4 svn-5646 'Insomnia' 20110308 - build 2011-03-19 23:10:52 UTC - Home Premium Edition (x64)  (Build 7600)
-reanimated- VERSION KVIrc 4.0.4 svn-5646 'Insomnia' 20110308 - build 2011-03-19 23:10:52 UTC - Windows XP Service Pack 3 (Build 2600) :666
-exreality- VERSION KVIrc 4.2.0 svn-6190 'Equilibrium' 20120701 - build 2012-07-04 14:48:08 UTC - Windows 7 Professional (x64) Service Pack 1 (Build 7601)
-Treize- VERSION KVIrc 4.2.0 svn-6190 'Equilibrium' 20120701 - build 2012-07-04 14:48:08 UTC - Windows 7 Home Premium (x64) Service Pack 1 (Build 7601)
-bakatotestto- VERSION KVIrc 4.2.0 svn-6190 'Equilibrium' 20120701 - build 2012-07-04 14:48:08 UTC - Windows 7 Ultimate (x64) Service Pack 1 (Build 7601)