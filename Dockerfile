# build stage
FROM alpine:latest AS build
RUN apk update &&\
    apk upgrade &&\ 
    apk add --no-cache linux-headers alpine-sdk cmake tcl openssl-dev zlib-dev
WORKDIR /tmp
RUN git clone https://github.com/MakishimuAkuma/srt-live-server.git
RUN git clone --depth 1 --branch v1.5.4 https://github.com/Haivision/srt.git
WORKDIR /tmp/srt
RUN ./configure && make -j$(nproc) && make install
WORKDIR /tmp/srt-live-server
RUN echo "#include <ctime>"|cat - slscore/common.cpp > /tmp/out && mv /tmp/out slscore/common.cpp
RUN make -j$(nproc)

# final stage
FROM alpine:latest
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64
RUN apk update &&\
    apk upgrade &&\
    apk add --no-cache openssl libstdc++ &&\
    adduser -D srt &&\
    mkdir /etc/sls /logs &&\
    chown srt /logs
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/
COPY sls.conf /etc/sls/
VOLUME /logs
EXPOSE 1935/udp
USER srt
WORKDIR /home/srt
ENTRYPOINT [ "sls", "-c", "/etc/sls/sls.conf"]
