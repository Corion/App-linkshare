use Mojolicious::Lite '-signatures';
use Mojo::JSON 'encode_json';

our $url;

get '/' => sub($c) {
    return $c->redirect_to($url);
};

get '/set' => sub( $c ) {
    if( my $url = $c->param('url')) {
        $url = $c->param('url');
        notify_clients({ src => $url });
    };
    $c->stash( url => $url );
    $c->render( template => 'set');
};

post '/set' => sub($c) {
    $url = $c->param('url');
    $c->stash( url => $url );
    notify_clients({ src => $url });
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
<a href="javascript:(function(){(new%20Image()).src='<%= $c->url_for('/set')->to_abs %>?url='+encodeURI(window.location.href)})">Bookmarklet for setting a link to the current page</a>
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