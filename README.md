1942 arcade
===========

FPGA 1942 arcade game for 18-545 capstone project

By: Gregory Nazario, Tyler Huberty, and Issac Simha

Introduction
===========
This project was built for the 18-545 capstone at Carnegie Mellon University.
This project won 1st place in the best project competition and had full
graphics for the arcade controls and bezel on the CRT screen.  It used a
custom VGA interface that allowed for 12-bits of video output.

Main board
===========
The files in the main folder can be used to run the game 1942.  It implements
some of the foreground sounds and can be changed with little effort to include
more sounds.  Also, it fully implements the graphics for the game including
scrolling.  It lacks the functionality to flip the screen and stop the screen,
according to dip switches, however.

Sound board
==========

The sound board folder contains the code for the separate background sounds.
It allows for larger sounds to be played from that board.



_Disclaimer_
The actual game data is not in this repository.


