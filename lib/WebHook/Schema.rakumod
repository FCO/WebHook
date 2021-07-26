use Red:api<2>;

my $schema = schema(
    subs => "WebHook::Subscription",
    call => "WebHook::Call",
    post => "WebHook::Post",
);
sub term:<webhook-schema> is export { $schema }
