#item (show) => ["cat", ["group1", "group2"], "stitle", "blacklist", airtime]
#TODO:
#TOSHO HAS NEW CATEGORIES


#	UNICODE:
#	U+[codepoint]s from wikipedia are HEX
#	chr() is BASE-10/DECIMAL
#	ord() is BASE-10/DECIMAL
#	regex/strings use \x{HEX}

%config = (
	LonE				=>	["Music", [qw|LonE|],		undef,			undef,		undef],
	nipponsei			=>	["Music", [qw|nipponsei|],	undef,			undef,		undef],
	eng					=>	["Hentai", [undef],			undef,			"raw",		undef],	#english hentai on ehtracker\sukebei, hopefully
	"[BSS]"				=>	["Anime", [qw|BSS|],		undef,			".avi",		undef],
	"THORA"				=>	["Anime", ["thora"],		undef,			undef,		undef],
	'mayo chiki'		=>	["Anime", [qw|ayako doki|], "Chiki",		undef,		2198],
	mukuchi				=>	["Anime", [qw|hadena AFFTW horrible|], "Morita-san", undef,2306],
	penguindrum			=>	["Anime", [qw|gg|],			"Penguins",		"reinweiss",2225],
	"mardock scramble"	=>	["Anime", [undef],			undef,			undef,		undef],
	'idolm@ster'		=>	["Anime", [qw|doki chibiki|], "Idols",		"848x480",	2194],
#fall 2011 starts here
#	"hunter x hunter"	=>	["Anime", [qw|tsuki horrible kanjouteki|], "HxH", undef,2288],
	chihayafuru			=>	["Anime", [qw|commie|], 	"Chihayafuru",	undef,		2271],
	"gundam AGE"		=>	["Anime", [sage],			'AGE',			undef,		2266],
	"guilty crown"		=>	["Anime", [qw'coalguys commie'],"Crown",	undef,		2259],
	horizon				=>	["Anime", [qw|commie|], 	"Horizon",		undef,		2254], #kyoukai senjou no horizon
	"persona 4"			=>	["Anime", [qw|commie|],		"P4",			undef,		2260],
	"fate \x{2044} zero"=>	["Anime", [qw|commie|],		"F/0",			"8bit",		2277],
	"fate zero"			=>	["Anime", [qw|UTW|],		"F/0",			undef,		2277],
	"maken-ki"			=>	["Anime", [qw'hiryuu fffpeeps'],"Maken-Ki",	"8bit",		2269],
	symphony			=>	["Anime", [qw|doki chihiro zenyaku|],"Mashiro",	"H.264",2256], #mashiro-iro symphony
	"ginyoku no fam"	=>	["Anime", [undef],			'Last Exile',	undef,		2253], #last exile: ginyoku no fam
	'last exile'		=>	["Anime", [undef],			'Last Exile',	undef,		2253],#commie
	"phi brain"			=>	["Anime", [undef],			undef,			undef,		2257],
	bakuman				=>	["Anime", [qw|sage TMD SFW|],	"Bakuman",		undef,	2295], #bakuman 2 #TMD and SFW
	"tomodachi ga sukunai"=>["Anime", [qw|mazui|],		"BokuTomo", 	undef,		2270], #boku ha/wa tomodachi ga sukunai
	"Cursed x Curious"	=>	["Anime", [qw|UTW|],		"C3",			undef,		2274], #cube[d] x cursed x curious [C3]
	"C\xB3"				=>	["Anime", [qw|commie|], 	"C3",			undef,		2274],
	"ben-to"			=>	["Anime", [qw'gg'],			"Ben-to",		undef,		2275],
	"mouretsu pirates"	=>	["Anime", [undef],			undef,			undef,		undef],
	tamayura			=>	["Anime", [undef],			undef,			undef,		2263],
	"Working'!!"		=>	["Anime", [qw'gg'],			"Working",		undef,		2249],
	'mirai nikki'		=>	["Anime", [undef],			"Nikki",		undef,		2273],
	'plastic nee-san'	=>	["Anime", ['retouched'],	undef,			undef,		undef] #comedy web series
);
@blacklist = qw( 
remux .iso .flv .rmvb .fr PSP ipod [iP- unofficial un-official xvid ashtr 400p indonesian sunred
animesenshi aoshen LQ bindesumux lorez thai italian persian getDBKAI gameternity senshiencodes 480p 848x480
german bakugan portuguese ptbr beyblade [RU] enconde ps3 dub Shani-san reencode re-encode animejoint
rena-chan imur88 chinese narutoforreal Español spanish animephase logn animestop grohotun pokemon 
kanjouteki (Hi10) iPhone [P] [ReinWeiss]
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
$do_airtime = 1;

####colorscheme
$Cname	= "09";
$Csize	= "04";
$Curl	= "14";
$Ccomnt	= "11,01";
$Chntai	= "05,10";