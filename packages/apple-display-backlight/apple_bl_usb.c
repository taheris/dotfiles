// SPDX-License-Identifier: GPL-2.0
/*
 * Apple USB Backlight Driver for Studio Display and Pro Display XDR
 *
 * Based on Julius Zint's apple_bl_usb patch submitted to kernel mailing list.
 * Modified to support Pro Display XDR (USB ID 05ac:9243).
 *
 * Copyright (C) 2023 Julius Zint
 */

#include <linux/backlight.h>
#include <linux/hid.h>
#include <linux/module.h>
#include <linux/usb.h>

#define APPLE_VENDOR_ID          0x05ac
#define STUDIO_DISPLAY_ID        0x1114
#define PRO_DISPLAY_XDR_ID       0x9243

/* Brightness range for Pro Display XDR: 400-50000, so max adjustment is 49600 */
#define XDR_MAX_BRIGHTNESS       49600
#define XDR_MIN_BRIGHTNESS       400

/* HID report for brightness control */
#define BRIGHTNESS_REPORT_ID     0x01
#define BRIGHTNESS_REPORT_SIZE   7

struct apple_bl_data {
	struct hid_device *hdev;
	struct backlight_device *bl_dev;
	u16 max_brightness;
	u16 min_brightness;
};

static int apple_bl_get_brightness(struct apple_bl_data *data)
{
	u8 *buf;
	int ret;
	int brightness;

	buf = kzalloc(BRIGHTNESS_REPORT_SIZE, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	ret = hid_hw_raw_request(data->hdev, BRIGHTNESS_REPORT_ID, buf,
				 BRIGHTNESS_REPORT_SIZE, HID_FEATURE_REPORT,
				 HID_REQ_GET_REPORT);
	if (ret < 0) {
		hid_err(data->hdev, "Failed to get brightness: %d\n", ret);
		kfree(buf);
		return ret;
	}

	/* Brightness is stored as little-endian 16-bit at offset 1 */
	brightness = buf[1] | (buf[2] << 8);

	kfree(buf);

	/* Convert from hardware range to 0-max range */
	if (brightness < data->min_brightness)
		brightness = data->min_brightness;

	return brightness - data->min_brightness;
}

static int apple_bl_set_brightness(struct apple_bl_data *data, int brightness)
{
	u8 *buf;
	int ret;
	u16 hw_brightness;

	buf = kzalloc(BRIGHTNESS_REPORT_SIZE, GFP_KERNEL);
	if (!buf)
		return -ENOMEM;

	/* Convert from 0-max range to hardware range */
	hw_brightness = brightness + data->min_brightness;

	buf[0] = BRIGHTNESS_REPORT_ID;
	buf[1] = hw_brightness & 0xff;
	buf[2] = (hw_brightness >> 8) & 0xff;

	ret = hid_hw_raw_request(data->hdev, BRIGHTNESS_REPORT_ID, buf,
				 BRIGHTNESS_REPORT_SIZE, HID_FEATURE_REPORT,
				 HID_REQ_SET_REPORT);
	if (ret < 0)
		hid_err(data->hdev, "Failed to set brightness: %d\n", ret);

	kfree(buf);
	return ret < 0 ? ret : 0;
}

static int apple_bl_update_status(struct backlight_device *bl)
{
	struct apple_bl_data *data = bl_get_data(bl);

	return apple_bl_set_brightness(data, bl->props.brightness);
}

static int apple_bl_get_brightness_op(struct backlight_device *bl)
{
	struct apple_bl_data *data = bl_get_data(bl);

	return apple_bl_get_brightness(data);
}

static const struct backlight_ops apple_bl_ops = {
	.update_status = apple_bl_update_status,
	.get_brightness = apple_bl_get_brightness_op,
};

/* Get USB interface number from HID device */
static int apple_bl_get_interface_number(struct hid_device *hdev)
{
	struct usb_interface *intf;

	if (hdev->dev.parent == NULL)
		return -1;

	intf = to_usb_interface(hdev->dev.parent);
	return intf->cur_altsetting->desc.bInterfaceNumber;
}

static int apple_bl_probe(struct hid_device *hdev,
			  const struct hid_device_id *id)
{
	struct apple_bl_data *data;
	struct backlight_device *bl_dev;
	struct backlight_properties props;
	int ret;
	int ifnum;
	const char *bl_name;

	/*
	 * The Pro Display XDR has 5 HID interfaces. Interface 4 has malformed
	 * HID report descriptors with oversized report_size values that cause
	 * parsing errors. We claim it here to prevent hid-generic from trying
	 * to parse it and spamming the kernel log with warnings.
	 *
	 * Interface 2 is the one with brightness control.
	 */
	ifnum = apple_bl_get_interface_number(hdev);
	if (ifnum == 4) {
		hid_info(hdev, "Claiming interface %d to suppress HID parse errors\n", ifnum);
		return 0;
	}

	/* Only set up backlight on interface 2 */
	if (ifnum != 2)
		return -ENODEV;

	data = devm_kzalloc(&hdev->dev, sizeof(*data), GFP_KERNEL);
	if (!data)
		return -ENOMEM;

	data->hdev = hdev;

	/* Set device-specific parameters */
	switch (id->product) {
	case PRO_DISPLAY_XDR_ID:
		data->max_brightness = XDR_MAX_BRIGHTNESS;
		data->min_brightness = XDR_MIN_BRIGHTNESS;
		bl_name = "apple_xdr_display";
		break;
	case STUDIO_DISPLAY_ID:
	default:
		data->max_brightness = XDR_MAX_BRIGHTNESS;
		data->min_brightness = XDR_MIN_BRIGHTNESS;
		bl_name = "apple_studio_display";
		break;
	}

	ret = hid_parse(hdev);
	if (ret) {
		hid_err(hdev, "Failed to parse HID device: %d\n", ret);
		return ret;
	}

	ret = hid_hw_start(hdev, HID_CONNECT_HIDRAW);
	if (ret) {
		hid_err(hdev, "Failed to start HID device: %d\n", ret);
		return ret;
	}

	ret = hid_hw_open(hdev);
	if (ret) {
		hid_err(hdev, "Failed to open HID device: %d\n", ret);
		goto err_stop;
	}

	memset(&props, 0, sizeof(props));
	props.type = BACKLIGHT_RAW;
	props.max_brightness = data->max_brightness;

	bl_dev = backlight_device_register(bl_name, &hdev->dev, data,
					   &apple_bl_ops, &props);
	if (IS_ERR(bl_dev)) {
		ret = PTR_ERR(bl_dev);
		hid_err(hdev, "Failed to register backlight device: %d\n", ret);
		goto err_close;
	}

	data->bl_dev = bl_dev;
	hid_set_drvdata(hdev, data);

	/* Get initial brightness */
	bl_dev->props.brightness = apple_bl_get_brightness(data);
	if (bl_dev->props.brightness < 0)
		bl_dev->props.brightness = data->max_brightness / 2;

	hid_info(hdev, "Apple display backlight registered: %s (max: %d)\n",
		 bl_name, data->max_brightness);

	return 0;

err_close:
	hid_hw_close(hdev);
err_stop:
	hid_hw_stop(hdev);
	return ret;
}

static void apple_bl_remove(struct hid_device *hdev)
{
	struct apple_bl_data *data = hid_get_drvdata(hdev);

	/* Interface 4 was claimed but no resources allocated */
	if (!data)
		return;

	backlight_device_unregister(data->bl_dev);
	hid_hw_close(hdev);
	hid_hw_stop(hdev);
}

static const struct hid_device_id apple_bl_devices[] = {
	{ HID_USB_DEVICE(APPLE_VENDOR_ID, STUDIO_DISPLAY_ID) },
	{ HID_USB_DEVICE(APPLE_VENDOR_ID, PRO_DISPLAY_XDR_ID) },
	{ }
};
MODULE_DEVICE_TABLE(hid, apple_bl_devices);

static struct hid_driver apple_bl_driver = {
	.name = "apple_bl_usb",
	.id_table = apple_bl_devices,
	.probe = apple_bl_probe,
	.remove = apple_bl_remove,
};
module_hid_driver(apple_bl_driver);

MODULE_AUTHOR("Julius Zint");
MODULE_DESCRIPTION("Apple USB Display Backlight Driver");
MODULE_LICENSE("GPL");
