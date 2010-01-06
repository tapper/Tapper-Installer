use inc::Module::Install;

name     'Artemis-Installer';
all_from 'lib/Artemis/Installer.pm';
author   'OSRC SysInt Team <osrc-sysint@elbe.amd.com>';
license  'perl';

install_script 'bin/artemis-installer-client.pl';

build_requires 'Test::More';
build_requires 'Test::Fixture::DBIC::Schema';
build_requires 'Test::MockModule';
build_requires 'Test::More';
build_requires 'Artemis::Test' => '2.010005';
build_requires 'Artemis::Config' => '2.010053';

requires 'perl' => '5.010';
requires 'File::Basename';
requires 'File::Path';
requires 'File::Type';
requires 'Getopt::Long';
requires 'Hash::Merge::Simple';

requires 'IPC::Open3';
requires 'List::Util';
requires 'Log::Log4perl';
requires 'Method::Signatures';
requires 'Moose';
requires 'Net::TFTP';

requires 'Socket';
requires 'Sys::Hostname';
requires 'YAML';
requires 'YAML::Syck';

auto_install;

postamble("

live:
\t./scripts/dist_upload_wotan.sh dist
\t/data/bancroft/artemis/live/nfsroot/installation_base/opt/artemis/bin/cpan Artemis::Installer\"

devel:
\t./scripts/dist_upload_wotan.sh dist
\t/data/bancroft/artemis/development/nfsroot/installation_base/opt/artemis/bin/cpan Artemis::Installer\"
");

WriteAll;
