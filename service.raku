use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Routes;

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<WEBHOOK_HOST> ||
        die("Missing WEBHOOK_HOST in environment"),
    port => %*ENV<WEBHOOK_PORT> ||
        die("Missing WEBHOOK_PORT in environment"),
    application => routes(),
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<WEBHOOK_HOST>:%*ENV<WEBHOOK_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
