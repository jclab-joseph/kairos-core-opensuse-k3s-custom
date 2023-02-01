ARG BASE_IMAGE=quay.io/kairos/core-opensuse-k3s:v1.25.0-k3s1
FROM ${BASE_IMAGE} as stage-1

RUN zypper install -y kernel-default || true
RUN for name in $(rpm -qa | grep -E 'kernel-default-[0-9]' | sort -r | tail -n +2); do zypper rm -y $name; done

FROM stage-1 as builder
RUN zypper install -y kernel-default-devel lbzip2 tar bash make gcc binutils-devel || true

RUN mkdir -p /work
ADD ["r8125-9.011.00.tar.bz2", "/work"]
WORKDIR /work/r8125-9.011.00

RUN export KERNEL_BASEDIR=/lib/modules/$(ls /lib/modules/ | sort -r | head -n 1) && \
    make BASEDIR=${KERNEL_BASEDIR} && \
    make BASEDIR=${KERNEL_BASEDIR} install

FROM ${BASE_IMAGE}

RUN rm -rf /lib/modules /boot

COPY --from=builder ["/lib/modules", "/lib/modules"]
COPY --from=builder ["/boot", "/boot"]

RUN echo "blacklist r8169" > /etc/modprobe.d/blacklist-r8169.conf && \
    echo "r8125" > /etc/modules-load.d/r8125.conf && \
    mkinitrd
