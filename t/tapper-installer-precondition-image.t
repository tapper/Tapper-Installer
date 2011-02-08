#! /usr/bin/env perl

use strict;
use warnings;

use Cwd;
use Test::More;
use Test::MockModule;
use File::Temp qw/tempdir/;

BEGIN { 
        use_ok('Tapper::Installer::Precondition::Image');
 }

my $tempdir = tempdir( CLEANUP => 1 );
my $config = {paths => 
              {base_dir => $tempdir }
             };

my $image_installer = Tapper::Installer::Precondition::Image->new($config);

SKIP:{
        skip "Can not test get_device since make dist kills symlinks", 3 unless -l "t/misc/dev/disk/by-label/testing";
        my $retval = $image_installer->get_device('/dev/hda2','t/misc/');
        is($retval, "/dev/hda2", "Find device from single file without links");
        
        $retval = $image_installer->get_device('testing','t/misc/');
        is($retval, "/dev/hda2", "Find device from single file with links");
        
        $retval = $image_installer->get_device(['/dev/sda2','testing'],'t/misc/');
        is($retval, "/dev/hda2", "Find device from file list with links");
}


done_testing();
