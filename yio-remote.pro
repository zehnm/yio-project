TEMPLATE = subdirs
SUBDIRS += remote-software/remote.pro \
    integration.ir/ir.pro \
    integration.home-assistant/homeassistant.pro \
    integration.homey/homey.pro

remote-software/remote.pro.depends = integration.ir/ir.pro integration.home-assistant/homeassistant.pro integration.homey/homey.pro
