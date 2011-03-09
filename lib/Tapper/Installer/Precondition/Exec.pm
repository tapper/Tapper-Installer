package Tapper::Installer::Precondition::Exec;

use strict;
use warnings;

use Method::Signatures;
use Moose;
use IO::Handle; # needed to set pipe nonblocking
use IO::Select;

extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Exec - Execute a program inside the installed system

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Exec;

=head1 FUNCTIONS

=cut

=head2 set_env_variables

Set environment variables for executed command/program.

=cut

sub set_env_variables
{
        my ($self) = @_;

        $ENV{TAPPER_TESTRUN}         = $self->cfg->{test_run};
        $ENV{TAPPER_SERVER}          = $self->cfg->{mcp_host};
        $ENV{TAPPER_REPORT_SERVER}   = $self->cfg->{report_server};
        $ENV{TAPPER_REPORT_API_PORT} = $self->cfg->{report_api_port};
        $ENV{TAPPER_REPORT_PORT}     = $self->cfg->{report_port};
        $ENV{TAPPER_HOSTNAME}        = $self->cfg->{hostname};
        return;
}

=head2 install

This function executes a program inside the installed system. This supersedes
the postinstall script facility of the package precondition and makes this
feature available to all other preconditions.

@param hash reference - contains all information about the program

@return success - 0
@return error   - error string

=cut

sub install
{
        my  ($self, $exec) = @_;

        my $command = $exec->{command};
        my @options;
        @options = @{$exec->{options}} if $exec->{options};

        if ($exec->{filename}) {
                $command = $self->cfg->{paths}{base_dir}.$exec->{filename};
                return("$command is not an executable") if not -x $command;
        }

        $self->log->debug("executing $command with options ",join (" ",@options));


	pipe (my $read, my $write);
	return ("Can't open pipe:$!") if not (defined $read and defined $write);

	# we need to fork for chroot
	my $pid = fork();
	return "fork failed: $!" if not defined $pid;

	# hello child
	if ($pid == 0) {
                $self->set_env_variables;

                close $read;
		# chroot to execute script inside the future root file system
                my ($error, $output) = $self->log_and_exec("mount -o bind /dev/ ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output)    = $self->log_and_exec("mount -t sysfs sys ".$self->cfg->{paths}{base_dir}."/sys");
                ($error, $output)    = $self->log_and_exec("mount -t proc proc ".$self->cfg->{paths}{base_dir}."/proc");
		chroot $self->cfg->{paths}{base_dir};
		chdir ("/");
                ($error, $output)=$self->log_and_exec($command,@options);
                print( $write $output, "\n") if $output;
                close $write;
                exit $error;
	} else {
                close $write;
                my $select = IO::Select->new( $read );
                my ($error, $output);
        MSG_FROM_CHILD:
                while (my @ready = $select->can_read()){
                        my $tmpout = <$read>;   # only read can be in @ready, since no other FH is in $select
                        last MSG_FROM_CHILD if not $tmpout;
                        $output.=$tmpout;
                }
                if ($output) {
                        my $outfile = $command;
                        $outfile =~ s/[^A-Za-z_-]/_/g;
                        $self->file_save($output,$outfile);
                }
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/dev");
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/sys");
                ($error, $output)=$self->log_and_exec("umount ".$self->cfg->{paths}{base_dir}."/proc");
                waitpid($pid,0);
                if ($?) {
                        return("executing $command failed");
                }
		return(0);
	}
}



1;

=head1 AUTHOR

AMD OSRC Tapper Team, C<< <tapper at amd64.org> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Tapper


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 AMD OSRC Tapper Team, all rights reserved.

This program is released under the following license: freebsd
