#!/usr/bin/env perl
# This is a simple script to check gralog2 number of sources
# STAMATIS LITINAKIS 20/03/2015

use warnings;
use strict;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use Nagios::Plugin;
use Data::Dumper;

my $np = Nagios::Plugin->new( 
        shortname => "GRAYLOG SOURCES",
        usage => "Usage: %s [-H] [-P] [-u] [-p] [-s] [-t] [-w] [-c] [-v]",
        version => '1.0'
);

$np->add_arg(
    spec => 'host|H=s',
    help => '-H, -host 192.168.1.1',
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
    spec => 'sources|s=s',
    help => '-s, --sources INTEGER',
    required => 1,
);

$np->add_arg(
    spec => 'time|t=s',
    help => '-t, --time INTEGER',
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

if ($np->opts->verbose) { (print($response->content . "\n")) };

my $json_response = decode_json($response->content);

if (($json_response->{total}) < ($np->opts->sources)) {
    
    if (($json_response->{total}) <= (($np->opts->sources) - $np->opts->critical)) {
    
         $np->nagios_exit(CRITICAL,"Some hosts sources is misssing! | total_sources=$json_response->{total}\n");
    
    } elsif (($json_response->{total}) <= (($np->opts->sources) - $np->opts->warning)) {    
 
         $np->nagios_exit(WARNING,"A host source is misssing! | total_sources=$json_response->{total}\n");

    }

} elsif (($json_response->{total}) > ($np->opts->sources)) {

    $np->nagios_exit(WARNING,"There is more sources than you think!!! | total_sources=$json_response->{total}\n");

} else {

    $np->nagios_exit(OK,"All hosts sources are logging well | total_sources=$json_response->{total}\n");
}

$np->nagios_exit(UNKNOWN,"Can't read sources from Graylog2 JSON API");
