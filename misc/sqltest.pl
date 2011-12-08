use Modern::Perl;
use DBI;

my $dbfile = 'sqltest.db';
my $db = DBI->connect("dbi:SQLite:dbname=$dbfile","","",{RaiseError => 1}) or die $DBI::errstr;

my $table = 'table1';
my @rows = qw(id time chan link orig del nick num);

$db->do('create table '.$table.' ('.(join ', ', @rows).')') or die $DBI::errstr;

my $id = 1;
my @ins;
for (@rows){
	my $tmp;
	say $_.': ';
	$tmp = <STDIN>;
	chomp $tmp;
	$tmp =~ s/(.+)/"$1"/;
	push @ins, $tmp;
}

$db->do('insert into '.$table.' values ('.(join ', ', @ins).')') or die $DBI::errstr;

$db->disconnect;