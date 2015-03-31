#!/usr/bin/env perl
# This is a simple script to check gralog2 number of sources
# Copyright Stamatis Litinakis 20/03/2015

use warnings;
use strict;
use HTTP::Request::Common;
use LWP::UserAgent;
use JSON;
use Nagios::Plugin;
use Data::Dumper;
use Array::Utils qw(:all);

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
if ($np->opts->verbose) { (print "\n" . $response->content . "\n\nFrom: http://" . $np->opts->host . ":" . $np->opts->port . "/sources?range=" . ((($np->opts->time)*60)*60) . "\n\n") };
my $json_response = decode_json($response->content);

if (($json_response->{total}) < ($np->opts->sources)) {

my $response2;
$response2 = $ua->request(GET "http://" . $np->opts->host . ":" . $np->opts->port . "/sources?range=" . (((($np->opts->time)*60)*60)+86400));  
if ($np->opts->verbose) { (print "\n" . $response2->content . "\n\nFrom: http://" . $np->opts->host . ":" . $np->opts->port . "/sources?range=" . (((($np->opts->time)*60)*60)+86400) . "\n\n") };
my $json_response2 = decode_json($response2->content);

    my @y= (keys $json_response->{sources});
    my @z= (keys $json_response2->{sources});

        foreach my $key (keys $json_response->{sources}) {
            push(@y,"\"" . $key . "\"\,");
        }
        foreach my $key (keys $json_response2->{sources}) {
            push(@z,"\"" . $key ."\"\,");
        }

    @y = sort @y;
    @z = sort @z;
    my @i = array_diff(@z,@y);
    
    if (($json_response->{total}) <= (($np->opts->sources) - $np->opts->critical)) {
         $np->nagios_exit(CRITICAL,"Missing " . (($np->opts->sources)-($json_response->{total})) . " hosts: @i are possible misssing! | total_sources=$json_response->{total}\n");
    } elsif (($json_response->{total}) <= (($np->opts->sources) - $np->opts->warning)) {    
         $np->nagios_exit(WARNING,"Missing " . (($np->opts->sources)-($json_response->{total})) . " hosts: @i are possible misssing! | total_sources=$json_response->{total}\n");
    }

} elsif (($json_response->{total}) > ($np->opts->sources)) {

    $np->nagios_exit(WARNING,"There is more sources than you think!!! | total_sources=$json_response->{total}\n");

} else {

    $np->nagios_exit(OK,"All hosts sources are logging well | total_sources=$json_response->{total}\n");
}

$np->nagios_exit(UNKNOWN,"Can't read sources from Graylog2 JSON API");
