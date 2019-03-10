This is just a placeholder README.md

Details of how the ultimate navigation works:

Admin
1.
Make prompt for checkpoint dropping

User
2.
You have arrived pop up

3.
Navigation
	- Make the dictionary for checkpoint location
	- Make Queue/Stack for highest priority map
	- Store maps as vertecies for A* algorithm

	
General process:

Admin will make maps with appropriate number of checkpoints. Once a checkpoint is dropped,
the location of the checkpoint along with the checkpoint will be saved in a dictionary passed to 
placenote. 

User will select a destination and once the destination is selected, the destination map will
be identified and the vertecies of maps will stored in a graph to be run through A* to find 
the shortest path of maps. They will then be added to a priority queue/stack that will be 
used to find the appropriate checkpoint. The appropriate checkpoint is found by finding the
one that has the closest distance to the next map in the queue. Once all of the processing 
and configuration is complete, the user will be guided to the checkpoint that is closets to 
the next map in the queue/stack.


