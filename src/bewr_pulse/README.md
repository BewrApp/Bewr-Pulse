# Bewr Pulse

## Algorithm
1. Define the following variables:
- threshold: the intensity threshold at which a vibration should be triggered
- amplitudeMax: the maximum amplitude of the vibration
- amplitudeMin: the minimum amplitude of the vibration
- currentIntensity: the current intensity of the audio signal
- previousIntensity: the previous intensity of the audio signal
- counter: a counter to track the number of updates performed

2. Initialize the variables:
- Set threshold to an appropriate value
- Set amplitudeMax to the desired maximum amplitude for the vibration
- Set amplitudeMin to the desired minimum amplitude for the vibration
- Set currentIntensity to null
- Set previousIntensity to null
- Set counter to 0

3. Repeat the following steps in a loop:
- Read the intensity of the audio signal and store it in currentIntensity
- If previousIntensity is not null:
- If currentIntensity is greater than the threshold:
- Calculate the amplitude based on the current intensity, using the formula: amplitude = (1 - currentIntensity)^2 * (amplitudeMax - amplitudeMin) + amplitudeMin
- Trigger a vibration with a duration of 50 milliseconds and an amplitude equal to amplitude
- Update previousIntensity with the value of currentIntensity
- Increment counter by 1
- If counter reaches a certain threshold (e.g., 1000 updates):
- Reset previousIntensity to null
- Reset counter to 0

## Algorithm code
```
ALGORITHM detectIntensityPulses
    // Declare variables
    DECLARE threshold, amplitudeMax, amplitudeMin, currentIntensity, previousIntensity, counter

    // Initialize variables
    SET threshold TO <threshold_value>
    SET amplitudeMax TO <max_amplitude_value>
    SET amplitudeMin TO <min_amplitude_value>
    SET currentIntensity TO null
    SET previousIntensity TO null
    SET counter TO 0

    // Main loop
    WHILE true DO
        // Read the intensity of the audio signal
        SET currentIntensity TO readAudioIntensity()

        // Check previous intensity
        IF previousIntensity != null THEN
            // Detect intensity pulse
            IF currentIntensity > threshold THEN
                // Calculate amplitude based on current intensity
                SET amplitude TO (1 - currentIntensity)^2 * (amplitudeMax - amplitudeMin) + amplitudeMin

                // Trigger vibration
                triggerVibration(50, amplitude)
            END IF
        END IF

        // Update previous intensity
        SET previousIntensity TO currentIntensity

        // Increment counter
        SET counter TO counter + 1

        // Reset if counter reaches a threshold
        IF counter >= 1000 THEN
            SET previousIntensity TO null
            SET counter TO 0
        END IF
    END WHILE
END ALGORITHM
```
