#!/usr/bin/env perl
use warnings;
use strict;
use Digest::SHA1 qw/sha1_hex/;
use LWP::UserAgent;
use Pithub;

my %config = do '/secret/github.config';

if(-d "free-programming-books"){
	chdir("free-programming-books");
	system("git pull");
	chdir("../.");
}else{
	system("git clone https://github.com/vhf/free-programming-books.git");
}

chdir("free-programming-books");
my @books = <free-programming-books*.md>;

my %db;

foreach my $book (@books){
	local $/ = undef;
	open FILE, "$book" or die "Couldn't open file: $!";
	my $content = <FILE>;
	close FILE;
	#print sha1_hex($content)," $book\n";
	my $sha = sha1_hex($content);

	$db{$book}{"sha"}=$sha;
	$db{$book}{"content"}=$content;
}

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/8.0");
$ua->timeout(120);
$ua->show_progress(1);

my $i = Pithub::Issues->new( token => $config{'token'} );

foreach my $book (keys %db){
	my @content = split("\n", $db{$book}{'content'});
	foreach my $line (@content){
		if($line =~ /\[.*\].*\(.*(http:\/\/.*?)\)/){
			#print "$1\n";
			my $url=$1;
			my $test = &test_url($url);
			if($test ne 'good'){
				my $lang="en";
				if($book =~ /free-programming-books-(.*)\.md/){
					$lang=$1;
				}

				my $result = $i->create(
					user => 'borgified',
					repo => 'test_issue',
					data => {
						body      => $test,
						labels    => [ $lang ],
						title     => $url,
					}
				);

			}
		}
	}
}

sub test_url{
	my $retval;
	my $url = shift @_;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req);
	if($res->is_success){
		$retval = "good";
	}else{
		$retval = $res->status_line." $url";
	}
	return $retval;
}
