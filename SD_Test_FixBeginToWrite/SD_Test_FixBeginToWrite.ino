#include <SD.h>

// ESP32-specific configurations
#if defined(ESP32)
const int chipSelect = A0;          // ESP32 SD card CS pin
const char *filename = "/test.txt"; // ESP32 requires leading slash
#else
const int chipSelect = 4;          // Standard Arduino SD card CS pin
const char *filename = "test.txt"; // Standard filename
#endif

const int DELAY_TIME = 5000; // 5 seconds
const int BUFFER_SIZE = 512;

void setup()
{
    // Initialize serial communication
    Serial.begin(9600);
    delay(1000);
    Serial.println("SD Card Power Test Starting...");

    pinMode(LED_BUILTIN, OUTPUT);
    digitalWrite(LED_BUILTIN, LOW); // Turn off built-in LED
    Serial.println("LED turned off");

    delay(DELAY_TIME); // Initial 5s delay
    Serial.println("Initial delay complete");

    // Initialize SD card
    Serial.print("Initializing SD card...");
    if (SD.begin(chipSelect))
    {
        Serial.println("initialization successful!");
    }
    else
    {
        Serial.println("initialization failed!");
        while (1)
            ; // Stop if failed
    }
    // delay(DELAY_TIME); // 5s delay after init
    Serial.println("Post-init delay complete");

    // !! SD is still in high power mode in most cases until write is complete !!

    // Check if non-existent file exists to reduce power consumption
    Serial.println("\nTest: Checking non-existent file...");
#if defined(ESP32)
    SD.exists("/x.txt"); // ESP32 requires leading slash
#else
    SD.exists("x.txt"); // Standard path without leading slash
#endif
    delay(DELAY_TIME);
    Serial.println("Test delay complete");

    // Test opening and closing root directory
    Serial.println("\nTest: Opening root directory...");
#if defined(ESP32)
    File root = SD.open("/"); // ESP32 requires leading slash
#else
    File root = SD.open("/"); // Standard root path
#endif
    if (root)
    {
        Serial.println("Root directory opened successfully");
        root.close();
        Serial.println("Root directory closed");
    }
    else
    {
        Serial.println("Failed to open root directory");
    }
    delay(DELAY_TIME);
    Serial.println("Test delay complete");

    // Create and write to test file
    Serial.print("Opening file for writing...");
    Serial.println(filename);
    File testFile = SD.open(filename, FILE_WRITE);
    if (testFile)
    {
        Serial.println("success!");
        uint8_t buffer[BUFFER_SIZE];
        memset(buffer, 0xFF, BUFFER_SIZE); // Fill buffer with 0xFF

        Serial.print("Writing 512 bytes...");
        size_t bytesWritten = testFile.write(buffer, BUFFER_SIZE);
        Serial.print("wrote ");
        Serial.print(bytesWritten);
        Serial.println(" bytes");

        Serial.print("Closing file...");
        testFile.close();
        Serial.println("done!");
    }
    else
    {
        Serial.println("error opening file!");
    }
    delay(DELAY_TIME); // 5s delay after write
    Serial.println("Post-write delay complete");

    // End SD card operations
    Serial.print("Calling SD.end()...");
    SD.end();
    Serial.println("done!");

    Serial.println("Entering infinite loop...");
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