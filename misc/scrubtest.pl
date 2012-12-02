use Modern::Perl;
use HTML::Scrubber;
use HTML::TreeBuilder;
use File::Slurp;
use utf8;

sub grab {
	my $url = 'http://www.literotica.com/s/genie-chronicles-ch-'.$_[0];

	my $scrubber = HTML::Scrubber->new(allow => [qw'p b br']);
	# $scrubber->rules(
		# div => {
			# class => qr/b-story-body-x/
		# }
	# );

	my $tree = HTML::TreeBuilder->new_from_url($url);
	my $title = $tree->look_down(_tag => 'div', 'class' => 'b-story-header');
	my $content = $tree->look_down(_tag => 'div', 'class' => 'b-story-body-x x-r15');

	my $partfixed = "<html><body><h2>".$title->as_trimmed_text."</h2>\n".$scrubber->scrub($content->as_HTML)."</body></html>";
	die $! unless $partfixed;
	$partfixed =~ s{(<br(?: /)?>\s*)+}{<p>}g; #there should be a treebuilder/element method to replace br with p. p doesn't need close tags
	my $final = HTML::TreeBuilder->new_from_content($partfixed)->as_HTML(undef,"\t",{});


	my $filename = $url;
	$filename =~ s{^.+/([^/]+)$}{$1.html};
	unlink $filename;
	write_file($filename, {binmode => ':utf8'}, $final);
}

for (my $i = 1,$i < 29, $i++){
	grab(sprintf "%02f", $i);
}

