#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::MockModule;
use File::Temp qw/tempdir/;

BEGIN { 
        use_ok('Artemis::Installer::Precondition::PRC');
 }

my $tempdir = tempdir( CLEANUP => 1 );
mkdir("$tempdir/etc/") or die "Can't create $tempdir/etc/:$!";

my $config = {paths => 
              {base_dir => $tempdir }
             };

my $prc_installer = Artemis::Installer::Precondition::PRC->new($config);

my $retval = $prc_installer->get_distro('t/misc/files/SuSE');
is($retval, "suse", 'Detect SuSE distribution');

$retval = $prc_installer->get_distro('t/misc/files/Debian');
is($retval, "Debian", 'Detect Debian distribution');

$retval = $prc_installer->get_distro("");
is($retval, "", 'Detect unknown distribution');

$retval = $prc_installer->install();

ok(-e "$tempdir/etc/artemis",'Write config file for PRC'); 
ok(-e "$tempdir/test.config",'Write config file for WinPRC'); 

done_testing();
