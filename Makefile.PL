use inc::Module::Install;

name     'Artemis-Installer';
all_from 'lib/Artemis/Installer.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

install_script 'bin/artemis-installer-client.pl';
install_script 'bin/artemis-installer-simnow.pl';

author_requires 'Module::Install::WriteAll';

build_requires 'Test::More';
build_requires 'Test::Deep';
build_requires 'Test::Fixture::DBIC::Schema';
build_requires 'Test::MockModule';
build_requires 'Artemis::Test' => '2.010005';
build_requires 'File::Temp';


requires 'Artemis::Remote' => '1.000018';
requires 'Artemis::Base'   => '0.010015';
requires 'File::Basename';
requires 'File::Path';
requires 'File::Type';
requires 'Hash::Merge::Simple';


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
