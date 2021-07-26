use Red:api<2>;
use WebHook::Schema;
use Cro::HTTP::Router;
use Controller;

sub routes() is export {
    my $*RED-DEBUG          = $_ with %*ENV<RED_DEBUG>;
    my $*RED-DEBUG-RESPONSE = $_ with %*ENV<RED_DEBUG_RESPONSE>;
    my @conf                = (%*ENV<RED_DATABASE> // "SQLite").split(" ");
    my $driver              = @conf.shift;
    red-defaults $driver, |%( @conf.map: { do given .split: "=" { .[0] => .[1] } } );

    route {
        get -> "healthcheck" {
            content 'application/json', %(
                service => True,
                db      => Red.ping,
            );
        }
        post -> "api", "webhooks"                  { add-webhook }
        post -> "api", "webhooks", "test"          { call-subscriptions }
        get  -> "api", "webhooks", "test", Str $id { list-calls $id }
    }
}
