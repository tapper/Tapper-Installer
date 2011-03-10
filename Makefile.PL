use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-Installer';
all_from 'lib/Tapper/Installer.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

install_script 'bin/tapper-installer-client.pl';
install_script 'bin/tapper-installer-simnow.pl';

author_requires 'Module::Install::WriteAll';

build_requires 'Test::More';
build_requires 'Test::Deep';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Fixture::DBIC::Schema';
build_requires 'Test::MockModule';
build_requires 'Tapper::Test' => "3.000002";
build_requires 'File::Temp';
build_requires 'Cwd';


requires 'Tapper::Remote' => "3.000002";
requires 'Tapper::Base'   => "3.000002";
requires 'File::Basename';
requires 'File::Path';
requires 'File::Type';
requires 'Hash::Merge::Simple';
requires 'File::ShareDir';

requires 'Daemon::Daemonize';    # for simnow installer
requires 'IPC::Open3';
requires 'IO::Select';
requires 'List::Util';
requires 'Log::Log4perl';
requires 'Method::Signatures';
requires 'Moose';

requires 'YAML' => "0.72";
requires 'YAML::Syck' => "1.17";

auto_install;

repository 'git://github.com/amd/Tapper-Installer.git';
bugtracker 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tapper-Installer';

WriteAll;
