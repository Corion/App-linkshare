package App::linkshare;
our $VERSION = '0.01';

=head1 NAME

App::linkshare - simple url shortener/redirector for a single link

=head1 INSTALLATION

Copy C<linkshare.pl> from this distribution

Launch C<linkshare.pl> as

  linkshare.pl daemon

=head1 Available URLs

    /set

Form to set the target URL. This form also displays a Javascript bookmarklet
you can use to set any page as the target URL without leaving it.

    /

Redirects to the target URL. Tell this URL to friends who have trouble typing
longer URLs. Also, bookmark this URL on your phone to quickly share an URL from
your desktop to your phone.

    /iframe

Sets up the target browser to always follow the target URL. You can use this
to show and update the same HTML page on multiple browsers at the same time.
This URL only works if you start the script stand-alone.

=cut

1;
