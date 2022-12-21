FROM debian:11 as build_stage
MAINTAINER Marcel Hecko
LABEL org.opencontainers.image.authors="maco@blava.net"

RUN apt-get update
RUN apt-get install -y unzip wget git
RUN mkdir -p /opt/atpack
WORKDIR /opt
RUN wget https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/avr8-gnu-toolchain-3.7.0.1796-linux.any.x86_64.tar.gz
RUN tar xzfv avr8-gnu-toolchain-3.7.0.1796-linux.any.x86_64.tar.gz
WORKDIR /opt/atpack
RUN wget http://packs.download.atmel.com/Atmel.ATmega_DFP.2.0.401.atpack
RUN unzip Atmel.ATmega_DFP.2.0.401.atpack

WORKDIR /opt
RUN git clone https://github.com/Optiboot/optiboot.git
WORKDIR /opt/optiboot/optiboot/bootloaders/optiboot
RUN git reset --hard 55d1e6b36922e4b8e3a32e6cea8ec03127ed65bf

ENV GCC="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-gcc -B ../../../../atpack/gcc/dev/atmega328p/ -I ../../../../atpack/include/ -g -Wall -Os -fno-split-wide-types -mrelax -mmcu=atmega328p -DF_CPU=8000000L -DBAUD_RATE=57600 -DBIGBOOT=1 -DSUPPORT_EEPROM=1 -DLED=D5 -DLED_START_FLASHES=3 -DRS485=C3 -DWDTTIME=8 -DNO_START_APP_ON_POR=1"
ENV OBJCOPY="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-objcopy"
ENV OBJDUMP="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-objdump"
ENV SIZE="../../../../avr8-gnu-toolchain-linux_x86_64/bin/avr-size"

RUN $GCC -c -o optiboot.o optiboot.c
# 0x7c00 is in bytes, datasheet is 0x3e00 (in words)
RUN $GCC -Wl,--section-start=.text=0x7c00 -Wl,--section-start=.version=0x7ffe -Wl,--relax -nostartfiles -o optiboot.elf optiboot.o
RUN $OBJCOPY -j .text -j .data -j .version --set-section-flags .version=alloc,load -O ihex optiboot.elf optiboot.hex
RUN $OBJDUMP -h -S optiboot.elf > optiboot.lst
RUN $OBJDUMP -d optiboot.elf > optiboot.asm
RUN $SIZE -C optiboot.elf

FROM scratch AS export_stage
COPY --from=build_stage /opt/optiboot/optiboot/bootloaders/optiboot/optiboot.hex .
COPY --from=build_stage /opt/optiboot/optiboot/bootloaders/optiboot/optiboot.lst .
COPY --from=build_stage /opt/optiboot/optiboot/bootloaders/optiboot/optiboot.asm .
