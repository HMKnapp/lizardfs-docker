FROM alpine:3.18
RUN apk add --no-cache git cmake build-base boost-dev fuse-dev fuse3-dev zlib-dev fmt-dev spdlog-dev
RUN git clone --recursive https://github.com/lizardfs/lizardfs
RUN cd lizardfs && \
    export CXXFLAGS="-Wno-error=infinite-recursion" && \
    ./configure && \
    make -j$(nproc)
RUN mkdir -p /var/lib/mfs /var/log/mfs /etc/lizardfs
RUN cp /lizardfs/src/data/mfsmaster.cfg.in /etc/lizardfs/mfsmaster.cfg
RUN cp /lizardfs/src/data/mfsexports.cfg /etc/lizardfs/mfsexports.cfg
RUN cp /lizardfs/src/data/mfsgoals.cfg /etc/lizardfs/mfsgoals.cfg
RUN cp /lizardfs/src/data/mfsmetalogger.cfg.in /etc/lizardfs/mfsmetalogger.cfg
RUN cp /lizardfs/src/data/mfsmount.cfg /etc/lizardfs/mfsmount.cfg
RUN cp /lizardfs/src/data/mfschunkserver.cfg.in /etc/lizardfs/mfschunkserver.cfg
