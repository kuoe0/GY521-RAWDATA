/*
 * =============================================================================
 *   FileName: processing-raw-plot.pde
 *       Desc: Processing code for plot GY-80 raw data
 *     Author: KuoE0
 *      Email: kuoe0.tw@gmail.com
 *   HomePage: http://blog.kuoe0.tw/
 *=============================================================================
 */

import processing.serial.*;

class Button {
	public int x, y, width_radius, height_radius;
	public Button(int _x, int _y, int _w, int _h) {
		this.x = _x;
		this.y = _y;
		this.width_radius = _w;
		this.height_radius = _h;
	}
	public boolean isInside(int _x, int _y) {
		return _x >= this.x - this.width_radius && _x <= this.x + this.width_radius && _y >= this.y - this.height_radius && _y <= this.y + this.height_radius;
	}
	int getLeftTopX() { return this.x - this.width_radius; }
	int getLeftTopY() { return this.y - this.height_radius; }
	int getRightBottomX() { return this.x + this.width_radius; }
	int getRightBottomY() { return this.y + this.height_radius; }
};

Serial myPort;
final int MAX_SAMPLE = 400;

int update_ptr = MAX_SAMPLE;
float[] accel_x = new float[MAX_SAMPLE];
float[] accel_y = new float[MAX_SAMPLE];
float[] accel_z = new float[MAX_SAMPLE];
float[] gyro_x = new float[MAX_SAMPLE];
float[] gyro_y = new float[MAX_SAMPLE];
float[] gyro_z = new float[MAX_SAMPLE];

int record_sec = 0, record_timer_begin = 0, record_timer_now = 0;
boolean record_stat = false;

String received_data;
String[] data_list;

int WINDOW_WIDTH = 800, WINDOW_HEIGHT = 600;
int WINDOW_PADDING = 20;
int COLUMN_WIDHT_1 = 480, COLUMN_WIDHT_2 = 260;
int CHART_CARD_HEIGHT = WINDOW_HEIGHT - WINDOW_PADDING * 2, RECORDER_CARD_HEIGHT = 130;
int CHART_INTERVAL = 50, CHART_WIDTH = MAX_SAMPLE, CHART_HEIGHT = CHART_INTERVAL * 8;
color CLR_ACCEL_X = #FF5722, CLR_ACCEL_Y = #259B24, CLR_ACCEL_Z = #03A9F4;
color CLR_GYRO_X = #E51C23, CLR_GYRO_Y = #5677FC, CLR_GYRO_Z = #009688;

PFont helveticaLight, helveticaMedium, helveticaUltraLight;
PGraphics pg_chart, pg_legend, pg_recorder;
PrintWriter file_output;
Button btn_recorder_add, btn_recorder_sub, btn_recorder_reset, btn_recorder_action;

void setup() {

	size(WINDOW_WIDTH, WINDOW_HEIGHT); // init window size

	int port_idx = get_arduino_dev();

	if (port_idx != -1) {
		String portName = Serial.list()[port_idx];
		myPort = new Serial(this, portName, 115200);
		myPort.clear();
		myPort.bufferUntil('\n');
	}

	helveticaUltraLight = createFont("HelveticaNeue-Ultralight", 22, true);
	helveticaLight = createFont("HelveticaNeue-Light", 22, true);
	helveticaMedium = createFont("HelveticaNeue-Medium", 22, true);
	textFont(helveticaLight);

	for (int i = 0; i < MAX_SAMPLE; ++i) {
		accel_x[i] = accel_y[i] = accel_z[i] = 0;
	}
}

void draw() {
	background(225);

	// recorder is on
	if (record_stat) {
		// record current time
		record_timer_now = millis();
		// timer is end
		if (record_sec - int((record_timer_now - record_timer_begin) / 1000) == 0) {
			record_stat = false;
			stop_record();
		}
	}

	draw_chart();
	draw_recorder();

}

// search for the Arduino device
int get_arduino_dev() {

	println(Serial.list());
	for (int i = 0; i < Serial.list().length; ++i) {
		// find name Arduino device
		String[] ret = match(Serial.list()[i], "tty.usbmodem");
		if (ret != null) {
			println("Found " + Serial.list()[i] + "!");
			return i;
		}
	}
	return -1;
}

void card(int x, int y, int width, int height) {

	int x1 = x, y1 = y, x2 = x + width, y2 = y + height;

	// card
	noStroke();
	fill(255);
	rectMode(CORNERS);
	rect(x1, y1, x2, y2);

	// right-bottom shadow
	stroke(200);
	line(x2 + 1, y1, x2 + 1, y2);
	line(x1, y2 + 1, x2, y2 + 1);

	// border shadow
	stroke(220);
	line(x1, y1 - 1, x2, y1 - 1);
	line(x1 - 1, y1, x1 - 1, y2);
	line(x2 + 2, y1, x2 + 2, y2);
	line(x1, y2 + 2, x2, y2 + 2);

}

void draw_chart() {

	// draw card
	card(WINDOW_PADDING, WINDOW_PADDING, COLUMN_WIDHT_1, CHART_CARD_HEIGHT);

	// draw unit
	fill(32);
	textSize(16);
	textAlign(RIGHT, CENTER);
	text(str(0), WINDOW_PADDING * 3.5, WINDOW_PADDING * 2.5 + CHART_HEIGHT / 2);
	for (int i = 1; i <= 4; ++i) {
		text(str(8192 * i), WINDOW_PADDING * 3.5 + 5, WINDOW_PADDING * 2.5 + CHART_HEIGHT / 2 - CHART_INTERVAL * i);
		text(str(-8192 * i), WINDOW_PADDING * 3.5 + 5, WINDOW_PADDING * 2.5 + CHART_HEIGHT / 2 + CHART_INTERVAL * i);
	}

	// draw chart
	pg_chart = createGraphics(CHART_WIDTH, CHART_HEIGHT + 1);
	pg_chart.beginDraw();
	pg_chart.background(255);
	pg_chart.translate(0, CHART_HEIGHT / 2);

	pg_chart.stroke(225);
	pg_chart.line(0, 0, CHART_WIDTH, 0);
	for (int i = 1; i <= 4; ++i) {
		pg_chart.line(0, CHART_INTERVAL * i, CHART_WIDTH, CHART_INTERVAL * i);
		pg_chart.line(0, -CHART_INTERVAL * i, CHART_WIDTH, -CHART_INTERVAL * i);
	}

	for (int i = 0; i < MAX_SAMPLE / 2 - 1; ++i) {
		int p1 = (i + update_ptr - MAX_SAMPLE / 2 + MAX_SAMPLE) % MAX_SAMPLE;
		int p2 = (i + update_ptr - MAX_SAMPLE / 2 + 1 + MAX_SAMPLE) % MAX_SAMPLE;
		
		// x-axis acceleration
		pg_chart.stroke(CLR_ACCEL_X);
		pg_chart.line(i * 2, -accel_x[p1] * 50 / 8192, i * 2 + 1, -accel_x[p2] * 50 / 8192);
		// y-axis acceleration
		pg_chart.stroke(CLR_ACCEL_Y);
		pg_chart.line(i * 2, -accel_y[p1] * 50 / 8192, i * 2 + 1, -accel_y[p2] * 50 / 8192);
		// z-axis acceleration
		pg_chart.stroke(CLR_ACCEL_Z);
		pg_chart.line(i * 2, -accel_z[p1] * 50 / 8192, i * 2 + 1, -accel_z[p2] * 50 / 8192);

		// x-axis acceleration
		pg_chart.stroke(CLR_GYRO_X);
		pg_chart.line(i * 2, -gyro_x[p1] * 50 / 8192, i * 2 + 1, -gyro_x[p2] * 50 / 8192);
		// y-axis angular velocity
		pg_chart.stroke(CLR_GYRO_Y);
		pg_chart.line(i * 2, -gyro_y[p1] * 50 / 8192, i * 2 + 1, -gyro_y[p2] * 50 / 8192);
		// z-axis angular velocity
		pg_chart.stroke(CLR_GYRO_Z);
		pg_chart.line(i * 2, -gyro_z[p1] * 50 / 8192, i * 2 + 1, -gyro_z[p2] * 50 / 8192);
	}

	pg_chart.endDraw();

	// put chart
	image(pg_chart, WINDOW_PADDING * 4, WINDOW_PADDING * 2.5);

	pg_legend = createGraphics(440, 100);
	pg_legend.beginDraw();
	pg_legend.background(255);
	pg_legend.translate(pg_legend.width / 2, pg_legend.height / 2);

	pg_legend.rectMode(CORNERS);
	pg_legend.noStroke();
	pg_legend.textAlign(LEFT, CENTER);

	// acceleromter
	pg_legend.fill(CLR_ACCEL_X);
	pg_legend.rect(-5 - 30 - 140, -25, 5 - 30 - 140, -35);
	pg_legend.text("ACCEL_X", -20 - 140, -30 - 2);

	pg_legend.fill(CLR_ACCEL_Y);
	pg_legend.rect(-5 - 30 - 140, 5, 5 - 30 - 140, -5);
	pg_legend.text("ACCEL_Y", -20 - 140, 0 - 2);

	pg_legend.fill(CLR_ACCEL_Z);
	pg_legend.rect(-5 - 30 - 140, 35, 5 - 30 - 140, 25);
	pg_legend.text("ACCEL_Z", -20 - 140, 30 - 2);

	// gyroscope
	pg_legend.fill(CLR_GYRO_X);
	pg_legend.rect(-5 - 30, -25, 5 - 30, -35);
	pg_legend.text("GYRO_X", -20, -30 - 2);

	pg_legend.fill(CLR_GYRO_Y);
	pg_legend.rect(-5 - 30, 5, 5 - 30, -5);
	pg_legend.text("GYRO_Y", -20, 0 - 2);

	pg_legend.fill(CLR_GYRO_Z);
	pg_legend.rect(-5 - 30, 35, 5 - 30, 25);
	pg_legend.text("GYRO_Z", -20, 30 - 2);

	pg_legend.endDraw();

	// put legend
	image(pg_legend, WINDOW_PADDING * 2, WINDOW_PADDING * 3.5 + CHART_HEIGHT);

}

void draw_recorder() {
	card(WINDOW_PADDING * 2 + COLUMN_WIDHT_1, WINDOW_PADDING, COLUMN_WIDHT_2, RECORDER_CARD_HEIGHT);

	pg_recorder = createGraphics(COLUMN_WIDHT_2, RECORDER_CARD_HEIGHT);

	pg_recorder.beginDraw();
	pg_recorder.background(255);

	// title
	pg_recorder.fill(33);
	pg_recorder.textSize(20);
	pg_recorder.textAlign(LEFT, TOP);
	pg_recorder.textFont(helveticaLight);
	pg_recorder.text("Recorder", WINDOW_PADDING, WINDOW_PADDING);

	// buttons
	int BTN_WIDTH = 65;
	pg_recorder.rectMode(CORNERS);
	pg_recorder.noStroke();
	pg_recorder.textFont(helveticaMedium);
	pg_recorder.textSize(14);
	pg_recorder.textAlign(CENTER, CENTER);

	// + button
	pg_recorder.noFill();
	pg_recorder.rect(0, pg_recorder.height - 30, BTN_WIDTH, pg_recorder.height);
	pg_recorder.fill(33);
	pg_recorder.text("+", BTN_WIDTH * 0.5, pg_recorder.height - 15);
	btn_recorder_add = new Button(int(WINDOW_PADDING * 2 + COLUMN_WIDHT_1 + BTN_WIDTH * 0.5), WINDOW_PADDING + pg_recorder.height - 15, int(BTN_WIDTH * 0.5), 15);

	// - button
	pg_recorder.noFill();
	pg_recorder.rect(BTN_WIDTH, pg_recorder.height - 30, BTN_WIDTH * 2, pg_recorder.height);
	pg_recorder.fill(33);
	pg_recorder.text("-", BTN_WIDTH * 1.5, pg_recorder.height - 15);
	btn_recorder_sub = new Button(int(WINDOW_PADDING * 2 + COLUMN_WIDHT_1 + BTN_WIDTH * 1.5), WINDOW_PADDING + pg_recorder.height - 15, int(BTN_WIDTH * 0.5), 15);

	// reset button
	pg_recorder.noFill();
	pg_recorder.rect(BTN_WIDTH * 2, pg_recorder.height - 30, BTN_WIDTH * 3, pg_recorder.height);
	pg_recorder.fill(33);
	pg_recorder.text("RESET", BTN_WIDTH * 2.5, pg_recorder.height - 15);
	btn_recorder_reset = new Button(int(WINDOW_PADDING * 2 + COLUMN_WIDHT_1 + BTN_WIDTH * 2.5), WINDOW_PADDING + pg_recorder.height - 15, int(BTN_WIDTH * 0.5), 15);

	// start button
	pg_recorder.noFill();
	pg_recorder.rect(BTN_WIDTH * 3, pg_recorder.height - 30, BTN_WIDTH * 4, pg_recorder.height);
	pg_recorder.fill(#FF9800);
	pg_recorder.text(record_stat ? "STOP" : "START", BTN_WIDTH * 3.5, pg_recorder.height - 15);
	btn_recorder_action = new Button(int(WINDOW_PADDING * 2 + COLUMN_WIDHT_1 + BTN_WIDTH * 3.5), WINDOW_PADDING + pg_recorder.height - 15, int(BTN_WIDTH * 0.5), 15);

	// underline
	pg_recorder.stroke(#03A9F4);
	pg_recorder.line(WINDOW_PADDING, pg_recorder.height - 38, pg_recorder.width / 2, pg_recorder.height - 38);
	pg_recorder.line(WINDOW_PADDING, pg_recorder.height - 39, pg_recorder.width / 2, pg_recorder.height - 39);
	pg_recorder.line(WINDOW_PADDING, pg_recorder.height - 40, pg_recorder.width / 2, pg_recorder.height - 40);
	// record time
	pg_recorder.textFont(helveticaUltraLight);
	pg_recorder.fill(117);
	pg_recorder.textSize(40);
	pg_recorder.textAlign(RIGHT, BOTTOM);
	pg_recorder.text(str(record_sec - int((record_timer_now - record_timer_begin) / 1000)), pg_recorder.width / 2, pg_recorder.height - 40);

	// second hint text
	pg_recorder.fill(188);
	pg_recorder.textSize(16);
	pg_recorder.textFont(helveticaLight);
	pg_recorder.textAlign(LEFT, BOTTOM);
	pg_recorder.text("second", pg_recorder.width / 2 + WINDOW_PADDING, pg_recorder.height - 40);

	pg_recorder.endDraw();
	// put on card
	image(pg_recorder, WINDOW_PADDING * 2 + COLUMN_WIDHT_1, WINDOW_PADDING);

}

// generate random sample
void gen_random_sample() {

	float x = random(-100, 100);
	float y = random(200, 300);
	float z = random(-300, -200);

	if (update_ptr >= MAX_SAMPLE)
		update_ptr = 0;

	accel_x[update_ptr] = x;
	accel_y[update_ptr] = y;
	accel_z[update_ptr] = z;

	++update_ptr;

}

void serialEvent(Serial p) {

	try {
		received_data = myPort.readStringUntil('\n');
		received_data = trim(received_data);
	}
	catch (Exception e) {
		println("READ FROM SERIAL");
		println("Caught Exception");
		println(e.toString());
	}

	try {
		if (received_data != null) {

			data_list = split(received_data, ':');

			if (data_list.length == 6) {

				float ax = float(trim(data_list[0]));
				float ay = float(trim(data_list[1]));
				float az = float(trim(data_list[2]));
				float gx = float(trim(data_list[3]));
				float gy = float(trim(data_list[4]));
				float gz = float(trim(data_list[5]));

				// record data to file
				if (record_stat) {
					file_output.println(join(data_list, ','));
				}

				if (update_ptr >= MAX_SAMPLE)
					update_ptr = 0;

				accel_x[update_ptr] = ax;
				accel_y[update_ptr] = ay;
				accel_z[update_ptr] = az;
				gyro_x[update_ptr] = gx;
				gyro_y[update_ptr] = gy;
				gyro_z[update_ptr] = gz;

				++update_ptr;
			}
		}
	}
	catch (Exception e) {
		println("Caught Exception");
		println(e.toString());
	}
}

void mousePressed() {
	if (btn_recorder_add.isInside(mouseX, mouseY)) {
		record_sec += 5;
		return;
	}
	if (btn_recorder_sub.isInside(mouseX, mouseY)) {
		if (record_sec > 0) record_sec -= 5;
		return;
	}
	if (btn_recorder_reset.isInside(mouseX, mouseY)) {
		record_sec = 0;
		return;
	}
	if (btn_recorder_action.isInside(mouseX, mouseY)) {
		if (record_sec > 0) {
			record_stat = !record_stat;
			if (record_stat) start_record();
			else stop_record();
		}
		return;
	}
}

String two_digit(int x) {
	return x < 10 ? str(0) + str(x) : str(x);
}
// start to record data
void start_record() {
	// open new file and name it to current datetime
	file_output = createWriter(two_digit(year()) + two_digit(month()) + two_digit(day()) + "-" + two_digit(hour()) + two_digit(minute()) + two_digit(second()) + ".csv");
	record_timer_begin = millis();
}
// stop to record data
void stop_record() {
	// close file
	file_output.flush();
	file_output.close();
	// reset timer
	record_sec = record_timer_now = record_timer_begin = 0;
}
