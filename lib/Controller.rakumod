use X::Red::Exceptions;
use Cro::HTTP::Router;
use Cro::Uri;
use WebHook::Schema;
unit module Contoller;

sub add-webhook is export {
    request-body
        -> % ( Str :$url!, Str :$token!, *%pars ) {
            note "Ignoring: { %pars.keys.map({ "'$_'" }).join: ", " }";
            CATCH {
                # Invalid URL
                when X::Cro::Uri::ParseError {
                    bad-request "application/json", %( :url( .message ) )
                }
                # Unique violated (url)
                when X::Red::Driver::Mapped::Unique {
                    bad-request "application/json", %( :url( "The url '$url' was already used." ) )
                }
            }
            Cro::Uri.parse: $url;
            webhook-schema.subs.^create: :$url, :$token
        },
        -> % ( Str :$url!, *%pars ) {
            note "Ignoring: { %pars.keys.map({ "'$_'" }).join: ", " }";
            my %error = :token("Token is required");
            CATCH {
                when X::Cro::Uri::ParseError {
                    bad-request "application/json", %( |%error, :url( .message ) )
                }
            }
            Cro::Uri.parse: $url;
            bad-request "application/json", %error
        },
        -> % ( Str :$token!, *%pars ) {
            note "Ignoring: { %pars.keys.map({ "'$_'" }).join: ", " }";
            bad-request "application/json", %( :url("URL is required") )
        },
        -> % ( *%pars ) {
            note "Ignoring: { %pars.keys.map({ "'$_'" }).join: ", " }";
            bad-request "application/json", %( :url("URL is required"), :token("Token is required") )
        },
}

sub call-subscriptions is export {
    request-body -> % ( :$payload ) {
        my $call = webhook-schema.call.create-call: :$payload;
        content "application/json", $call.Hash
    }
}

sub list-calls($id) is export {
    my $call = webhook-schema.call.^load(:$id);
    return not-found "application/json", %( :id("Not found") ) without $call;
    .&dd for $call.posts.Seq.map: *.Hash;
    content "application/json", $call.posts.Seq.map: *.Hash
}
