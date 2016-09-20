"""
RigControl - A simple interface to control AutoHat device testing rig.
"""
from pylibftdi.util import Bus
from pylibftdi import BitBangDevice


class RigControl(object):
    """Simple class to provide direct access to FTDI GPIOs on the rig
       Everything is active towards the Device Under Test (DUT) when LOW.
    """
    sd_select = Bus(0)  # DUT connected to sdcard on LOW
    usb_select = Bus(3)  # USB on DUT side connected on LOW
    power_select = Bus(4)  # DUT Powered on when LOW
    d0 = Bus(0)
    d1 = Bus(1)
    d2 = Bus(2)
    d3 = Bus(3)
    d4 = Bus(4)
    d5 = Bus(5)
    d6 = Bus(6)
    d7 = Bus(7)
    __version__ = '0.1'

    def __init__(self, **kwargs):
        self.device = BitBangDevice(**kwargs)  # All pins as OUTPUT

    def select_rig(self, **kwargs):
        self.device = BitBangDevice(**kwargs)  # Selects the FTDI device

    def enable_dut(self):
        """ Connects the HOST to the USB located towards DUT
            Connects SD card to Device Under Test (DUT)
            Powers ON the DUT
        """
        self.usb_select = 0
        self.sd_select = 0
        self.power_select = 0

    def disable_dut(self):
        """ Powers OFF the DUT
            Connects SD card to the HOST
            Connects the HOST to the USB located away from DUT
            (SDcard reader present on this USB)
        """
        self.power_select = 1
        self.sd_select = 1
        self.usb_select = 1
