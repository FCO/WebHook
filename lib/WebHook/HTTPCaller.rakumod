use WebHook::Caller;
use Cro::HTTP::Client;
use WebHook::Post::Status;

#| Implements WebHook::Caller
unit class WebHook::HTTPCaller does WebHook::Caller;

method call($url, $token, $payload --> Map()) {
    my ($status, $resp, $http-st);
    {
        CATCH {
            default {
                $status = Error;
                $resp   = .message;
            }
        }
        with await Cro::HTTP::Client.post: $url, :content-type<application/json>, :body{ :$token, :$payload } {
            $resp    = $_ with await .body-text;
            $http-st = .status;
            $status  = (.status // 500) div 100 == 2 ?? Done !! Error;
        }
    }
    :$status, :$resp, :$http-st
}
