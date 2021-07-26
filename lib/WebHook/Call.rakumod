use v6.d;
use LibUUID;
use Red:api<2>;
use JSON::Fast;
use Red::Type::Json;
use WebHook::Post;
use WebHook::Caller;
use WebHook::Post::Status;
use WebHook::Subscription;

#| Represents a call for running all webhooks posts
unit model WebHook::Call is table<call>;

has Str             $.id          is id      = ~UUID.new;
has Instant         $.time        is column = now;
has Json            $.payload     is column;
has                 @.posts       is relationship(*.call-id, :model<WebHook::Post>);
has Bool            $.retry       is column = False;
has UInt            $.max-retries is column = 3;
has Promise         $.running     is rw; #= A promise that keeps when all posts have finished
has WebHook::Caller $.caller      is rw;

method retry-errors(UInt :$max-retries = 3, :$caller, Bool :$sync = False) {
    my $call = self.WHAT.^create: :retry, :$max-retries, :payload("");
    $call.caller = $_ with $caller;
    my @errors = WebHook::Post.^all.grep: {
        .tries < $max-retries && .status == Error
    }
    my @posts = do for @errors.Seq -> WebHook::Post:D $_ {
        my $post = WebHook::Post.^create: :subs(.subs), :payload(.payload // .call.payload), :tries(.tries), :$call;
        $post.caller = $_ with $caller;
        $post
    }
    $call.running = do if $sync {
        $call.run-posts: @posts;
    } else {
        start $call.run-posts: @posts;
    }
    $call
}

#| Creates new Call obj and all Posts (based on subscriptions)
#| an run all them
method create-call(::?CLASS:U: $payload = %(), :$caller, Bool :$sync = False) {
    my $call = self.^create: :$payload;
    $call.caller = $_ with $caller;
    my @posts = $call.create-posts;
    $call.running = do if $sync {
        $call.run-posts: @posts;
    } else {
        start $call.run-posts: @posts;
    }
    $call
}

method create-posts(::?CLASS:D:) {
    do for WebHook::Subscription.^all.Seq -> $subs {
        my $post = $subs.posts.create: :call(self), :payload($!payload), |%_;
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
