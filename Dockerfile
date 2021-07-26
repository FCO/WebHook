FROM    croservices/cro-http:0.8.5
RUN     mkdir /app
WORKDIR /app
RUN     apt-get update && apt-get install -y git build-essential linux-libc-dev uuid-dev libsqlite3-dev postgresql-client
RUN     zef install "NativeLibs:auth<github:salortiz>" --force-test
RUN     zef install LibUUID DB::Pg --exclude="pq:ver<5>:from<native>"
COPY    META6.json /app/META6.json
RUN     zef install --exclude="pq:ver<5>:from<native>" --deps-only --/test .
COPY    . /app
RUN     zef install --exclude="pq:ver<5>:from<native>" --/test . && raku -c -I. service.raku
ENV     WEBHOOK_HOST="0.0.0.0" WEBHOOK_PORT="9876"
EXPOSE  9876
CMD     raku -I. service.raku
