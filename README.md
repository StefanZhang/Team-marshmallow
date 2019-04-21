Official Documentation for WhereTo?

WhereTo is an iOS application that utilizes Apple's ARKit library and the PlaceNoteSDK. 
Placenote explaination can be found here: https://placenote.com/

This application is split into four parts: front-end, back-end, user mode, and admin mode. 

Front end:



User Mode:
The file for the user can be found in the ______.swift file. What the user does is select a destination in the ViewControllerWT.swift then _______

Backend: 
Step 1: In ViewControllerWT.swift, after a user has selected a destination, the name of the map which contains this destination as well as the coordinate of the destination (type SCNVector3), will be passed to ViewControllerWAY.swift.

Step 2: In ViewControllerWAY.swift, after a user has selected a initial location, the name of the map which contains this initial location as well as the coordinate of the initial location (type SCNVector3), will be passed to ViewControllerUM.swift, together with the desitination information mentioned in Step 1.


Admin Mode:
  The login of admin need to be click on the side bar menu, and then click the admin login. The front end side bar menu implementation is taking care by the class MenuLauncherWT, MenuCellWT and BaseCell. MenuLauncherWT as a launcher class gets called once the button being clicked in ViewControllerWT, the reason we create a seperate class for this is to reduce the code in the ViewcontrollerWT, and indeed solve the "Fat ViewController" issue, and easier to debug in case something went wrong. In MenuLauncherWT, ShowMenu() display menu with specific coordinates and animation, HandleDismiss() handles the fade out animation. collectionView() handles menu selection, layout of the cells and number of cells in the menu bar. BaseCell class the parent cell of all cells, MenuCellWT is the customized Cell for Menu, inherite from BaseCell. MenuCellWT add label, icon and constraint to the menu cell. 
  
  Once the login button is clicked.........................
  
  
  Destinations-
  The Admin has the ability to drop places known as destinations. After they press the button, line 1206 in ViewController.swift is    invoked. First what this does is goes to the ShapeManager.swift file and creates a subclass (Destination node) from the root class Navigaton Node.

  Next, it opens an alert box for the admin to type in the destination name and type. After the information has been input, all of the  metadata regarding the destination including location and map it is inside of is saved to the json that is sent to the Placenote cloud.
This all happens if there is no duplicate destination already in the storage.
  
  Checkpoint-
  The Admin also has the ability to drop checkpoints. Checkpoints are a crucial part of the navigation process for the user. Once the admin presses the checkpoint button, line   

The Admin does the bulk of the work for the application while the user side is meant to follow the instructions that the Admin has layed out. The file for the admin can be found in the ViewController.swift file. What the admin does is ______
