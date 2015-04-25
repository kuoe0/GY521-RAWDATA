/*============================================================================
 *    FileName: arduino-raw-tx.ino
 *        Desc: Arduino with GY-521 transmitter
 *      Author: KuoE0
 *       Email: kuoe0.tw@gmail.com
 *    HomePage: http://kuoe0.tw/
 *============================================================================*/

#include <I2Cdev.h>
#include <MPU6050.h>
#include <Timer.h>

#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
#include "Wire.h"
#endif

MPU6050 imu;

int ax, ay, az, gx, gy, gz;
Timer tcb;

void setup() {
	Serial.begin(115200);

	// join I2C bus (I2Cdev library doesn't do this automatically)
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
	Wire.begin();
#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
	Fastwire::setup(400, true);
#endif

	imu.initialize();
	Serial.println("Initialize MPU6050...");
	if (!imu.testConnection()) {
		Serial.println("Initialize MPU6050 failed...");
		delay(1000);
	}
	imu.setRate(3); // 1kHz / (1 + 3) = 250 Hz
	tcb.every(4, updateSample);
}

void loop() {
	tcb.update();
}

void updateSample() {
	imu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

	Serial.print(ax);
	Serial.print(":");
	Serial.print(ay);
	Serial.print(":");
	Serial.print(az);
	Serial.print(":");
	Serial.print(gx);
	Serial.print(":");
	Serial.print(gy);
	Serial.print(":");
	Serial.println(gz);
}

