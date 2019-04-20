# shapester
A way to share limited bandwidth equitably among greedy endpoints

## Background
This is an example of a self-directed project I undertook in 2006.  2006 
was the heyday of filesharing, the likes of BitTorrent, Limewire, KaZaA, 
etc.  My network, with low-bandwidth uplinks and voracious data consumers, 
had sky-high latency and near unusability during peak usage.  Earlier 
efforts using more conventional QoS (i.e. a small number of queues) only 
served to move the bottleneck from the carrier router to our firewall's 
queue. This project's goal was to give each endpoint IP address its own 
piece of the pie with modest guaranteed upload bandwidth, but also the 
opportunity to consume more if there's excess capacity.

I accomplished this by using Linux TC (traffic control) and the HTB 
(Hierarchical Token Bucket) queueing discipline.  Each endpoint IP gets 
its own HTB queue.  Borrowing from unused excess capacity is allowed up 
to a configured limit.  If you want queueing to be effective, it has to 
happen at egress.  This only limits upload rate, so the queues are only 
configured on the external interface.

This script has been edited as lightly as possible, only to anonymize 
names and network settings.  I have grown quite a bit since writing this, 
but considering my experience level at the time, I'm still proud of this 
work.  I have not tried this code in about a decade, but I expect it still 
works, provided you run it on 2006-era Debian 3.1 ("Sarge").

## Usage

### Hardware Configuration
Build a Debian host with 3 NICs:

|   NIC  | Purpose                                        |
|-------:|:-----------------------------------------------|
| `eth0` | external, connect to Internet firewall         |
| `eth1` | internal, connect to network that needs taming |
| `eth2` | management, for administrator SSH logon        |

`eth0` and `eth1` are bridged together using `brctl` somewhere in 
`/etc/network/interfaces`.

NATing and firewalling is done by a separate device on the Internet side of 
this one.

### Script Usage
There are a few items you can tune in this script.

* Around line 175, `prefix` should be adjusted to match your LAN.  If you 
  have anything other than a Class C, you'll have to change some other lines.

* Around line 253, the minimum guaranteed rate is set to 36 kbit/sec per 
  host.  This number needs to be tweaked less than it seems.  Set it to your 
  total link speed divided by the maximum likely number of clients.

* One the same line (~253) the maximum rate per client is 150 kbit/sec.  You 
  might need to adjust it a bit.  If too high, file sharing users will have 
  their way.  If too low, legit interactive traffic will suffer.

Run it by hand and verify it works as designed.  Look at live traffic rates 
using a tool like `iptraf`, and ping the outside world and surf the web 
yourself when heavy uploads are going on.  If working properly, ping latency 
should be low, and you should be surfing some sick waves dude!

Once you're comfortable with it, run it at bootup from somewhere like 
`/etc/rc.local`.
