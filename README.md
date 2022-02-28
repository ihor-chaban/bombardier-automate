
# bombardier-automate
Script for Docker image [alpine/bombardier](https://hub.docker.com/r/alpine/bombardier) to DDoS multiple targets simultaneously.  Allows to dynamically update targets using Google Drive or any other service, so all you need to do is just run the script in the background.

#### Requirements
- *NIX operating system
- Docker installed

#### Example how to use with Google Drive:
- Create any `.txt` file with the list of URLs:
```
https://www.sberbank.ru/
...
https://government.ru/
```
- Upload it to your Google Drive and make it publicly **readable**.
- Get the link like `https://drive.google.com/file/d/1rmAAKhf039g5leQdd3u45xtlMQ3Bj_ad9FJ/view?usp=sharing` and reformat it to `https://drive.google.com/uc?id=1rmAAKhf039g5leQdd3u45xtlMQ3Bj_ad9FJ`  using the ID from the original link.
- Paste the result link `https://drive.google.com/uc?id=1rmAAKhf039g5leQdd3u45xtlMQ3Bj_ad9FJ` to `config` in **TARGETS** variable.

In order to modify the file in place in your Google Drive, use **Open With - Text Editor** app, the default Google Documents will not modify the .txt file, but will rather make a copy of it!

All other settings in `config` can be left as is.
In case you want to change them, they are pretty straightforward and described in comments.

#### Now you are ready to go!
Just grant the script permissions to be executed and run it:
```
$ chmod 755 bombardier-automate.sh
$ ./bombardier-automate.sh
```
Or run in a background:
```
$ nohup ./bombardier-automate.sh &
```

Now the script will continuously iterate overall targets, check if they are available, and start DDoS if yes. You may just update the list in your Google Drive and all the changes will be picked up at the next fetch.

To stop and remove all the containers after script termination use
```
$ for container in $(docker ps -a --format "{{.Names}}" | grep "^ddos_"); do docker rm -f "$container"; done
```

#### The actual targets and coordination info can be found here https://t.me/itarmyofukraine2022
