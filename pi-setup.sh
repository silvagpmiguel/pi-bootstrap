#!/bin/bash
set -e

BOOT_CMDLINE_PATH="/boot/cmdline.txt"
CGROUP_CONFIG="cpuset cgroup_memory=1 cgroup_enable=memory"
IP_ADDRESS=
MOTD_NEOFETCH_PATH=/etc/update-motd.d/10-neofetch
RPI_DATA_PATH='/etc/rpimonitor/data.conf'
RPI_DEFAULT_DATA="#web.friends.1.name=Raspberry Pi
#web.friends.1.link=http://192.168.0.123/
#web.friends.2.name=Shuttle
#web.friends.2.link=http://192.168.0.2/

web.page.icon='img/logo.png'
web.page.menutitle='RPi-Monitor  <sub>('+data.hostname+')</sub>'
web.page.pagetitle='RPi-Monitor ('+data.hostname+')'
web.status.1.name=Raspberry Pi
#web.status.2.name=Home
web.statistics.1.name=Raspberry Pi
#web.statistics.2.name=page 2
#web.addons.1.name=Addons
#web.addons.1.addons=about
web.addons.1.name=Shellinabox
web.addons.1.addons=custom
web.addons.1.url=http://diglett.local/shellinabox

include=/etc/rpimonitor/template/version.conf
include=/etc/rpimonitor/template/uptime.conf
include=/etc/rpimonitor/template/services.conf
include=/etc/rpimonitor/template/cpu.conf
include=/etc/rpimonitor/template/memory.conf
include=/etc/rpimonitor/template/sdcard.conf
include=/etc/rpimonitor/template/swap.conf
"
RPI_SD_PATH='/etc/rpimonitor/template/sdcard.conf'
RPI_SD_DATA=`cat <<-'EOF'
static.7.name=sdcard_root_total
static.7.source=df /
static.7.regexp=\S+\s+(\d+).*\/$
static.7.postprocess=$1/1024

static.8.name=sdcard_boot_total
static.8.source=df /boot/firmware
static.8.regexp=\S+\s+(\d+).*\/boot.*$
static.8.postprocess=$1/1024

dynamic.6.name=sdcard_root_used
dynamic.6.source=df /
dynamic.6.regexp=\S+\s+\d+\s+(\d+).*\/$
dynamic.6.postprocess=$1/1024
dynamic.6.rrd=GAUGE

dynamic.7.name=sdcard_boot_used
dynamic.7.source=df /boot/firmware
dynamic.7.regexp=\S+\s+\d+\s+(\d+).*\/boot.*$
dynamic.7.postprocess=$1/1024
dynamic.7.rrd=GAUGE

web.status.1.content.7.name=SD card
web.status.1.content.7.icon=sd.png
web.status.1.content.7.line.1="<b>/boot</b> Used: <b>"+KMG(data.sdcard_boot_used,'M')+"</b> (<b>"+Percent(data.sdcard_boot_used,data.sdcard_boot_total,'M')+"</b>) Free: <b>"+KMG(data.sdcard_boot_total-data.sdcard_boot_used,'M')+ "</b> Total: <b>"+ KMG(data.sdcard_boot_total,'M') +"</b>"
web.status.1.content.7.line.2=ProgressBar(data.sdcard_boot_used,data.sdcard_boot_total,60,80)
web.status.1.content.7.line.3="<b>/</b> Used: <b>"+KMG(data.sdcard_root_used,'M') + "</b> (<b>" + Percent(data.sdcard_root_used,data.sdcard_root_total,'M')+"</b>) Free: <b>"+KMG(data.sdcard_root_total-data.sdcard_root_used,'M')+ "</b> Total: <b>"+ KMG(data.sdcard_root_total,'M') + "</b>"
web.status.1.content.7.line.4=ProgressBar(data.sdcard_root_used,data.sdcard_root_total,60,80)

web.statistics.1.content.3.name=Disks - boot
web.statistics.1.content.3.graph.1=sdcard_boot_total
web.statistics.1.content.3.graph.2=sdcard_boot_used
web.statistics.1.content.3.ds_graph_options.sdcard_boot_total.label=Size of /boot (MB)
web.statistics.1.content.3.ds_graph_options.sdcard_boot_total.color="#FF7777"
web.statistics.1.content.3.ds_graph_options.sdcard_boot_used.label=Used on /boot (MB)
web.statistics.1.content.3.ds_graph_options.sdcard_boot_used.lines={ fill: true }
web.statistics.1.content.3.ds_graph_options.sdcard_boot_used.color="#7777FF"

web.statistics.1.content.4.name=Disks - root
web.statistics.1.content.4.graph.1=sdcard_root_total
web.statistics.1.content.4.graph.2=sdcard_root_used
web.statistics.1.content.4.ds_graph_options.sdcard_root_total.label=Size of / (MB)
web.statistics.1.content.4.ds_graph_options.sdcard_root_total.color="#FF7777"
web.statistics.1.content.4.ds_graph_options.sdcard_root_used.label=Used on / (MB)
web.statistics.1.content.4.ds_graph_options.sdcard_root_used.lines={ fill: true }
web.statistics.1.content.4.ds_graph_options.sdcard_root_used.color="#7777FF"
EOF
`
RPI_SHELL_PATH='/etc/default/shellinabox'
RPI_SHELL_DATA='SHELLINABOX_DAEMON_START=1
SHELLINABOX_PORT=4200
SHELLINABOX_ARGS="--no-beep --disable-ssl"
'
RPI_TOP3_PATH='/usr/share/rpimonitor/web/addons/top3/top3.html'
RPI_TOP3_DATA=`cat <<-'EOF'
#!/usr/bin/perl
my $process='rpimonitor';
my $web=1;
my $nbtop=3;
my @top=[];
my $monitored;
#Get uptime
my $uptime;

open ( FILE, "/proc/uptime") or die "Can't open /proc/uptime \n";
while (<FILE>){
  /(\S+) \S+/;
  $uptime = $_;
}
my $idx=0;
open (PS, 'ps -e -o etimes,time,comm --sort -time |') or die;
while (<PS>)
{
  /TIME/ and next;
  $idx++;
  /$process/ and $monitored->{'idx'} ||= $idx;
  /$process/ or $idx <= $nbtop or next;
  /(\S+) (\S+):(\S+):(\S+) (\S+)/;
  $1 or next;
  my $start=100*($2*60*60+$3*60+$4)/$1;
  my $total=100*($2*60*60+$3*60+$4)/$uptime;
  $web
  and $top[$idx] = sprintf("<tr><td>%3d</td><td>%02d:%02d:%02d</td><td>%-12s</td><td>( %.2f% / %.2f% )</td></tr>\n",$idx, $2, $3, $4, $5, $start, $total)
  or $top[$idx] = sprintf("%3d %02d:%02d:%02d %-12s ( %.2f% / %.2f% ) \n",$idx, $2, $3, $4, $5, $start, $total);
}
close PS or die;
my $iloop;
  $web
  and print "<table class='table'>\n"
  and print "<tr><th>#</th><th>CPU usage</th><th>Process</th><th>% start / total</th></tr>\n";
  for ($iloop=1; $iloop<=$nbtop; $iloop++)
  {
    print $top[$iloop];
  }
  $web
  and print "</table>\n";
EOF
`
RPI_CPU_PATH='/etc/rpimonitor/template/cpu.conf'
RPI_CPU_DATA='dynamic.1.name=cpu_frequency
dynamic.1.source=/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq
dynamic.1.regexp=(.*)
dynamic.1.postprocess=$1/1000
dynamic.1.rrd=

dynamic.2.name=cpu_voltage
dynamic.2.source=vcgencmd measure_volts core
dynamic.2.regexp=(\d+.\d+)V
dynamic.2.postprocess=
dynamic.2.rrd=

dynamic.3.name=load1,load5,load15
dynamic.3.source=/proc/loadavg
dynamic.3.regexp=^(\S+)\s(\S+)\s(\S+)
dynamic.3.postprocess=
dynamic.3.rrd=GAUGE

dynamic.4.name=scaling_governor
dynamic.4.source=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
dynamic.4.regexp=(.*)
dynamic.4.postprocess=
dynamic.4.rrd=

dynamic.5.name=temp
dynamic.5.source=/sys/devices/virtual/thermal/thermal_zone0/temp
dynamic.5.regexp=(.*)
dynamic.5.postprocess=sprintf("%.2f", $1/1000)
dynamic.5.rrd=GAUGE

static.9.name=max_proc
static.9.source=nproc
static.9.regexp=(.*)
static.9.postprocess=$1 + 1

web.status.1.content.1.name=CPU
web.status.1.content.1.icon=cpu.png
#web.status.1.content.1.line.1="Loads: <b>" + data.load1 + "</b> [1min] - <b>" + data.load5 + "</b> [5min] - <b>" + data.load15 + "</b> [15min]"
web.status.1.content.1.line.1=JustGageBar("Load", "1min", 0, data.load1, data.max_proc, 100, 80)+" "+JustGageBar("Load", "5min", 0, data.load5, data.max_proc, 100, 80)+" "+JustGageBar("Load", "15min", 0, data.load15, data.max_proc, 100, 80)+" "+JustGageBar("Temperature", data.temp+"°C", 40, data.temp, 80, 100, 80)
web.status.1.content.1.line.2="CPU frequency: <b>" + data.cpu_frequency + "MHz</b> Voltage: <b>" + data.cpu_voltage + "V</b>"
web.status.1.content.1.line.3="Scaling governor: <b>" + data.scaling_governor + "</b>"
web.status.1.content.1.line.4=InsertHTML("/addons/top3/top3.html")

web.statistics.1.content.1.name=CPU Loads
web.statistics.1.content.1.graph.1=load1
web.statistics.1.content.1.graph.2=load5
web.statistics.1.content.1.graph.3=load15
web.statistics.1.content.1.ds_graph_options.load1.label=Load 1min
web.statistics.1.content.1.ds_graph_options.load5.label=Load 5min
web.statistics.1.content.1.ds_graph_options.load15.label=Load 15min
'
NGINX_CONF_PATH=/etc/nginx/nginx.conf
NGINX_DEFAULT_CONF="user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}
http {
        # Basic
        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        # SSL
        #ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
        #ssl_prefer_server_ciphers on;

        # Logging
        access_log /var/log/nginx/access.log;

        #Gzip
        #gzip on;

        # Server
        server {
                listen 80;
                server_name $USER.local;

                location = / {
                        return 301 /dashboard;
                }
                location /shellinabox/ {
                        proxy_pass http://localhost:4200;
                }
                location /dashboard/ {
                        proxy_pass http://localhost:8888;
                }
                location /addons/ {
                        proxy_pass http://localhost:8888;
                }
        }
}
"

if [ -z "$IP_ADDRESS" ]; then
    read -rp "Insert your IP address: " IP_ADDRESS
fi

echo "Installing basic utilitaries..."
sudo apt -y update 
sudo apt -y upgrade 
sudo apt -y install ca-certificates curl cgroupfs-mount exfat-fuse exfatprogs ntfs-3g

read -r -n2 -p "Do you want to customize your ssh banner with neofetch (y/n)? "
if [ "$REPLY" = "y" ]; then
    if [ -f "$MOTD_NEOFETCH_PATH" ]; then
        echo "Skipping... The banner is already customized."
    else 
        echo "Begin neofetch install..."
        sudo apt -y install neofetch
        echo "Clear static banner..."
        sudo truncate -s 0 /etc/motd
        echo "Configurating neofetch to run in $MOTD_NEOFETCH_PATH..."
        echo '#!/bin/sh
    neofetch' | sudo tee -a "$MOTD_NEOFETCH_PATH"
        sudo chmod +x "$MOTD_NEOFETCH_PATH"
    fi
fi

echo "Verifying if cgroup is configured..."
if grep -F "$CGROUP_CONFIG" "$BOOT_CMDLINE_PATH"; then
    echo "Cgroup is already configured!"
else 
    echo "Configuring cgroup..."
    printf " $CGROUP_CONFIG" | sudo tee -a "$BOOT_CMDLINE_PATH"
fi 

read -r -n2 -p "Do you want to configure a static ip address (y/n)? "
if [ "$REPLY" = "y" ]; then
    echo "Configuring static ip address in /etc/dhcpcd.conf..."
    echo "interface eth0
static ip_address=$IP_ADDRESS/24
static routers=192.168.1.254" | sudo tee -a /etc/dhcpd.conf
fi

read -r -n2 -p "Do you want to install Rpi monitor (y/n)? " 
if [ "$REPLY" = "y" ]; then
    echo "Begin rpimonitor install..."
    sudo apt -y install dirmngr
    echo "Setting up rpimonitor apt repository..."
    sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2C0D3C0F
    sudo wget http://goo.gl/vewCLL -O /etc/apt/sources.list.d/rpimonitor.list
    sudo apt -y update
    echo "Installing rpimonitor..."
    sudo apt -y install rpimonitor
    echo "Improving default config..."
    sudo truncate -s 0 $RPI_DATA_PATH
    echo "$RPI_DEFAULT_DATA" | sudo tee -a $RPI_DATA_PATH
    echo "Activating shell-in-a-box plugin..."
    sudo apt -y install shellinabox
    sudo truncate -s 0 $RPI_SHELL_PATH
    echo "$RPI_SHELL_DATA" | sudo tee -a $RPI_SHELL_PATH
    sudo systemctl restart shellinabox
    echo "Activating top3 plugin..."
    sudo cp /usr/share/rpimonitor/web/addons/top3/top3.cron /etc/cron.d/top3
    sudo truncate -s 0 $RPI_TOP3_PATH
    echo "$RPI_TOP3_DATA" | sudo tee -a $RPI_TOP3_PATH
    echo "Improving cpu config and enabling top3..."
    sudo truncate -s 0 $RPI_CPU_PATH    
    echo "$RPI_CPU_DATA" | sudo tee -a $RPI_CPU_PATH
    echo "Fix sd card config"
    sudo truncate -s 0 $RPI_SD_PATH    
    echo "$RPI_SD_DATA" | sudo tee -a $RPI_SD_PATH
    echo "Triggering rpimonitor update..."
    sudo /etc/init.d/rpimonitor update
    sudo apt -y update -y
    sudo apt -y upgrade -y
    sudo systemctl restart rpimonitor
fi

read -r -n2 -p "Do you want to install docker (y/n)? "
if [ "$REPLY" = "y" ]; then
    echo "Begin docker installation..."
    echo "Add docker to apt..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt -y update
    echo "Installing docker..."
    sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

read -r -n2 -p "Do you want to install k3s (y/n)? "
if [ "$REPLY" = "y" ]; then
    echo "Begin k3s installation..."    
    echo "Installing k3s and binding to address $IP_ADDRESS..." 
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik --flannel-backend=host-gw --tls-san=$IP_ADDRESS --bind-address=$IP_ADDRESS --advertise-address=$IP_ADDRESS --node-ip=$IP_ADDRESS --cluster-init" sh -s -
fi

read -r -n2 -p "Do you want to install nginx (y/n)? "
if [ "$REPLY" = "y" ]; then
    echo "Begin nginx install..."
    sudo apt install -y nginx
    echo "Overwrite default config to a simple one with redirect / to /dashboard and proxypass in order to use rpimonitor..."
    sudo truncate -s 0 $NGINX_CONF_PATH
    echo "$NGINX_DEFAULT_CONF" | sudo tee -a $NGINX_CONF_PATH    
    sudo systemctl reload nginx
fi

read -r -n2 -p "Setup has finished, reboot now? (y/n)? "
if [ "$REPLY" = "y" ]; then
    sudo reboot now
fi
