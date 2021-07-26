use v6.d;
use Red:api<2>;

#| Represents a subscription
unit model WebHook::Subscription is table<subs>;

has UInt $!id    is serial;
has Str  $.url   is unique;
has Str  $.token is column{ :nullable };
has      @.posts is relationship(*.subs-id, :model<WebHook::Post>);

#| How representing Subscription for humans
method gist {
    qq:to/END/
    url:   $!url
    token: { $!token // "" }
    END
}
