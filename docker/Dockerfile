FROM alpine:3.18

# Add minimal build dependencies for LizardFS
RUN apk add --no-cache git cmake build-base boost-dev fuse-dev fuse3-dev zlib-dev fmt-dev spdlog-dev bash python3 python3-dev py3-pip

# Get latest source code from LizardFS repository
RUN git clone --recursive --depth 1 https://github.com/lizardfs/lizardfs

# Build LizardFS, ignoring infinite-recursion warning
# Use all CPU cores for building
RUN cd lizardfs && \
    export CXXFLAGS="-Wno-error=infinite-recursion" && \
    ./configure && \
    make -j$(nproc) && \
    make install

# Create configuration files
RUN mkdir -p /var/lib/mfs /var/log/mfs /etc/lizardfs
RUN cp /lizardfs/src/data/mfsmaster.cfg.in /etc/lizardfs/mfsmaster.cfg
RUN cp /lizardfs/src/data/mfsexports.cfg /etc/lizardfs/mfsexports.cfg
RUN cp /lizardfs/src/data/mfsgoals.cfg /etc/lizardfs/mfsgoals.cfg
RUN cp /lizardfs/src/data/mfsmetalogger.cfg.in /etc/lizardfs/mfsmetalogger.cfg
RUN cp /lizardfs/src/data/mfsmount.cfg /etc/lizardfs/mfsmount.cfg
RUN cp /lizardfs/src/data/mfschunkserver.cfg.in /etc/lizardfs/mfschunkserver.cfg

# Copy OpenRC init scripts for LizardFS
COPY scripts/openrc/lizardfs-* /etc/init.d/
