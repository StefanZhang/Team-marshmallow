Official Documentation for WhereTo?

WhereTo is an iOS application that utilizes Apple's ARKit library and the PlaceNoteSDK. The parts of the application include the user mode and the Admin mode.

The Admin does the bulk of the work for the application while the user side is meant to follow the instructions that the Admin has layed out.

User Mode:
The file for the user can be found in the ______.swift file. What the user does is select a destination in the ViewControllerWT.swift then _______

Backend: 
Step 1: In ViewControllerWT.swift, after a user has selected a destination, the name of the map which contains this destination as well as the coordinate of the destination (type SCNVector3), will be passed to ViewControllerWAY.swift.

Step 2: In ViewControllerWAY.swift, after a user has selected a initial location, the name of the map which contains this initial location as well as the coordinate of the initial location (type SCNVector3), will be passed to ViewControllerUM.swift, together with the desitination information mentioned in Step 1.

Step 3: In ViewControllerUM.swift, there are two main functions: loadMapButton and showPathbutton. 
The loadMapButton function takes the information of maps in Step 2 and run A* algorithm to find the shortest path from getting from the initial location map to destination map. The A* algorithm was implemented in AppDelegate.swift and used the CoreLocation of all of the maps stored in the Placenote Cloud. The maps that form the shortest path will be saved in the global variable mapStack.
After a stack of the maps have been found, we need to generate a shortest path of breadcrumbs in each map. In each shortest path, the first breadcrumb is the one closest to the user's current location, and the last breadcrumb is either a checkpoint or the final destination. The showPathButton function generates this shortest path of breadcrumbs in every map. And A* algorithm was used just like before.

In summary, if the initial location and destination are in the same map, then we only need to generate the shortest path of breadcrumbs once and display the shapes. However, if they are in different maps, then a path of maps will be found, and in all but the last map, we generate the shortest path of breadcrumbs from the closest breadcrumb to the best checkpoint. The best checkpoint was selected based on the checkpoints and maps' CoreLocation.

Admin Mode:
The file for the admin can be found in the ViewController.swift file. What the admin does is ______

The login of admin need to be click on the side bar menu, and then click the admin login. The front end side bar menu implementation is taking care by the class MenuLauncherWT, MenuCellWT and BaseCell. MenuLauncherWT as a launcher class gets called once the button being clicked in ViewControllerWT, the reason we create a seperate class for this is to reduce the code in the ViewcontrollerWT, and indeed solve the "Fat ViewController" issue, and easier to debug in case something went wrong. In MenuLauncherWT, ShowMenu() display menu with specific coordinates and animation, HandleDismiss() handles the fade out animation. collectionView() handles menu selection, layout of the cells and number of cells in the menu bar. BaseCell class the parent cell of all cells, MenuCellWT is the customized Cell for Menu, inherite from BaseCell. MenuCellWT add label, icon and constraint to the menu cell.

Once the login button is clicked.........................
