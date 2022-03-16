import serial
# import time
import os


class FuncGenUART:
    # used to convert between hex and decimal numbers
    H2I = [str(i) for i in range(10)] + ['a', 'b', 'c', 'd', 'e', 'f']

    BAUDRATE = 115200

    # instruction set
    CLEAR = [0xff for i in range(4)]
    CYCTICKS = 1
    HIGH = 2
    LOW = 3
    DUTYCYCLE = 4
    WVFRM = 5
    DIRECTION = 6

    CONST, PWM, ZIGZAG, RAMP = range(4)

    PRESCALE = 4 * 17
    FSYS = 100e6
    FMAX = FSYS / PRESCALE
    # defined by PRESCALE and the width of cyc_tick register
    FMIN = FSYS / PRESCALE / 2**24

    @staticmethod
    def list_of_bytes(Z: int) -> list:
        hexlit = list(hex(int(Z))[2:])
        if len(hexlit) % 2 == 1:
            # append one 0 infront of hexlit
            hexlit = ['0'] + hexlit
        lb = []
        while len(hexlit) > 0:
            s1, s0 = hexlit.pop(0), hexlit.pop(0)
            lb += [16 * FuncGenUART.H2I.index(s1) + FuncGenUART.H2I.index(s0)]
        return lb

    @staticmethod
    def int2arg(Z: int):
        lb = FuncGenUART.list_of_bytes(Z)
        if len(lb) < 3:
            lb = [0] * (3 - len(lb)) + lb
        elif len(lb) > 3:
            lb = lb[:3]
        return lb

    def __init__(self, port="/dev/ttyUSB1"):
        self.serial = serial.Serial(port, baudrate=FuncGenUART.BAUDRATE)

    def send_instruction(self, instruction):
        self.serial.write(bytearray(instruction))

    def read_buffer(self):
        buffer = []
        while self.serial.in_waiting:
            buffer.append(self.serial.read())
        return buffer

    def set_frequency(self, f: float):
        assert FuncGenUART.FMAX >= f > FuncGenUART.FMIN, \
             "f must be greater than %.2f and less than / equal to %.2f but was %.2f!" % (FuncGenUART.FMAX, FuncGenUART.FMIN, f)
        ct = int(FuncGenUART.FMAX / f)
        self.send_instruction([FuncGenUART.CYCTICKS] + FuncGenUART.int2arg(ct))
        return ct

    def set_waveform(self, wv: int):
        if wv in range(4):
            self.send_instruction([FuncGenUART.WVFRM, 0, 0, wv])
        else:
            raise ValueError("wv must be 0, 1, 2 or 3!")

    def set_dutycycle(self, dc: int):
        dc = dc if dc < 256 else 255
        dc = dc if dc > 0 else 0
        self.send_instruction([FuncGenUART.DUTYCYCLE, 0, 0, dc])
        return dc

    def set_high(self, h: float):
        h = abs(h) if abs(h) < 3.3 else 3.3
        h = int((h / 3.3) * 4095)
        self.send_instruction([FuncGenUART.HIGH] + FuncGenUART.int2arg(h))
        return h

    def set_low(self, l: float):
        l = abs(l) if abs(l) < 3.3 else 3.3
        l = int((l / 3.3) * 4095)
        self.send_instruction([FuncGenUART.LOW] + FuncGenUART.int2arg(l))
        return l

    def set_direction(self, d: int):
        self.send_instruction([FuncGenUART.DIRECTION] + FuncGenUART.int2arg(d))
        return d


if __name__ == "__main__":
    p = ["/dev/" + f for f in os.listdir("/dev/") if "ttyUSB" in f]
    fgu = FuncGenUART(port=p[0])
    a = 1
