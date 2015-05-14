num=16
cat << HTTP > /home/vagrant/http.sh
#!/bin/sh
touch /home/cirros/cloud-init.test
sh -c echo "while true; do echo -e 'HTTP/1.0 200 OK\r\n\r\nYou are connected to 10.0.0.10$num' | sudo nc -l -p 80; done &" > /home/cirros/http.sh
chmod +rx /home/cirros/http.sh
/home/cirros/http.sh > /dev/null 2>&1
exit 0
HTTP

nova boot --image cirros-0.3.4-x86_64-uec --flavor 6 --user-data /home/vagrant/http.sh --key-name vagrant node$num
