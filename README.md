Sinatra Tic-Tac-Toe
===================
A Sinatra server that allows users to login, receive a confirmation e-mail via Mandrill, and submit turns that are processed in the cloud by IronWorker.

Done
----
**Tic-Tac-Toe move processor:** runs in ruby with info stored in a hash usable by IronWorker or the Sinatra server
**Login & Confirmation:** Hashes passwords for security; sends confirmation e-mail via Mandrill; Logs in, signs up or rejects with appropriate error messages using session[:token]; 
**IronWorker processing:** Accepts input from Sinatra server and processes the turn

To-Do
-----
**IronWorker output:** Use IronMQ to give turn results to the users
**Matchmaking:** Allow users to connect to eachother and exclude others from their games
**Lobby & Game Chat**

Lessons Learned
---------------
**Server can be smaller:** With cloud services like iron.io the server is only needed for the most basic functions like matchmaking. Sinatra is better suited for a general games server that can spin up IronWorker with whatever program you want. Anything that doesn't need to be always available should be done on an as needed basis.

This greatly simplifies scaling and versatility as the server would no longer care what program it connects users to.