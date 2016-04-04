#**Driver for RFID-reader by Parallax**

####Ment for [RFID-reader by Parallax - Product#28140][1] written in VHDL for Altera FPGA devices.

-------
###Intro
The reader is connected to the GPIO expansion of the Device. The device for which this driver was written is `"Cyclone IV E"/EP4CE115F29C7`. For you guys it matters only when cloning the repo and to using the [pin-assignemnts][2]. Take a look at them if you are using a different device.

The **User-manual**/**datasheet** for the reader was found [here][1] and can be viewed [here][manual-git-blob] within the repo, downloaded [here] [manual-git-blob].

The reader transmits data in a frequency of `125[khz]` through the RFID card and transmits through $S_{out}$ the data. As described in the manual is shown here:
![reader](https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/images/reader.png)

###Voltage Compatibility with the FPGA
You can use the GPIO expansion to provide voltage source to the driver and as GND:
> The DE2-115 Board provides one 40-pin expansion header. The header connects directly to 36 pins
of the Cyclone IV E FPGA, and also provides DC +5V (VCC5), DC +3.3V (VCC3P3), and two
GND pins

The GPIO I/O pins can't recieve higher voltage than $3.3[V]$, therefor **you must convert $S_{out}$'s voltage range from $5[V] - 0[V]$ to $3.3[V] - 0[V]$** with an external electrical circuit.
Quote from the manual for `DE2-115`:
> The voltage level of the I/O pins on the expansion headers can be adjusted to 3.3V, 2.5V, 1.8V, or
1.5V using JP6 (The default value is 3.3V[..])

I designed and implemented the following design:<sup>1</sup>
![circuit](https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/images/circuit.png)
####This is how the circuit work for every state of $S_{out}$:
|$S_{out}=5[V]$                     |$S_{out}=0[V]$
|-----------------------------------|------------------
|$V_{BB}>V_{CC}$                    |$V_{BB}=0[V]=I_B*R_1+V_{BE}+0$
|Transistor is on it's sub-threshold|$I_{BB}\approx 0[V]$
|$V_{R2}=3.3[V]$                    |Transistor is saturated
|$S_{in}=0[V]$                      |$I_{C} \geq I_{B}$
|                                   |$I_C = \dfrac {3.3[v]-S_{in}}{R_2}$
|                                   |$S_{in}=3.3[V]$

As you can see, there is an invertion for the signal coming out of the reader. Therefor there is a not statement in the design As well as in the pin-assignments.
###Communication Protocol
The broadcast is ascii codes send as serial output to $S_{out}$ as described in the Manual:
> All communication is 8 data bits, no parity, 1 stop bit, and least
significant bit first (8N1) at 2400 bps. The RFID Card Reader Serial
version transmits data as 5 V TTL-level, non-inverted asynchronous
serial. […], the tag’s unique ID will be transmitted as a 12-byte
printable ASCII string serially to the host in the following format:
The start byte and stop byte are used to easily identify that a
correct string has been received from the reader (they correspond to
line feed and carriage return characters, respectively). The middle
ten bytes are the actual tag's unique ID. For example, for a tag with
a valid ID of 0F0184F07A, the following bytes would be sent: 0x0A,
0x30, 0x46, 0x30, 0x31, 0x38, 0x34, 0x46, 0x30, 0x37, 0x41, 0x0D.

The reader is broadcasting at $2400[\frac{bits}{sec}]$, therefor it's maximum frequency is $1200[hz]$ because you need $2$ bits to make $1$ cycle. According to $Nyquist$, The sampling rate should be twice as much therefor it's $2400[hz]$. This is the sampling rate I chose with (created by a pll by Altera).
####Errors at Transporting
According to the communication protocol, There are $10$ bits send per byte. There are $2$ bytes for the end and start and $10$ bytes for the ID itself. Summing up all together leads to $12*10=120$ bits at total in one broadcast. 
*The sad truth* is that In real life there are Errors just like in any other communication protocol and The driver must be able to fix it. The errors that I got and I saw using `signaltap`<sup>2</sup> were extra bits sent randomly during the broadcast, usually $2$. I have sort of managed to fix it with the software, but I'll be more than glad to have pull-requests for [that section][reader.vhd|fixing].

I have here a very colorized sampling example of a few samples taken.<sup>3</sup>
![samples](https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/images/samples.png)

As you can see, Where I've putten red `z`, it's an error. Besides that, the start bit and end bit are `'0'` and `'1'` in conjunction.
####Fixing the Errors
Check out the [`reader.vhd`][reader.vhd|case] and the `case` named [`fixing`][reader.vhd|fixing] at line 145.

-----------
1. I had help from [123d.circuits.com](123d.circuits.com) to illustrate it.
2. The `signaltap` feature in `Quartus` enables you to see the actual bits that are sent through the device. It's was extremely usefull for me in this development.
3. You can Access the data via [the HTML version][samples.html]
[1]: https://www.parallax.com/product/28140
[2]: https://github.com/Doron-Behar/parallax-28140-RFID-reader/blob/master/pin-assignments.csv
[manual-git-blob]: https://github.com/Doron-Behar/parallax-28140-RFID-reader/blob/master/manual.pdf
[manual-git-raw]: https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/manual.pdf
[reader.png]: https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/images/reader.png
[samples.html]: https://raw.githubusercontent.com/Doron-Behar/parallax-28140-RFID-reader/master/samples.html
[reader.vhd|case]: https://github.com/Doron-Behar/parallax-28140-RFID-reader/blob/master/reader.vhd#L82
[reader.vhd|fixing]: https://github.com/Doron-Behar/parallax-28140-RFID-reader/blob/master/reader.vhd#L145
