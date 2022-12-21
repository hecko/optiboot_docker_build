FROM debian:11 as build_stage
MAINTAINER Marcel Hecko
LABEL org.opencontainers.image.authors="maco@blava.net"

RUN apt-get update
RUN apt-get install -y unzip wget
RUN mkdir -p /opt/atpack
WORKDIR /opt
RUN wget https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/avr8-gnu-toolchain-3.7.0.1796-linux.any.x86_64.tar.gz
RUN tar xzfv avr8-gnu-toolchain-3.7.0.1796-linux.any.x86_64.tar.gz
WORKDIR /opt/atpack
RUN wget http://packs.download.atmel.com/Atmel.ATmega_DFP.2.0.401.atpack
RUN unzip Atmel.ATmega_DFP.2.0.401.atpack
WORKDIR /opt
RUN wget https://github.com/Optiboot/optiboot/archive/refs/tags/v8.0.tar.gz
RUN tar xzfv v8.0.tar.gz
WORKDIR /opt/optiboot-8.0/optiboot/bootloaders/optiboot

ENV GCC="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-gcc -B ../../../../atpack/gcc/dev/atmega328pb/ -I ../../../../atpack/include/ -g -Wall -Os -fno-split-wide-types -mrelax -mmcu=atmega328pb -DF_CPU=8000000L -DBAUD_RATE=9600 -DLED=B5 -DLED_START_FLASHES=3"
ENV OBJCOPY="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-objcopy"
ENV OBJDUMP="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-objdump"
ENV SIZE="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-size"

RUN $GCC -c -o optiboot.o optiboot.c
RUN $GCC -Wl,--section-start=.text=0x7e00 -Wl,--section-start=.version=0x7ffe -Wl,--relax -nostartfiles -o optiboot.elf optiboot.o
RUN $OBJCOPY -j .text -j .data -j .version --set-section-flags .version=alloc,load -O ihex optiboot.elf optiboot.hex
RUN $OBJDUMP -h -S optiboot.elf > optiboot.lst
RUN $SIZE -C optiboot.elf

FROM scratch AS export_stage
COPY --from=build_stage /opt/optiboot-8.0/optiboot/bootloaders/optiboot/optiboot.hex .
