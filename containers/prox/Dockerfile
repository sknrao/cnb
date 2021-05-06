##
## Copyright (c) 2019 Intel Corporation
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

##################################################
# Build all components in separate builder image #
##################################################
FROM centos:7 as builder

#
## Install required packages
##
RUN rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO && curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
RUN yum groupinstall -y "Development Tools"
RUN yum install -y wget numactl-devel git golang make; yum clean all
## Debug Tools (if needed):
##RUN yum install -y pciutils iproute; yum clean all
#
##
## Download and Build APP-NetUtil
##
WORKDIR /root/go/src/
RUN go get github.com/openshift/app-netutil 2>&1 > /tmp/UserspaceDockerBuild.log || echo "Can ignore no GO files."
WORKDIR /root/go/src/github.com/openshift/app-netutil
RUN make c_sample
RUN cp bin/libnetutil_api.so /lib64/libnetutil_api.so; cp bin/libnetutil_api.h /usr/include/libnetutil_api.h

#
## Download and Build DPDK
##
ENV DPDK_VER 20.05
ENV DPDK_DIR /usr/src/dpdk-${DPDK_VER}
WORKDIR /usr/src/
RUN wget http://fast.dpdk.org/rel/dpdk-${DPDK_VER}.tar.xz
RUN tar -xpvf dpdk-${DPDK_VER}.tar.xz
#
ENV RTE_TARGET=x86_64-native-linuxapp-gcc
ENV RTE_SDK=${DPDK_DIR}
WORKDIR ${DPDK_DIR}
## DPDK_VER 19.08
RUN sed -i -e 's/EAL_IGB_UIO=y/EAL_IGB_UIO=n/' config/common_linux
RUN sed -i -e 's/KNI_KMOD=y/KNI_KMOD=n/' config/common_linux
RUN sed -i -e 's/LIBRTE_KNI=y/LIBRTE_KNI=n/' config/common_linux
RUN sed -i -e 's/LIBRTE_PMD_KNI=y/LIBRTE_PMD_KNI=n/' config/common_linux

COPY ./vhost_substitute.sh ./vhost_substitute.sh
RUN ./vhost_substitute.sh

RUN make install T=${RTE_TARGET} DESTDIR=${RTE_SDK}

ARG BUILD_DIR=/opt/rapid

COPY ./port_info ${BUILD_DIR}/port_info

COPY ./deploycentostools.sh ${BUILD_DIR}/
RUN chmod +x ${BUILD_DIR}/deploycentostools.sh \
  && ${BUILD_DIR}/deploycentostools.sh -k deploy

#############################
# Create slim runtime image #
#############################
FROM centos:7

ARG BUILD_DIR=/opt/rapid

COPY ./deploycentostools.sh ${BUILD_DIR}/
COPY --from=builder ${BUILD_DIR}/install_components.tgz ${BUILD_DIR}/install_components.tgz
COPY --from=builder ${BUILD_DIR}/src ${BUILD_DIR}/src

RUN chmod a+rwx ${BUILD_DIR} && chmod +x ${BUILD_DIR}/deploycentostools.sh \
 && ${BUILD_DIR}/deploycentostools.sh -k runtime_image

# Expose SSH and PROX ports
EXPOSE 22 8474

# Copy SSH keys
#COPY ./rapid_rsa_key.pub /home/centos/.ssh/authorized_keys
#COPY ./rapid_rsa_key.pub /root/.ssh/authorized_keys

# Copy startup script
COPY ./start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
