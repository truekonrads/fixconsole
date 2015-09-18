```
___________.__       _________                            .__          
\_   _____/|__|__  __\_   ___ \  ____   ____   __________ |  |   ____  
 |    __)  |  \  \/  /    \  \/ /  _ \ /    \ /  ___/  _ \|  | _/ __ \ 
 |     \   |  |>    <\     \___(  <_> )   |  \\___ (  <_> )  |_\  ___/ 
 \___  /   |__/__/\_ \\______  /\____/|___|  /____  >____/|____/\___  >
     \/             \/       \/            \/     \/                \/ 
```

# What is FixConsole? #

FixConsole is a flexible FIX client written in ruby which can be used to fuzz the a FIX1.1 protocol.
It handles the basic login nd heartbeat process allowing you to focus on writing bespoke test cases.

# How to use it? #

For example, see ```testcases.rb```, but in a nutshell you subclass the ```FixSession``` and then add bespoke mutators. 
In the provided example, we make use of ronin mutators.


