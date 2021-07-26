use v6.d;
use Red:api<2> <refreshable>;
use Red::Type::Json;
use WebHook::Caller;
use WebHook::HTTPCaller;
use WebHook::Post::Status;

#| Model representing a Post call for a webhook subscription
unit model WebHook::Post is table<post>;

has UInt                  $!id      is serial;
has UInt                  $!subs-id is referencing(*.id,       :model<WebHook::Subscription>);
has Str                   $!call-id is referencing(*.id,       :model<WebHook::Call>);
has                       $.subs    is relationship(*.subs-id, :model<WebHook::Subscription>) handles <url token>;
has                       $.call    is relationship(*.call-id, :model<WebHook::Call>);
has Json                  $.payload is column{ :nullable };
has UInt                  $.http-st is column{ :nullable } is rw;
has Str                   $.resp    is column{ :nullable, :type<text> } is rw;
has UInt                  $.tries   is column is rw = 0;
has                       $!orig-id is referencing(*.id,        :model<WebHook::Post>);
has                       $.orig    is relationship(*.orig-id, :model<WebHook::Post>);
has WebHook::Post::Status $.status  is column{
    :deflate{ .key },
    :inflate{ WebHook::Post::Status::{$_} },
} is rw = Pending;
has WebHook::Caller       $.caller  is rw = WebHook::HTTPCaller.new;

method Hash { %( :$.url, :$.token, :payload($!payload // $!call.payload), :$!status ) }

method time { $.call.time }

#| Runs the post request
method run {
    self.^refresh;
    my $payload = $!payload // $!call.payload;
    given $!caller.call: $.url, $.token, $payload -> % (:$status, :$resp, :$http-st) {
        $!status  = $_ with $status;
        $!resp    = $_ with $resp;
        $!http-st = $_ with $http-st;
        $!tries++;
        self.^save
    }
}

#| How representing Post for humans
method gist {
    qq:to/END/
    url:         $.url
    status:      $!status
    token:       { $.token   // "" }
    payload:     { $!payload // $!call.payload // "" }
    HTTP status: { $!http-st // "" }
    response:    { $!resp    // "" }
    END
}
