use v6.d;
use LibUUID;
use Red:api<2>;
use JSON::Fast;
use Red::Type::Json;
use WebHook::Post;
use WebHook::Caller;
use WebHook::Subscription;

#| Represents a call for running all webhooks posts
unit model WebHook::Call is table<call>;

has Str             $.id      is id      = ~UUID.new;
has DateTime        $.time    is column .= now;
has Json            $.payload is column;
has                 @.posts   is relationship(*.call-id, :model<WebHook::Post>);
has Promise         $.running is rw; #= A promise that keeps when all posts have finished
has WebHook::Caller $.caller  is rw;

#| Creates new Call obj and all Posts (based on subscriptions)
#| an run all them
method create-call(::?CLASS:U: $payload = %(), :$caller) {
    my $call = self.^create: :$payload;
    $call.caller = $_ with $caller;
    my @posts = $call.create-posts;
    $call.running = start $call.run-posts: @posts;
    $call
}

method create-posts(::?CLASS:D:) {
    do for WebHook::Subscription.^all.Seq -> $subs {
        my $post = $subs.posts.create: :call(self);
        $post.caller = $_ with $!caller;
        $post
    }
}

method run-posts(::?CLASS:D: @posts) {
    for @posts -> WebHook::Post:D $_ { .run }
}

method Hash { %( :$!id, :$!time, :$!payload ) }

#| How representing Call for humans
method gist {
    qq:to/END/
    id:      $!id
    time:    $!time
    payload: $!payload.&to-json()
    END
}
