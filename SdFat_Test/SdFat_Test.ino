#include <SdFat.h>

const int chipSelect = 4;    // SD card CS pin
const int DELAY_TIME = 5000; // 5 seconds
const int BUFFER_SIZE = 512;

SdFat SD;

void setup()
{
    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, LOW); // Turn off built-in LED

    delay(DELAY_TIME); // Initial 5s delay

    // Initialize SD card
    SD.begin(chipSelect);
    delay(DELAY_TIME); // 5s delay after init

    // Create and write to test file
    FsFile testFile = SD.open("test.txt", FILE_WRITE);
    if (testFile)
    {
        uint8_t buffer[BUFFER_SIZE];
        memset(buffer, 0xFF, BUFFER_SIZE); // Fill buffer with 0xFF
        testFile.write(buffer, BUFFER_SIZE);
        testFile.close();
    }
    delay(DELAY_TIME); // 5s delay after write

    // End SD card operations
    SD.end();

    // Enter infinite loop
    while (1)
    {
        // Do nothing forever
    }
}

void loop()
{
    // Never reached
}