# Bewr Pulse

## Vibration algorithm

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
    - If previousIntensity is null:
        - Update previousIntensity with the value of currentIntensity
        - Continue to the next iteration of the loop
    - If previousIntensity is not null:
        - If currentIntensity is greater than the threshold:
            - Calculate the amplitude based on the current intensity, using the formula: amplitude = (1 - currentIntensity)^2 * (amplitudeMax - amplitudeMin) + amplitudeMin
            - Trigger a vibration with a duration of 50 milliseconds and an amplitude equal to amplitude
        - Update previousIntensity with the value of currentIntensity
    - Increment counter by 1
    - If counter reaches a certain threshold (e.g., 1000 updates):
        - Reset previousIntensity to null
        - Reset counter to 0

## Vibration algorithm code

```text
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
        /**
            * FUNCTION readAudioIntensity
            *
            * Description:
            *  Reads the current intensity of the audio signal from a predetermined source, typically a microphone or audio input stream.
            *
            * Returns:
            *  FLOAT - A value between 0.0 and 1.0 representing the current intensity or amplitude of the audio signal. 
            *          0.0 indicates silence, while 1.0 indicates the loudest possible intensity for the given input.
            *
            * Dependencies:
            *  Assumes that an audio source (e.g., microphone) is initialized and is capturing audio data.
            *
            * Notes:
            *  The exact method of calculating intensity might vary based on the specifics of the audio input and the desired granularity.
            *  Error handling, such as what to do if no audio source is available, should be handled either inside this function or in the calling function.
        */


        // If it's the first iteration or counter reset
        IF previousIntensity = null THEN
            SET previousIntensity TO currentIntensity
            CONTINUE   // Skip the rest of the loop and move to the next iteration
        END IF

        // Detect intensity pulse
        IF currentIntensity > threshold THEN
            // Calculate amplitude based on current intensity
            SET amplitude TO (1 - currentIntensity)^2 * (amplitudeMax - amplitudeMin) + amplitudeMin

            // Trigger vibration
            triggerVibration(50, amplitude)
            /**
                * FUNCTION triggerVibration
                *
                * Parameters:
                *  duration (INTEGER) - The duration of the vibration in milliseconds.
                *  amplitude (FLOAT) - The amplitude of the vibration, typically a value between 0.0 (no vibration) and 1.0 (maximum vibration). 
                *
                * Description:
                *  Triggers a vibration using the specified duration and amplitude. This function interfaces with a vibration motor or haptic feedback device.
                *
                * Returns:
                *  VOID - This function typically does not return any value but executes the vibration command.
                *
                * Dependencies:
                *  Assumes that a vibration motor or haptic feedback device is available and initialized.
                *
                * Notes:
                *  The exact method of triggering the vibration will vary based on the specifics of the haptic device used.
                *  Error handling, such as what to do if no haptic device is available, should be handled either inside this function or in the calling function.
            */

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

## Capture sound waves algorithm

1. Initialize the microphone and set the desired sample rate and bit depth.
2. Create a circular buffer of the desired size to store the audio samples.
3. Start recording audio from the microphone.
4. Continuously:
   a. Read a specified number of audio samples or for a specified duration from the microphone.
   b. Store these samples in the circular buffer.
5. As samples are collected, process them as needed (e.g., perform analysis, apply filters, etc.).
6. Repeat steps 4 and 5 until a desired stop condition is met.
7. Stop recording audio from the microphone.
8. Process the stored sound waves in the buffer as desired (e.g., save to a file, analyze further, etc.).

## Capture sound waves algorithm code

```text
ALGORITHM captureSoundWaves
    // Initialize the microphone
    INITIALIZE microphone WITH desired sample rate and bit depth

    // Create an empty buffer
    CREATE buffer OF SIZE <desired_buffer_size> [AS CIRCULAR]

    // Start recording audio
    START recording audio

    // Capture sound waves
    REPEAT UNTIL desired stop condition
        // Read audio samples from the microphone
        READ <number_of_samples> audio samples FROM microphone OR READ audio samples FOR <specified_duration> FROM microphone

        // Append audio samples to the buffer
        APPEND audio samples TO buffer
    END REPEAT

    // Stop recording audio
    STOP recording audio

    // Process captured sound waves
    ANALYZE frequencies OF captured sound waves
    FILTER noise FROM captured sound waves
    [Any other processing steps]
END ALGORITHM
```
