#!/usr/bin/perl

use strict;
use warnings;
use Mail::IMAPClient;

my $configFilePath = '/etc/imapmda/';

my $destinationName = $ARGV[0];

if (not defined $destinationName) {
  die "Need name of destination";
}

my $configFile = $configFilePath.$destinationName;

my $config = do($configFile);
die "Error parsing $configFile: $@" if $@;
die "Error reading $configFile: $!" unless defined $config;

my $mail = join("", <STDIN>);

my $imap = Mail::IMAPClient->new(
  Server   => $config->{server},
  User     => $config->{user},
  Password => $config->{password},
  Ssl      => 1,
  Uid      => 1,
);

$imap->append_string($config->{folder}, $mail);

$imap->logout
  or die "Logout error: ", $imap->LastError, "\n";
