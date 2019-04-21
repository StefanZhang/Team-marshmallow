Official Documentation for WhereTo?

WhereTo is an iOS application that utilizes Apple's ARKit library and the PlaceNoteSDK. The parts of the application include the user mode and the Admin mode.

The Admin does the bulk of the work for the application while the user side is meant to follow the instructions that the Admin has layed out.

User Mode:
The file for the user can be found in the ______.swift file. What the user does is select a destination in the ViewControllerWT.swift then _______

Backend: 
Step 1: In ViewControllerWT.swift, after a user has selected a destination, the name of the map which contains this destination as well as the coordinate of the destination (type SCNVector3), will be passed to ViewControllerWAY.swift.

Step 2: In ViewControllerWAY.swift, after a user has selected a initial location, the name of the map which contains this initial location as well as the coordinate of the initial location (type SCNVector3), will be passed to ViewControllerUM.swift, together with the desitination information mentioned in Step 1.


Admin Mode:
The file for the admin can be found in the ViewController.swift file. What the admin does is ______
