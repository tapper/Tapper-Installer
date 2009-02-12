package Artemis::Installer::Logsave;

=head1 DEPRECATED

This module is only there to save ideas used in it for later use. It is currently not used but a similar functionality is planed.

=cut

use warnings;
use strict;
use DBI;
use Storable;
use IO::Socket::INET;
use Log::Log4perl;
use Artemis;
use Artemis::Installer::Client::Base qw(gethostname);
#use Artemis::Image::Installer;
use Artemis::Db::Handling;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(logsave);
our %EXPORT_TAGS = (
                    all => [qw(logsave)]
                   );

=head1 NAME

Artemis::Install::Logsave - Save logfiles after a testrun

=head1 SYNOPSIS

 use Artemis::Install::Logsave;


=head1 FUNCTIONS

=begin mount_testsystem

Mount all partitions belonging to the test system according to config file.

@param none

@return success - 0
@return error   - error string

=end mount_testsystem

=cut

sub mount_testsystem
{
        my ($confhash)=@_;
        my $basedir=$confhash->{basedir};

	foreach my $image (@{$confhash->{image_install}}) {
                if ($image->{mount} and $image->{partition}) {
                        my ($success, $partition)=Artemis::Image::Installer::get_device($image->{partition});
                        return $partition if not $success;
                        system("mount",$partition, $basedir.$image->{mount}) == 0 or return("Can't mount root partition: $!");
                }
        }
        return 0;

}

=begin logsave

Save logs generated in test phase.

@param 1. hash ref - hash containing all config options
@param 2. string   - path of the config file that contains the test information

@return success - 0
@return error   - error string

=end logsave

=cut

sub logsave
{
        #
        # WATCH OUT: 2008-09-18 ss5 sschwigo I did some changes to the paths in artemis.yml. Please double check!
        #

        my ($confhash, $ctp_conf_file) = @_;
	my $logger                       = Log::Log4perl->get_logger('local.logsave');
	my $hostname                     = gethostname();

	my $output_target                = Artemis->cfg->{paths}{output_target};
	my $basedir                      = Artemis->cfg->{paths}{base_dir};
	my $output_dir                   = Artemis->cfg->{paths}{output_dir};

	foreach my $thisdir (($basedir,$output_target)) {
		if (not -d $thisdir) {
			unlink($thisdir) if -e $thisdir; # delete if it's anything but a directory 
			system("mkdir","-p",$thisdir) == 0 or return("Can't create mount point for root partition: $!");
		}
	}

        my $retval;
        return "Can't mount test system:$retval" if $retval=mount_testsystem($confhash);

	$logger->info("Copying output files");
	opendir(DIR, "$basedir/$output_dir") or return("can't opendir $basedir/$output_dir: $! ");
	while (my $thisfile=readdir(DIR)) {
		next if $thisfile=~m/^\.+$/; # ignore . and ..
		system("cp","-r","$basedir/$output_dir/$thisfile",$output_target) == 0 or return("Can't copy output data to $output_target: $!");
	}
	closedir(DIR);



	my $dbhandle   = Artemis::Db::Handling->db_connect;
	my @testrunids = @{retrieve($ctp_conf_file)};
	foreach my $testrun (@testrunids) {
		my @tests=@{$testrun->{"tests"}};

	TEST:
		foreach my $test (@tests) {
			($logger->warn("not return value found for test ",$test->{"id"}) and next TEST) if not defined($test->{"retval"});
			my $statement="UPDATE tests_per_run SET return_value=".$test->{"retval"}." WHERE lid=".$test->{"id"};
		
			my $sth=$dbhandle->prepare($statement);
			if (not $sth->execute()) {
				$logger->info("Updating test ",$test->{"id"}," failed:",$sth->err(),". Continue to next test.");
				next TEST;
			}

			($logger->warn("not runtime found for test ",$test->{"id"}) and next TEST) if not defined($test->{"runtime"});
			$statement="UPDATE tests_per_run SET runtime=".$test->{"runtime"}." WHERE lid=".$test->{"id"};

			$sth=$dbhandle->prepare($statement);
			if (not $sth->execute()) {
				$logger->info("Updating test ",$test->{"id"}," failed:",$sth->err(),". Continue to next test.");
				next TEST;
			}
		}
	}
	$dbhandle->disconnect();
        return(0);
}

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

