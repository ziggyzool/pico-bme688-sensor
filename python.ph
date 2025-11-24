import bme680
import time
import smbus  # Importing the module to access I2C bus

print("""read-all.py - Displays temperature, pressure, humidity, and gas.

Press Ctrl+C to exit!

""")

# Function to initialize the sensor on a specified I2C bus
def initialize_sensor(bus_number, sensor_address):
    try:
        bus = smbus.SMBus(bus_number)
        sensor = bme680.BME680(sensor_address, bus)
        print(f"Sensor initialized on I2C bus {bus_number} at address {sensor_address:#04x}")
        return sensor
    except (RuntimeError, IOError):
        print(f"Failed to find BME680 sensor on I2C bus {bus_number}.")
        return None  # Return None if initialization fails

# Set the I2C address for the BME680 sensor
sensor_address = 0x77  # The I2C address for the BME680 sensor

# List to hold initialized sensors
sensors = []

# Attempt to initialize the sensor on a range of I2C bus numbers
for bus_number in range(0, 16):  # Iterate through buses 0 to 15
    sensor = initialize_sensor(bus_number, sensor_address)
    if sensor is not None:
        sensors.append(sensor)

# Check if any sensors were found
if not sensors:
    print("No sensors found; exiting.")
else:
    # Calibration data (can be commented out if not needed)
    for sensor in sensors:
        print('Calibration data for sensor:')
        for name in dir(sensor.calibration_data):
            if not name.startswith('_'):
                value = getattr(sensor.calibration_data, name)
                if isinstance(value, int):
                    print(f'{name}: {value}')

        # Oversampling settings for various parameters
        sensor.set_humidity_oversample(bme680.OS_2X)
        sensor.set_pressure_oversample(bme680.OS_4X)
        sensor.set_temperature_oversample(bme680.OS_8X)
        sensor.set_filter(bme680.FILTER_SIZE_3)
        sensor.set_gas_status(bme680.ENABLE_GAS_MEAS)

        print('\n\nInitial reading for sensor:')
        for name in dir(sensor.data):
            value = getattr(sensor.data, name)
            if not name.startswith('_'):
                print(f'{name}: {value}')

        sensor.set_gas_heater_temperature(320)
        sensor.set_gas_heater_duration(150)
        sensor.select_gas_heater_profile(0)

    print('\n\nPolling:')
    try:
        while True:
            for sensor in sensors:
                if sensor.get_sensor_data():
                    output = '{0:.2f} C, {1:.2f} hPa, {2:.2f} %RH'.format(
                        sensor.data.temperature,
                        sensor.data.pressure,
                        sensor.data.humidity)

                    if sensor.data.heat_stable:
                        print('{0}, {1} Ohms'.format(
                            output,
                            sensor.data.gas_resistance))
                    else:
                        print(output)

            time.sleep(30)

    except KeyboardInterrupt:
        pass
