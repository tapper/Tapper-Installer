package Tapper::Installer::Precondition::Repository;

use strict;
use warnings;

use File::Basename;
use Method::Signatures;
use Moose;
extends 'Tapper::Installer::Precondition';


=head1 NAME

Tapper::Installer::Precondition::Repository - Install a repository to a given location

=head1 SYNOPSIS

 use Tapper::Installer::Precondition::Repository;

=head1 FUNCTIONS

=cut


=head2 git_get 

This function encapsulates getting data out of a git repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=cut

method git_get($repo)
{
        return "no url given to git_get" if not $repo->{url};
        if (not $repo->{target}) {
                $repo->{target} = basename($repo->{url},(".git"));
        }
        $repo->{target} = $self->cfg->{paths}{base_dir}.$repo->{target};

	my ($error, $retval) = $self->log_and_exec("git","clone","-q",$repo->{url},$repo->{target});
        return($retval) if $error;
        
        if ($repo->{revision}) {
                chdir ($repo->{target});
                ($error,$retval) = $self->log_and_exec("git","checkout",$repo->{revision});
                return($retval) if $error;
        }
	return(0);
};

=head2 hg_get

This function encapsulates getting data out of a mercurial repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=cut 

method hg_get($repo)
{
        return "no url given to hg_get" if not $repo->{url};
        if (not $repo->{target}) {
                $repo->{target} = basename($repo->{url},(".hg"));
        }
        $repo->{target} = $self->cfg->{paths}{base_dir}.$repo->{target};

	my ($error, $retval) = $self->log_and_exec("hg","clone","-q",$repo->{url},$repo->{target});
        return($retval) if $error;
        
        if ($repo->{revision}) {
                ($error, $retval) = $self->log_and_exec("hg","update",$repo->{revision});
                return($retval) if $error;
        }
	return(0);
};

=head2 svn_get

This function encapsulates getting data out of a subversion repository.

@param hash reference - repository data

@retval success - 0
@retval error   - error string

=cut

method svn_get($repo)
{
        $self->log->error("unimplemented");
};


=head2 install


=cut

method install ($repository)
{
        return "No repository type given" if not $repository->{type};
        if ($repository->{type} eq "git") {
                return $self->git_get($repository);
        } elsif ($repository->{type} eq "hg") {
                return $self->hg_get($repository);
        } elsif ($repository->{type} eq "svn") {
                return $self->svn_get($repository);
        } else {
                return ("Unknown repository type:",$repository->{type});
        }
        return "Bug: Repository::install() got after if/else.";
};

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
