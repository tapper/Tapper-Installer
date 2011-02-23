#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MockModule;
use File::Temp qw/tempdir/;

BEGIN {
        use_ok('Tapper::Installer::Precondition::PRC');
 }

my $tempdir = tempdir( CLEANUP => 1 );

my $config = {paths =>
              { base_dir => $tempdir },
              hostname=> "uruk",
              mcp_port=> 12345,
              mcp_server=> "kupfer",
              prc_nfs_server=> "kupfer",
              report_api_port=> 12345,
              report_port=> 12345,
              report_server=> "kupfer",
              sync_port=> 1337,
              test_run=> 28372,
             };

my $prc_installer = Tapper::Installer::Precondition::PRC->new($config);

my $retval = $prc_installer->get_distro('t/misc/files/SuSE');
is($retval, "suse", 'Detect SuSE distribution');

$retval = $prc_installer->get_distro('t/misc/files/Debian');
is($retval, "Debian", 'Detect Debian distribution');

$retval = $prc_installer->get_distro("t/");
is($retval, "", 'Detect unknown distribution');

$retval = $prc_installer->install();

ok(-e "$tempdir/etc/tapper",'Write config file for PRC');
ok(-e "$tempdir/test.config",'Write config file for WinPRC');

my $success;
my $prc = {config =>
           {guest_number => 1,
            runtime => 10,
            test_program => "winsst",
            timeout_testprogram => 60}};
($success, $retval) = $prc_installer->create_win_config($prc);

use Data::Dumper;

is_deeply($retval, {guest_number => 1,
                    paths =>
                    { base_dir => $tempdir },
                    hostname =>  "uruk",
                    mcp_port =>  12345,
                    mcp_server =>  "kupfer",
                    prc_nfs_server =>  "kupfer",
                    report_api_port =>  12345,
                    report_port =>  12345,
                    report_server =>  "kupfer",
                    sync_port =>  1337,
                    test_run =>  28372,
                    test0_runtime_default =>  10,
                    test0_timeout =>  60,
                    test0_prog =>  "winsst",
                   }, 'Config for WinSST/ only one test');

 $prc = {config =>
           {guest_number => 1,
            testprogram_list => [{
                                  runtime => 10,
                                  test_program => "winsst",
                                  timeout_testprogram => 60,
                                  },{
                                  runtime => 30,
                                  test_program => "none",
                                  timeout_testprogram => 60,
                                 },{
                                  runtime => 30,
                                  test_program => "none",
                                  timeout_testprogram => 60,
                                 }]}};

($success, $retval) = $prc_installer->create_win_config($prc);
is_deeply($retval, {guest_number => 1,
                    hostname =>  "uruk",
                    paths =>
                    { base_dir => $tempdir },
                    mcp_port =>  12345,
                    mcp_server =>  "kupfer",
                    prc_nfs_server =>  "kupfer",
                    report_api_port =>  12345,
                    report_port =>  12345,
                    report_server =>  "kupfer",
                    sync_port =>  1337,
                    test_run =>  28372,
                    test0_runtime_default =>  10,
                    test0_timeout =>  60,
                    test0_prog =>  "winsst",
                    test1_runtime_default =>  30,
                    test1_timeout =>  60,
                    test1_prog => "none",
                    test2_runtime_default =>  30,
                    test2_timeout =>  60,
                    test2_prog =>  "none"
                   }, 'Generate config for WinSST');

($success, $retval) = $prc_installer->create_config($prc);
cmp_deeply($retval, superhashof($config), 'Create config');

done_testing();
