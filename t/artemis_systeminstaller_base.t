#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::MockModule;



BEGIN { use_ok('Artemis::Installer::Client::Precondition'); }


{
        # testing gethostname with an IP address will try to set the hostname
        # this may cause problems if tester is root and thus can set the hostname
        my $sys_hostname = new Test::MockModule('Sys::Hostname');
        $sys_hostname->mock('hostname', sub { return 'bascha' });        

        my $inst=new Artemis::Installer::Client::Precondition;
        is (Sys::Hostname::hostname(), 'bascha', 'mocking worked');
        is ($inst->gethostname(), 'bascha', "gethostname by ip");
}

# get_file_type checks in two ways. 
# First it analyses the file suffix. For this, the file does not need to exists.
my $inst_base = new Artemis::Installer::Client::Precondition;
is ($inst_base->get_file_type('/tmp/1.iso'), 'iso', 'Detected ISO using extenstion.');
is ($inst_base->get_file_type('/tmp/2.tar.gz'), 'gzip', 'Detected tar.gz using extension.');
is ($inst_base->get_file_type('/tmp/3.tgz'), 'gzip', 'Detected tgz using extension.');
is ($inst_base->get_file_type('/tmp/4.tar'), 'tar', 'Detected tar using extension.');

# second way of get_file_type -> analyse using file magic

is ($inst_base->get_file_type('t/file_type/targzfile'), 'gzip', 'Detected tar.gz using file type.');
is ($inst_base->get_file_type('t/file_type/tarbz2file'), 'bz2', 'Detected bzip using file type.');
is ($inst_base->get_file_type('t/file_type/tarfile'), 'tar', 'Detected tar using file.');

