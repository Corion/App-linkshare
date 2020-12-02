#!perl
use Mojolicious::Lite '-signatures';
use Mojo::JSON 'encode_json';
use Mojo::File 'curfile', 'path';

our $VERSION = '0.01';
our $url;

=head1 NAME

App::linkshare - simple link redirector

=head1 USAGE

Install this file as a CGI file or launch it as

    server.pl daemon

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

# we are running as CGI, so persist in a file
our $is_cgi = defined $ENV{PATH_INFO} || defined $ENV{GATEWAY_INTERFACE};
if( $is_cgi ) {
    my $file = path(curfile->to_abs . '.state');
    if( -r $file->to_abs ) {
        $url = $file->slurp;
        $url =~ s!\s+$!!;
    };
}

sub update_url( $newurl ) {
    $url = $newurl;

    if( $is_cgi ) {
        path(curfile->to_abs . '.state')->spurt($url);
    }
    notify_clients({ src => $url });
}

get '/' => sub($c) {
    return $c->redirect_to($url);
};

get '/set' => sub( $c ) {
    if( my $url = $c->param('url')) {
        update_url( $url );
    };
    $c->stash( url => $url );
    $c->render( template => 'set');
};

post '/set' => sub($c) {
    update_url( $url );
    $c->stash( url => $url );
};

get '/iframe' => sub( $c ) {
    $c->stash( url => $url );
    $c->render( template => 'iframe');
};

my %clients;

my $id = 0;
websocket '/cnc' => sub( $c ) {
    $clients{ $id++ } = $c;

    $c->on( message => sub( $c, $msg ) {
        # we don't handle clients talking to us
    });
};

sub notify_clients( $msg ) {
    my $str = encode_json( $msg );
    for my $id (keys %clients) {
        eval {
            $clients{ $id }->send($str);
        };
        if( $@ ) {
            delete $clients{ $id };
        };
    };
}

app->start;

__DATA__
@@ set.html.ep
<html>
<body>
<form method="POST" url="/set">
<label for="url">Enter URL to share:</label>
<input id="url" type="text" name="url" placeholder="http://example.com" value="<%= $url %>" />
<input type="submit"/>
</form>
<a href="javascript:void(new Image().src='<%= $c->url_for('/set')->to_abs %>?url='+encodeURIComponent(document.location))">Bookmarklet for setting a link to the current page</a>
</body>
</html>

@@ iframe.html.ep
<!DOCTYPE html>
<html>
<head>
<!-- just in case the ws breaks down -->
<meta http-equiv="refresh" content="300; URL=<%= $c->url_for('/iframe') %>">
<title>URL receiver</title>
<script>
let ws_uri = "<%= $c->url_for('/cnc')->to_abs() =~ s!^http!ws!r %>";
window.uplink = new WebSocket(ws_uri);
window.uplink.onmessage = (event) => {
    let target = document.getElementById('iframe');
    console.log(event.data);
    let msg = JSON.parse(event.data);
    try {
        target.src = msg.src;
    } catch(e) {
        console.log(e);
    };
};
</script>
</head>
<body style="margin:0px; padding:0px;">
<iframe id="iframe" style="width: 100%; height: 100%; position: absolute; border: none;" frameborder="0" allowfullscreen allow='autoplay' src="<%= $url %>"/>
</body>
</html>
