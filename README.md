# studienarbeit_function_generator
vhdl based function generator on Basys3 Board

## Instructionset

Befehlsname  | Hex-Code | Argumentbits | Funktion
-------------|----------|--------------|-----------------
SETCYCTICKS  | 0x01     | 23 - 0       | ändern der Zykluszeit der aktuellen Funktion
SETHIGH      | 0x02     | 11 - 0       | ändern des high Werts
SETLOW       | 0x03     | 11 - 0       | ändern des low Werts
SETDUTYCYCLE | 0x04     | 7 - 0        | ändern des dutycycles der Rechteckfunktion
SETWVFRM     | 0x05     | 1 - 0        | ändern der Funktion 
SETDIR       | 0x06     | 0            | ändern der Richtung der Rampenfunktion

documentation: https://github.com/markushart/function_generator_doku.git
