#!/bin/bash

ID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
MONGDB_HOST=mongodb.daws76s.online   #go to rout53 select the hosted zone which you created, open it,create new record,give your server private ip,save,now copy and paste newly got Record name here

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
echo "script started executing at $TIMESTAMP" &>> $LOGFILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]
then 
    echo -e "$R ERROR :: please run this script with roor access $N"
    exit 1
else 
    echo -e "$G you are root user $N"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling current NodeJS"
dnf module enable nodejs:18 -y  &>> $LOGFILE
VALIDATE $? "Enabling NodeJS:18"
dnf install nodejs -y  &>> $LOGFILE
VALIDATE $? "Installing NodeJS:18"

id roboshop #if roboshop user does not exist, then it is failure
if [ $? -ne 0 ]
then
    useradd roboshop
    VALIDATE $? "roboshop user creation"
else
    echo -e "roboshop user already exist $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip  &>> $LOGFILE    #downloading application code
VALIDATE $? "Downloading catalogue application"

cd /app
unzip -o /tmp/catalogue.zip  &>> $LOGFILE
VALIDATE $? "unzipping catalogue"
npm install  &>> $LOGFILE    #installing dependencies
VALIDATE $? "Installing dependencies"

# use absoluteexact path where catalogue.service file is, because catalogue.service exists there
cp /home/centos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Copying catalogue service file"
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "catalogue daemon reload"
systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enable catalogue"
systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Starting catalogue"
cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo"
dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "Installing MongoDB client"
mongo --host $MONGDB_HOST </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "Loading catalouge data into MongoDB"

