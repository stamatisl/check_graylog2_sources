#!/usr/bin/env perl
# This is a simple script to check graylog2 number of sources from a static file
# Copyright Stamatis Litinakis 02/11/2016

use warnings;
use strict;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use Nagios::Plugin;
use Data::Dumper;
use Array::Utils qw(:all);

my $np = Nagios::Plugin->new( 
        shortname => "Graylog2 Sources",
        usage => "Usage: %s [-H] [-P] [-u] [-p] [-t] [-f] [-w] [-c] [-v]",
        version => '1.1'
);

$np->add_arg(
    spec => 'host|H=s',
    help => '-H, --host 192.168.1.1',
    required => 1,
);

$np->add_arg(
    spec => 'port|P=s',
    help => '-P, --port INTEGER',
    required => 1,
);

$np->add_arg(
    spec => 'user|u=s',
    help => '-u, --user admin',
    required => 1,
);

$np->add_arg(
    spec => 'password|p=s',
    help => '-p, --password password',
    required => 1,
);

$np->add_arg(
    spec => 'time|t=s',
    help => '-t, --time INTEGER',
    required => 1,
);

$np->add_arg(
    spec => 'file|f=s',
    help => '-f, --file filename',
    required => 1,
);

$np->add_arg(
    spec => 'warning|w=s',
    help => '-w, --warning INTEGER',
    required => 1,
);

$np->add_arg(
    spec => 'critical|c=s',
    help => '-c, --critical INTEGER',
    required => 1,
);


$np->getopts;
if ($np->opts->verbose) { (print Dumper ($np))};

my $ua = LWP::UserAgent->new();

$ua->agent('check_json/0.5');
$ua->credentials($np->opts->host . ":" . $np->opts->port,"Graylog2 Server",$np->opts->user,$np->opts->password);
$ua->default_header('Accept' => 'application/json');
$ua->protocols_allowed( ['http', 'https'] );
$ua->parse_head(0);
$ua->timeout(15);

if ($np->opts->verbose) { (print Dumper ($ua . "\n"))};

my $response;
$response = $ua->request(GET "http://" . $np->opts->host . ":" . $np->opts->port . "/sources?range=" . (($np->opts->time)*60)*60);
if ($np->opts->verbose) { (print "\n" . $response->content . "\n\nFrom: http://" . $np->opts->host . ":" . $np->opts->port . "/sources?range=" . ((($np->opts->time)*60)*60) . "\n\n") };
my $json_response = decode_json($response->content);


    my @y= (keys $json_response->{sources});

    open my $handle, '<', $np->opts->file;
    chomp(my @z=<$handle>);
    close $handle;


    @y = sort @y;
    if ($np->opts->verbose) {print "@y\n\n";};
    @z = sort @z;
    if ($np->opts->verbose) {print "@z\n\n";};
    my @i = array_diff(@y,@z);

my @minus = array_minus( @y, @z );
print "Ignore the following hosts: @minus\n\n";

my @minus2 = array_minus( @z, @y );

if (@minus2) {
    if ((scalar(grep $_, @minus2)) >= ($np->opts->critical)) {
         $np->nagios_exit(CRITICAL,"Missing " . scalar(grep $_, @minus2) . " hosts: @minus2 are possible misssing! | total_sources=$json_response->{total}\n");
    } elsif ((scalar(grep $_, @minus2)) >= ($np->opts->warning)) {
         $np->nagios_exit(WARNING,"Missing " . scalar(grep $_, @minus2) . " host: @minus2 is possible misssing! | total_sources=$json_response->{total}\n");
    } else {
    $np->nagios_exit(OK,"All hosts sources are logging well | total_sources=$json_response->{total}\n");
}
}

$np->nagios_exit(UNKNOWN,"Can't read sources from Graylog2 JSON API");
