use inc::Module::Install;

name     'Tapper-Installer';
all_from 'lib/Tapper/Installer.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'freebsd';

install_script 'bin/tapper-installer-client.pl';
install_script 'bin/tapper-installer-simnow.pl';

author_requires ''Module::Install::WriteAll'';

build_requires 'Test::More';
build_requires 'Test::Deep';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Fixture::DBIC::Schema';
build_requires 'Test::MockModule';
build_requires 'Tapper::Test' => '2.010005';
build_requires 'File::Temp';


requires 'Tapper::Remote' => '1.000026';
requires 'Tapper::Base'   => '0.010015';
requires 'File::Basename';
requires 'File::Path';
requires 'File::Type';
requires 'Hash::Merge::Simple';
requires 'File::ShareDir';

requires 'Daemon::Daemonize';    # for simnow installer
requires 'IPC::Open3';
requires 'List::Util';
requires 'Log::Log4perl';
requires 'Method::Signatures';
requires 'Moose';

requires 'YAML';
requires 'YAML::Syck';

auto_install;

WriteAll;
