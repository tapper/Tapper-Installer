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
build_requires 'Test::Perl::Critic';
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

postamble("
MOUNT=/opt/artemis/mnt
MOUNT64:=\${MOUNT}64
MOUNT32:=\${MOUNT}32
PKG_DIR=/data/bancroft/artemis/live/repository/packages/artemisutils/
PKG_DIR_DEV=/data/bancroft/artemis/development/repository/packages/artemisutils/

live:
\t./scripts/dist_upload_wotan.sh dist
\tssh artemis\@bancroft \"cd \${MOUNT64}; sudo chroot \${MOUNT64} /opt/artemis/bin/cpan Artemis::Installer; tar -czf \${PKG_DIR}/opt-artemis64.tar.gz opt/ etc/resolv.conf\"
\tssh artemis\@bancroft \"cd \${MOUNT32}; sudo chroot \${MOUNT32} /opt/artemis/bin/cpan Artemis::Installer; tar -czf \${PKG_DIR}/opt-artemis32.tar.gz opt/ etc/resolv.conf\"


devel:
\t./scripts/dist_upload_wotan.sh dist
\tssh artemis\@bancroft \"sudo mv \${MOUNT64}/opt \${MOUNT64}/opt.live; sudo mv \${MOUNT64}/opt.devel \${MOUNT64}/opt;\"
\tssh artemis\@bancroft \"cd \${MOUNT64}; sudo chroot \${MOUNT64} /opt/artemis/bin/cpan Artemis::Installer && tar -czf \${PKG_DIR_DEV}/opt-artemis64_devel.tar.gz opt/\"
\tssh artemis\@bancroft \"sudo mv \${MOUNT64}/opt \${MOUNT64}/opt.devel; sudo mv \${MOUNT64}/opt.live \${MOUNT64}/opt;\"

\tssh artemis\@bancroft \"sudo mv \${MOUNT32}/opt \${MOUNT32}/opt.live; sudo mv \${MOUNT32}/opt.devel \${MOUNT32}/opt;\"
\tssh artemis\@bancroft \"cd \${MOUNT32}; sudo chroot \${MOUNT64} /opt/artemis/bin/cpan Artemis::Installer && tar -czf \${PKG_DIR_DEV}/opt-artemis32_devel.tar.gz opt/\"
\tssh artemis\@bancroft \"sudo mv \${MOUNT32}/opt \${MOUNT32}/opt.devel; sudo mv \${MOUNT32}/opt.live \${MOUNT32}/opt;\"

");

WriteAll;
