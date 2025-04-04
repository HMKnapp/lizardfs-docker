FROM alpine:3.18

# Install OpenSSH first to avoid recreating keys later
RUN apk add --no-cache openssh-server

# For SSH access (sshfs)
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config
RUN ssh-keygen -A

# Add minimal build dependencies for LizardFS
RUN apk add --no-cache git cmake build-base boost-dev fuse fuse-dev fuse3 fuse3-dev zlib-dev fmt-dev spdlog-dev bash python3 python3-dev py3-pip htop vim openssh-server openjdk17-jre-headless rsync

# Get latest source code from LizardFS repository
RUN git clone --recursive --depth 1 --branch 3.13-rc4-testing https://github.com/lizardfs/lizardfs

# Build LizardFS, ignoring infinite-recursion warning
# Use all CPU cores for building
RUN cd lizardfs && \
    export CXXFLAGS="-Wno-error=infinite-recursion" && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    rm -r ../lizardfs

# Create directories for LizardFS
RUN mkdir -p /var/lib/lizardfs /var/log/lizardfs /etc/lizardfs

RUN addgroup --g 10001 lizardfs 
RUN adduser -u 1000 -G lizardfs -D lizardfs

# Copy OpenRC init scripts for LizardFS
COPY scripts/openrc/lizardfs-* /etc/init.d/

# Add entrypoint script
COPY scripts/*.sh /usr/local/bin/

ENTRYPOINT [ "entrypoint.sh" ]
