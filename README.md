##### Warning: I do not consider myself a networking expert. Do not take my words religiously. If I'm mistaken anywhere in this text or the code, please let me know. 

## This project uses the following program written by Jouni Malinen:
hostapd (https://w1.fi/hostapd/) for access point creation and authentication (WPA etc.)

## Extender
Puts a host (or a group of hosts) with a supported wireless card into AP mode for sharing it's Wifi connection. 

## Problem Statement
  Given an environment where only one computer has access to a Wireless connection, how would you extend it's connection to other areas of the environment?
  
  Well, the "extension" part can be done simply by using hostapd (https://w1.fi/hostapd/). But you would soon realise that you have another problem.
  
  For example, take into a consideration the following setup: 
  
  ![alt text](https://i.imgur.com/Wk304Wa.png)
  
  In an ideal scenario, the events that lead to successful internet sharing between the three computers would be these: 
  
  1. PC-1 connects to the access point (to which PC-1 & PC-2 have no access to or lie beyond it's range). It then creates an access point.
  2. PC-2 connects to the access point provided by PC-1. It then creates it's own access point.
  3. PC-3 connects to the access point provided by PC-2.
  
  However, what happens if, for some reason, all your access points are named the same? Here is one such scenario:
  
  1. PC-1 connects to the access point (conveniently named "AP") and creates it's own access point.
  2. PC-2 connects to AP (started by PC-1) and creates it's own access point also named "AP". Note that it cannot connect to the main access point since that's not in range.
  3. PC-3 connects to AP (started by PC-2).
  
  But here's the problem: Say for some reason, the connection between PC-1 & PC-2 gets disrupted. Now, PC-2 tries to reconnect to the access point named "AP". However, we've got two SSIDs named "AP" now (well, three but it can't connect to itself... at least, it shouldn't). It may so happen that PC-2 connects to AP (started by PC-3). This will lead to PC-2 and PC-3 being disconnected from the main network and they cannot access the internet now.
  
Even if all access points are named differently, we still need to manually specify which access points a PC can connect to (because PC-2 should never connect to the AP of PC-3). Automating this would be a pain since it would involve maintaining a file containing a list of SSIDs of access points a PC can connect to. 
  
### Solution

To prevent such a scenario from arising we must define to what access points a computer can connect to. One way of doing it is to assign a number (a level) to each PC.

![alt text](https://i.imgur.com/X21p2Fm.png)

With such a system, we can then define the following rule:

* A PC with a level "n" can only connect to a PC at a level "n-1" or lower.
  
This will prevent the problem discussed above.

To implement such a level system we embed the level "n" directly into the BSSID (mac address) of the created access point.

For example, look at the third byte in 12:00:02:e2:be:ce. It's 02 and denotes the level of the access point. Since it follows the rule defined above, the PC at level 2 can only connect with level 1 (Note that level 0 is the main access point which is not in range of the PC at level 2).

There are two shell scripts (BASH) named fdf_1.sh and fdf_2.sh .
* fdf_1.sh is for the PC at level 1 i.e. the PC that has direct access to the main access point.
* fdf_2.sh is for PCs at other levels i.e. the PCs that are indirectly connected to the main access point.

Further, we can also have multiple PCs at any level-n so as to provide a failover mechanism. In case a PC at level-n fails, all PCs from level-(n+1) get connected to another PC at level-n and the network does not disconect.

## The woes of WiFi i.e. caveats
* You cannot bridge wireless connections the same way you bridge ethernet connections. This is because an access point will outright reject frames coming from a MAC address that has not authenticated with it. This makes bridging impossible (without resorting to something like WDS whose adoption rate stays low).
* You could use a method known as Proxy ARP so as to "simulate a bridge". You can even use something like dhcp-helper to relay DHCP packets. But this method is still not bridging since it works at Layer 3. I suspect this is what Virtualbox uses to "bridge" wireless connections but I can't say for sure since I've not inspected the code myself.
* The method used here is the traditional use of a NAT. This method works well if your intent is just to share your internet connection. But for purposes such as, say, reaching a level-3 PC from level-1 you would have to resort to some hacky solutions such as static routes. This is because the network a PC is connected to and the network that a PC hosts (the access point) are not the same. For reasons discussed above, we cannot use bridging to solve this.
* Not all wireless cards can be put into AP mode while being connected to an access point simultaneously.
* The maximum clients that can connect to an access point created by hostapd varies from 6-8. This is not a limitation of hostapd itself but the wireless card.

## ToDo
1. Access $level as an environment variable rather than hardcoding it.
2. Clean up the procedure followed to detect if we're already connected.
3. Get rid of the spaghetti code.
