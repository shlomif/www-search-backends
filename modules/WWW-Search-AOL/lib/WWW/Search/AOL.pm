package WWW::Search::AOL;

use warnings;
use strict;

require WWW::Search;

use WWW::SearchResult;
use Encode;

use Scalar::Util ();

=head1 NAME

WWW::Search::AOL - backend for searching search.aol.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.0101';

use vars qw(@ISA);

@ISA=(qw(WWW::Search));

=head1 SYNOPSIS

This module provides a backend of L<WWW::Search> to search using 
L<http://search.aol.com/>.

    use WWW::Search;

    my $oSearch = WWW::Search->new("AOL");

=head1 FUNCTIONS

All of these functions are internal to the module and are of no concern
of the user.

=head2 native_setup_search()

This function sets up the search.

=cut

sub native_setup_search
{
    my ($self, $native_query, $opts) = @_;

    $self->{'_hits_per_page'} = 10;

    $self->user_agent('non-robot');

    $self->{'_next_to_retrieve'} = 1;

    $self->{'search_base_url'} ||= 'http://search.aol.com';
    $self->{'search_base_path'} ||= '/aolcom/search';

    if (!defined($self->{'_options'}))
    {
        $self->{'_options'} = +{
            'query' => $native_query,
            'invocationType' => 'topsearchbox.webhome',
        };
    }
    my $self_options = $self->{'_options'};

    if (defined($opts))
    {
        foreach my $k (keys %$opts)
        {
            if (WWW::Search::generic_option($k))
            {
                if (defined($opts->{$k}))
                {
                    $self->{$k} = $opts->{$k};
                }
            }
            else
            {
                if (defined($opts->{$k}))
                {
                    $self_options->{$k} = $opts->{$k};
                }
            }
        }
    }

    $self->{'_next_url'} = $self->{'search_base_url'} . $self->{'search_base_path'} . '?' . $self->hash_to_cgi_string($self_options);
    $self->{'_AOL_first_retrieve_call'} = 1;
}

=head2 parse_tree()

This function parses the tree and fetches the results.

=cut

sub parse_tree
{
    my ($self, $tree) = @_;

    if ($self->{'_AOL_no_results_found'})
    {
        return 0;
    }

    if ($self->{'_AOL_first_retrieve_call'})
    {
        $self->{'_AOL_first_retrieve_call'} = undef;

        my $nohit_div = $tree->look_down("_tag", "div", "id", "nohit");

        if (defined($nohit_div))
        {
            if (($nohit_div->as_text() =~ /Your search for/) &&
                ($nohit_div->as_text() =~ /returned no results\./)
               )
            {
                $self->approximate_result_count(0);
                $self->{'_AOL_no_results_found'} = 1;
                return 0;
            }
        }

        my $wr_div = $tree->look_down("_tag", "div", "id", "wr");

        if ($wr_div->as_text() =~ m{page 1 of (\d+)})
        {
            my $n = $1;
            $self->approximate_result_count($n*10);
        }
    }

=begin Removed

    my @h1_divs = $tree->look_down("_tag", "div", "class", "h1");
    my $requested_div;
    foreach my $div (@h1_divs)
    {
        my $h1 = $div->look_down("_tag", "h1");
        if ($h1->as_text() eq "web results")
        {
            $requested_div = $div;
            last;
        }
    }
    if (!defined($requested_div))
    {
        die "Could not find div. Please report the error to the author of the module.";
    }

    my $r_head_div = $requested_div->parent();
    my $r_web_div = $r_head_div->parent();
    
=end Removed

=cut

    my $wr_div = $tree->look_down("_tag", "div", "id", "wr");
    my $r_web_div = $wr_div->look_down("_tag", "div", "class", "r-web");
    my @results_divs = $r_web_div->look_down("_tag", "div", "id", qr{^r\d+$});
    my $hits_found = 0;
    foreach my $result (@results_divs)
    {
        if ($result->attr('id') !~ m/^r(\d+)$/)
        {
            die "Broken Parsing. Please contact the author to fix it.";
        }
        my $id_num = $1;
        my $url_tag = $result->look_down("_tag", "b", "id", "ldurl$id_num");
        my $desc_tag = $result->look_down("_tag", "p", "id", "ldesc$id_num");
        my $a_tag = $result->look_down("_tag", "a", "id", "lrurl$id_num");
        my $hit = WWW::SearchResult->new();
        $hit->add_url($url_tag->as_text());
        $hit->description($desc_tag->as_text());
        $hit->title($a_tag->as_text());
        push @{$self->{'cache'}}, $hit;
        $hits_found++;
    }

    # Get the next URL
    {
        my $pagination_div = $tree->look_down("_tag", "div", "class", "pagination");
        my @a_tags = $pagination_div->look_down("_tag", "a");
        # The reverse() is because it seems the "next" link is at the end.
        foreach my $a_tag (reverse(@a_tags))
        {
            if ($a_tag->as_text() =~ "next")
            {
                $self->{'_next_url'} =
                    $self->absurl(
                        $self->{'_prev_url'},
                        $a_tag->attr('href')
                    );
                last;
            }
        }
    }
    return $hits_found;
}

=head2 preprocess_results_page()

The purpose of this function is to decode the HTML text as returned by
search.aol.com as UTF-8.

=cut

sub preprocess_results_page
{
    my $self = shift;
    my $contents = shift;

    return decode('UTF-8', $contents);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

Funded by L<http://www.deviatemedia.com/> and
L<http://www.redtreesystems.com/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-search-aol@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-AOL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Funded by L<http://www.deviatemedia.com/> and
L<http://www.redtreesystems.com/>.

=head1 DEVELOPMENT

Source code is version-controlled in a Subversion repository in Berlios:

L<http://svn.berlios.de/svnroot/repos/web-cpan/WWW-Search/trunk/>

One can find the most up-to-date version there.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11 (a BSD-style
license).

=cut

1; # End of WWW::Search::AOL
