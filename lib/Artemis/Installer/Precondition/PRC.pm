package Artemis::Installer::Precondition::PRC;

use strict;
use warnings;

use File::Basename;
use Hash::Merge::Simple 'merge';
use File::ShareDir      'module_file';
use Method::Signatures;
use Moose;
use YAML;
extends 'Artemis::Installer::Precondition';


=head1 NAME

Artemis::Installer::Client::Precondition::PRC - Install Program Run Control to a given location

=head1 SYNOPSIS

 use Artemis::Installer::Client::Precondition::PRC;

=head1 FUNCTIONS

=cut


=head2 create_config

Generate a config for PRC. Take special care for virtualisation
environments. In this case, the host system runs a proxy which collects status
messages from all virtualisation guests.

@param hash reference - contains all information about the PRC to install

@return success - (0, config hash)
@return error   - (1, error string)

=cut

method create_config($prc)
{
        my $config = merge($prc->{config}, {paths=>$self->{cfg}->{paths}});
        $config    = merge($config, {times=>$self->{cfg}->{times}});
        my @timeouts;

        if ($prc->{config}->{guest_count})
        {
                $config->{guest_count} = $prc->{config}->{guest_count};
                $config->{server}      = 'localhost';
                $config->{mcp_server}  = $self->{cfg}->{server};
                $config->{timeouts}    = $prc->{config}->{timeouts};
        }
        elsif ($prc->{mountpartition} or $prc->{mountfile})
        {
                $config->{server}      = $self->{cfg}->{hostname};
        }
        else
        {
                $config->{server}      = $self->{cfg}->{server};
        }
        
        $config->{report_server}   = $self->{cfg}->{report_server};
        $config->{report_port}     = $self->{cfg}->{report_port};
        $config->{report_api_port} = $self->{cfg}->{report_api_port};
        $config->{hostname}        = $self->{cfg}->{hostname};  # allows guest systems to know their host system name
        $config->{test_run}        = $self->{cfg}->{test_run};
        $config->{port}            = $self->{cfg}->{mcp_port} if $self->{cfg}->{mcp_port};
        $config->{prc_nfs_server}  = $self->{cfg}->{prc_nfs_server} if $self->{cfg}->{prc_nfs_server}; # prc_nfs_path is set by merging paths above

        return (0, $config);
};


=head2 install

Install the tools used to control running of programs on the test
system. This function is implemented to fullfill the needs of kernel
testing and is likely to change dramatically in the future due to
limited extensibility. Furthermore, it has the name of the PRC hard
coded which isn't a good thing either.

@param hash ref - contains all information about the PRC to install

@return success - 0
@return error   - return value of system or error string

=cut

method install($prc)
{

        my $basedir = $self->cfg->{paths}{base_dir};
        my $distro=$self->get_distro($basedir);
        my ($error, $retval);
        if (not -d "$basedir/etc/init.d" ) {
                mkdir("$basedir/etc/init.d") or return "Can't create /etc/init.d/ in $basedir";
        }
        ($error, $retval) = $self->log_and_exec("cp",module_file('Artemis', "startfiles/$distro/etc/init.d/artemis"),"$basedir/etc/init.d/artemis");
        return $retval if $error;
        if ($distro!~/artemis/) {
        
                pipe (my $read, my $write);
                return ("Can't open pipe:$!") if not (defined $read and defined $write);

                # fork for the stuff inside chroot
                my $pid     = fork();
                return "fork failed: $!" if not defined $pid;
	
                # child
                if ($pid == 0) {
                        close $read;
                        chroot $basedir;
                        chdir ("/");
		
                        my $ret = 0;
                        my ($error, $retval);
                        if ($distro=~m/suse/) {
                                ($error, $retval)=$self->log_and_exec("insserv","/etc/init.d/artemis");
                        } elsif ($distro=~m/(redhat)|(fedora)/) {
                                ($error, $retval)=$self->log_and_exec("chkconfig","--add","artemis"); 
                        } elsif ($distro=~/gentoo/) {
                                ($error, $retval)=$self->log_and_exec("rc-update", "add", "artemis_gentoo", "default");
                        } else {
                                ($error, $retval)=(1,"No supported distribution detected.");
                        }
                        print($write "$retval") if $error;
                        close $write;
                        exit $error;
                } else {        # parent
                        close $write;
                        waitpid($pid,0);
                        if ($?) {
                                my $output = <$read>;
                                return($output);
                        }
                }
        }

        my $config;
        ($error, $config) = $self->create_config($prc);
        return $config if $error;

        open FILE, '>',$basedir.'/etc/artemis' or return "Can not open /etc/artemis in $basedir:$!";
        print FILE YAML::Dump($config);
        close FILE;
        
        if ($prc->{artemis_package}) {
                my $pkg_object=Artemis::Installer::Client::Precondition::Package->new($self->cfg);
                my $package={filename => basename($prc->{artemis_package}),
                             path => dirname($prc->{artemis_package})};
                $self->logdie($retval) if $retval = $pkg_object->install($package);
        }

        return 0;
}
;


=head2 get_distro

Find out which distribution is installed below the directory structure
given as argument. The guessed distribution is returned as a string.

@param string - path name under which to check for an installed
distribution

@return success - name of the distro
@return error   - empty string

=cut

method get_distro($dir)
{
	my @files=glob("$dir/etc/*-release");
	for my $file(@files){
		return "suse"    if $file  =~ /suse/i;
		return "redhat"  if $file  =~ /redhat/i;
		return "gentoo"  if $file  =~ /gentoo/i;
		return "artemis" if $file  =~ /artemis/i;
	}
	return "";
};


1;

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Artemis


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive
