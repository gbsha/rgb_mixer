# RGB Mixer



# Ingredients

* [iCEBreaker FPGA](https://1bitsquared.com/products/icebreaker)
* Seven 3k resistors
* One RGB LED
* One [rotary encoders](https://eu.mouser.com/datasheet/2/54/pec11l-777793.pdf)
* Breadboard
* Wires

# Implementation

The following concepts are used:
* Clock divider to generate slower clocks required for
    * pulse width modulation.
    * user input.
* Debounce signals from input pins.
* Decoder for detecting clockwise (increment) and counter clockwise (decrement) rotation of the rotary encoder.
* LED display based on [icebreaker workshop](https://github.com/icebreaker-fpga/icebreaker-workshop).

# Circuit for connecting RGB LED and rotary encoder

TODO