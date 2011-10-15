#item (show) => "category|group,group2|topicname|tracker,tracker2,etc|blacklist,of,terms"
#TODO:
#TOSHO HAS NEW CATEGORIES


#	UNICODE:
#	U+[codepoint]s from wikipedia are HEX
#	chr() is BASE-10/DECIMAL
#	ord() is BASE-10/DECIMAL
#	regex/strings use \x{HEX}

%config = (
	LonE				=>	["Music", [qw|LonE|],	undef,		undef],
	nipponsei			=>	["Music", [qw|nipponsei|], undef,	undef],
	eng					=>	["Hentai", [undef],		undef,		"raw"],	#english hentai on ehtracker\sukebei, hopefully
	"[BSS]"				=>	["Anime", [qw|BSS|],	undef,		".avi"],
	"THORA"				=>	["Anime", ["thora"],	undef,		undef],
	'mayo chiki'		=>	["Anime", [qw|ayako doki|], "Chiki", undef],
	mukuchi				=>	["Anime", [qw|hadena AFFTW horrible|], "Morita-san", undef],
	penguindrum			=>	["Anime", [qw|gg|],		"Penguins",	undef],
	"mardock scramble"	=>	["Anime", [undef],		undef,		undef],
	'idolm@ster'		=>	["Anime", [qw|doki chibiki|], "Idols", "848x480"],
#fall 2011 starts here
	"hunter x hunter"	=>	["Anime", [qw|tsuki horrible kanjouteki|], "HxH", undef],
	chihayafuru			=>	["Anime", [qw|commie|], "Chihayafuru",	undef],
	"gundam AGE"		=>	["Anime", [undef],		undef,		undef],
	"guilty crown"		=>	["Anime", [qw'coalguys commie'],"Crown",	undef],
	horizon				=>	["Anime", [qw|commie|], "Horizon",	undef], #kyoukai senjou no horizon
	"persona 4"			=>	["Anime", [qw|commie|],	"P4",		undef],
	"fate \x{2044} zero"=>	["Anime", [qw|commie|],	"F/0",		"8bit"],
	"fate zero"			=>	["Anime", [qw|UTW|],	"F/0",		undef],
	"maken-ki"			=>	["Anime", [undef],		"Maken-Ki",	undef],
	symphony			=>	["Anime", [qw|doki chihiro zenyaku|],"Mashiro",	"H.264"], #mashiro-iro symphony
	"ginyoku no fam"	=>	["Anime", [undef],		undef,		undef], #last exile: ginyoku no fam
	"phi brain"			=>	["Anime", [undef],		undef,		undef],
	bakuman				=>	["Anime", [qw|TMD SFW|],"Bakuman",	undef], #bakuman 2 #TMD and SFW
	"tomodachi ga sukunai"=>["Anime", [qw|mazui|],	"BokuTomo", undef], #boku ha/wa tomodachi ga sukunai
	"Cursed x Curious"	=>	["Anime", [qw|UTW|],	"C3",		undef], #cube[d] x cursed x curious [C3]
	"C\xB3"				=>	["Anime", [qw|commie|], "C3",		undef],
	"ben-to"			=>	["Anime", [qw'gg'],		"Ben-to",	undef],
	"mouretsu pirates"	=>	["Anime", [undef],		undef,		undef],
	tamayura			=>	["Anime", [undef],		undef,		undef],
	"Working'!!"		=>	["Anime", [qw'gg'],		"Working",	undef]
);
@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint
rena-chan imur88 chinese narutoforreal Español spanish animephase logn animestop grohotun pokemon 
kanjouteki (Hi10) iPhone [P]
); #regex special characters should NOT be escaped
@moreblacklist = (	
					"one piece", "galactic heroes", "kamen rider", "hitman reborn", 
					"shin koihime musou", "shugo chara", "heartcatch precure", "pretty cure",
					"hidamari sketch", "character song", "character album", "dragon ball",
					"tinkle", "shuffle", "rainbow gate", "cardfight", "doraemon",
					"pocket monsters"
				);
push @blacklist, @moreblacklist;

$do_hentai = 0;

####colorscheme
$Cname	= "09";
$Csize	= "04";
$Curl	= "14";
$Ccomnt	= "11,01";
$Chntai	= "05,10";