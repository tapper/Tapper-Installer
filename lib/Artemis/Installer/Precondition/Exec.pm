package Artemis::Installer::Precondition::Exec;

use strict;
use warnings;

use Method::Signatures;
use Moose;
use IO::Handle; # needed to set pipe nonblocking
extends 'Artemis::Installer::Precondition';


=head1 NAME

Artemis::Installer::Precondition::Exec - Execute a program inside the installed system

=head1 SYNOPSIS

 use Artemis::Installer::Precondition::Exec;

=head1 FUNCTIONS

=cut


=head2 install

This function executes a program inside the installed system. This supersedes
the postinstall script facility of the package precondition and makes this
feature available to all other preconditions.

@param hash reference - contains all information about the program

@return success - 0
@return error   - error string

=cut

method install ($exec)
{
        my $filename = $exec->{filename};
        my @options;
        @options = @{$exec->{options}} if $exec->{options};

	$self->log->debug("executing $filename with options ",join (" ",@options));

        my $fullpath = $self->cfg->{paths}{base_dir}.$filename;
        return("$filename is not an executable") if not -x $fullpath;
        
	pipe (my $read, my $write);
	return ("Can't open pipe:$!") if not (defined $read and defined $write);
	
	# we need to fork for chroot
	my $pid = fork();
	return "fork failed: $!" if not defined $pid;
	
	# hello child
	if ($pid == 0) {
                close $read;
		# chroot to execute script inside the future root file system
		chroot $self->cfg->{paths}{base_dir};
		chdir ("/");
                my ($error, $output)=$self->log_and_exec($filename,@options);
                print( $write $output, "\n") if $output;
                close $write;
                exit $error;
	} else {
                close $write;
                my $select = new IO::Select( $read );
                my $output;
        MSG_FROM_CHILD:
                while (my @ready = $select->can_read()){
                        my $tmpout = <$read>;   # only read can be in @ready, since no other FH is in $select
                        last MSG_FROM_CHILD if not $tmpout;
                        $output.=$tmpout;
                }
                if ($output) {
                        my $outfile = $filename;
                        $outfile =~ s/[^A-Za-z_-]/_/g;
                        $self->file_save($output,$outfile);
                }
                waitpid($pid,0);
                if ($?) {
                        return("executing $filename failed");
                }
		return(0);
	}
}
;


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