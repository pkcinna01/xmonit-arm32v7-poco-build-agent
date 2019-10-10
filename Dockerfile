FROM alpine AS builder

ENV QEMU_URL https://github.com/multiarch/qemu-user-static/releases/download/v4.1.0-1/qemu-arm-static.tar.gz
RUN apk add curl && curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

FROM arm32v7/ubuntu:disco

COPY --from=builder qemu-arm-static /usr/bin

RUN apt-get -y update
RUN apt-get -y upgrade

RUN apt-get -y install vim wget
RUN apt-get -y install build-essential
RUN apt-get -y install cmake git
RUN apt-get -y install openssl libssl-dev
#RUN apt-get -y install libpoco-dev

ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

WORKDIR /src
RUN git clone -b master https://github.com/pocoproject/poco.git

WORKDIR /src/poco
RUN git checkout poco-1.9.4-release 

RUN mkdir cmake-build
WORKDIR /src/poco/cmake-build

RUN cmake -DCMAKE_BUILD_TYPE=Release ..
RUN make install

RUN rm -rf /src/poco/cmake-build/*
RUN cmake -DCMAKE_BUILD_TYPE=Debug ..
RUN make install

RUN rm -rf /src/poco/cmake-build/*
RUN cmake -DPOCO_STATIC=1 -DCMAKE_BUILD_TYPE=Release ..
RUN make install

RUN rm -rf /src/poco/cmake-build/*
RUN cmake -DPOCO_STATIC=1 -DCMAKE_BUILD_TYPE=Debug ..
RUN make install

RUN rm -rf /src/poco/cmake-build

# Include Prometheus here for now (needed by solar-power-mgr app)
RUN apt-get -y install zlib1g-dev libcurl4-openssl-dev

RUN cd /src && git clone https://github.com/jupp0r/prometheus-cpp.git

WORKDIR /src/prometheus-cpp
RUN git submodule init && git submodule update
RUN mkdir /src/prometheus-cpp/build

WORKDIR /src/prometheus-cpp/build
RUN cmake .. -DBUILD_SHARED_LIBS=ON -DENABLE_TESTING=OFF
RUN make -j 
#RUN ctest -v
RUN make install

RUN rm -rf /src/prometheus-cpp/build/*
RUN cmake .. -DBUILD_SHARED_LIBS=OFF -DENABLE_TESTING=OFF
RUN make -j
#RUN ctest -v
RUN make clean install

RUN rm -rf /src/prometheus-cpp/build

WORKDIR /


