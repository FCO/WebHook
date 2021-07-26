#!/usr/bin/env raku

use Test;
use Red:api<2> <refreshable>;
use WebHook::Caller;
use WebHook::Post::Status;
use WebHook::Schema;

my $*RED-FALLBACK = False;
my $*RED-DEBUG    = ?%*ENV<RED_DEBUG>;

# Configure Red to use in memory sqlite
red-defaults "SQLite";

# Create DB schema
webhook-schema.create;

test-call;
test-call :404http-st;
test-call :http-st(UInt), :status(Error);

test-retry;

done-testing;

class Test::Caller does WebHook::Caller {
    has $.url;    has $.token; has $.payload;
    has $.status; has $.resp;  has $.http-st;
    method call($u, $t, $p --> Map()) is test-assertion {
        is $u, $!url, "The expected url";
        is $t, $!token, "The expected token";
        is $p, $!payload, "The expected payload";
        :$!status, :$!resp, :$!http-st
    }
}

state %used-urls;

sub test-call(
    :$url     = "http://bla",
    :$token   = "abc",
    :$payload = %( :bla<ble>, :bli{ :blo<blu> } ),
    :$status  = Done,
    :$resp    = "worked",
    :$http-st = 200,
) is test-assertion {
    subtest "test-call($url, $token, $payload, $status, $resp, { $http-st // "" })" => {
        without %used-urls{$url} {
            my $subs = webhook-schema.subs.^create: :$url, :$token;
            isa-ok $subs, webhook-schema.subs;
            is $subs.url, $url, "The expected url";
            is $subs.token, $token, "The expected token";
            %used-urls{$url} = True;
        }

        # Create call
        my $call = webhook-schema.call.^create: :$payload;
        $call.caller = Test::Caller.new: :$url, :$token, :$payload, :$status, :$resp, :$http-st;
        isa-ok $call.caller, Test::Caller;

        my @posts = $call.create-posts;
        is @posts.elems, 1, "One post created";
        isa-ok @posts.head, webhook-schema.post;
        isa-ok @posts.head.caller, Test::Caller;

        subtest "Call is working" => {
            plan 3;
            $call.run-posts: @posts;
        };

        is-deeply $call.posts.head.Hash, %( :$url, :$token, :$payload, :$status ), "Post with the expected state";
    }
}

sub test-retry(
    :$url         = "http://bla",
    :$token       = "abc",
    :$payload     = %( :bla<ble>, :bli{ :blo<blu> } ),
    :$status      = Done,
    :$resp        = "worked",
    :$http-st     = 200,
    :$max-retries = 3,
) is test-assertion {
    subtest "test-retry($url, $token, $payload, $status, $resp, { $http-st // "" }, $max-retries)" => {
        without %used-urls{$url} {
            my $subs = webhook-schema.subs.^create: :$url, :$token;
            isa-ok $subs, webhook-schema.subs;
            is $subs.url, $url, "The expected url";
            is $subs.token, $token, "The expected token";
            %used-urls{$url} = True;
        }

        my $time   = DateTime.now.earlier: :30seconds;
        my $caller = Test::Caller.new: :$url, :$token, :$payload, :$status, :$resp, :$http-st;

        # Create call
        my $call = webhook-schema.call.^create: :$payload, :$time;
        $call.caller = $caller;
        isa-ok $call.caller, Test::Caller;
        is $call.time, $time, "The expected time";

        my @posts = $call.create-posts: :status(Error);
        is @posts.elems, 1, "One post created";
        my $err-post = @posts.head;
        isa-ok $err-post, webhook-schema.post;
        isa-ok $err-post.caller, Test::Caller;
        isa-ok $err-post.status, Error;
        is $err-post.time, $time, "The expected time";
        is $err-post.tries, 0, "The expected tries";

        my $retry;
        subtest "Retry posts" => {
            plan 6;
            $retry = $call.retry-errors: :$caller, :sync
        };

        is-deeply $retry.posts.head.Hash, %( :$url, :$token, :$payload, :$status ), "Post with the expected state";
    }
}
