"""
RigControl - A simple interface to control AutoHat device testing rig.
"""
from pylibftdi import BitBangDevice


class RigControl(object):
    """Simple class to provide direct access to FTDI GPIOs on the rig
       Everything is active towards the Device Under Test (DUT) when LOW.
    """

    sd_select = 0  # DUT connected to sdcard on LOW
    patch_select = 1 # Workaround for patched SD power
    usb_select = 3  # USB on DUT side connected on LOW
    power_select = 4  # DUT Powered on when LOW

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
        self.clear_pin(self.sd_select)
        self.clear_pin(self.usb_select)
        self.set_pin(self.patch_select)
        self.clear_pin(self.power_select)

    def disable_dut(self):
        """ Powers OFF the DUT
            Connects SD card to the HOST
            Connects the HOST to the USB located away from DUT
            (SDcard reader present on this USB)
        """
        self.set_pin(self.power_select)
        self.clear_pin(self.patch_select)
        self.set_pin(self.sd_select)
        self.set_pin(self.usb_select)

    def set_pin(self, pin):
        """ Sets the pin selected (High,5v)
        """
        self.device.port |= (1 << int(pin))

    def clear_pin(self, pin):
        """ Clears the pin selected (Low,0v)
        """
        self.device.port &= ~(1 << int(pin))

    def set_output(self, pin):
        """ Sets the pin selected as an output
        """
        self.device.direction |= (1 << int(pin))

    def set_input(self,pin):
        """ Sets the pin selected as an input
        """
        self.device.direction &= ~(1 << int(pin))
