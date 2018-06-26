This is a repository attempting to reproduce the bad recording when trying to record the mix from both the built-in microphone and a playing audio stream to the same output file. This has been reproduced on an iphone 6s, but it's possible (probably?) that any ios device later than that (with siri) may demonstrate the same problem. The initial guess is that having siri locks the mic to a 48k stream, while audiokit (or the lower layer) expects 44.1k, so there is a mismatch.

1) Click "Record" to start the recording
2) Click "Cart Off" button to start the cart
3) Click "Mic Off" button to start the mic (do NOT have an external mic plugged in)
4) Speak a little bit
5) Click the "Recording" button to stop the recording

Now, you can play it on the phone, or get the `test.caf` file from the itunes interface. Click on the device, then `File Sharing` to see the app, and you should be able to save the file to your desktop.

There is also an example (called `scratchy_mic.caf`) example file in this repo's root.
