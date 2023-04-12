# RGB Mixer


# Ingredients

* [iCEBreaker FPGA](https://1bitsquared.com/products/icebreaker)
* [7 segment display PMOD](https://1bitsquared.de/products/pmod-7-segment-display)
* Three resistors
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
* Decoder for detecting clockwise (CW, increment) and counter clockwise (CCW, decrement) rotation of the rotary encoder.
* LED display based on [icebreaker workshop](https://github.com/icebreaker-fpga/icebreaker-workshop).

# Circuits for connecting RGB LED and rotary encoder

TODO
* rotary encoder signals require pullup resistors.
* RGB LED requires resistor in series.

# Compile

## `test_led_display`

* Requirement: 7 segment display PMOD connected as PMODA1A.
* compile with `make PROJ=test_led_display prog`
* Repeatedly pressing button 1 should now count cyclically to 3 on the display.

## `test_bcd_saturated_counter`

* Requirement: 7 segment display PMOD connected as PMODA1A.
* compile with `make PROJ=test_bcd_saturated_counter prog`
* Repeatedly pressing button 1 should now count up to 10 on the display and stay there (saturate).
* Repeatedly pressing button 2 should now count down to 0 on the display and stay there (saturate).

## `test_rotary_encoder`

* Requirement: 
    * 7 segment display PMOD connected as PMODA1A.
    * rotary encoder connected according to the circuit above.
* compile with `make PROJ=test_rotary_decoder prog`
* turning the rotary encoder CW should count up to 10 and saturate.
* turning the rotary encoder CCW should count down to 0 and saturate.

## `main_rgb_mixer`

* Requirement: 
    * 7 segment display PMOD connected as PMODA1A.
    * rotary encoder connected according to the circuit above.
    * RGB LED connected according to the circuit above.
* compile with `make PROJ=main_rgb_mixer prog`
* pressing button 1 will cyclicly select between red, green, and blue. The selected color is also indicated by LED5, LED3, and LED4, respectively.
* turning the rotary encoder CW (CCW) should now increase (decrease) the strength of the selected color.
* the current strength of each color is also displayed.
* the color strengths saturate at the maximum value (default: 31) and the minimum value 0.

