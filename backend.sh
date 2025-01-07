#!bin/bash
USERID=$(id -u)
#echo "$USERID "

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#we need to create the log folder path in the server
LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}



CHECK_ROOT(){
if [ $USERID -ne 0 ]
then
    echo "ERROR:: You must have sudo access to execute this script"
    exit 1 #other than 0
fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enabling  node js 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing node js"

id expense &>>$LOG_FILE_NAME 

if [ $? -ne 0 ]
then
useradd expense &>>$LOG_FILE_NAME 
VALIDATE $? "Adding expense user"
else
echo -e "Expense user already exist ............$y Skipping $N"
fi

mkdir /app &>>$LOG_FILE_NAME
VALIDATE $? "creating App directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading Source code"

cd /app

unzip /tmp/backend.zip  &>>$LOG_FILE_NAME
VALIDATE $? "Unzipping source code"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing npm "

cp /home/ec2-user/expense-shell/backend.service  /etc/systemd/system/backend.service

#Prepare Mysql Schema
dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing Mysql Client"

mysql -h mysql.sgkinfo.xyz -uroot -pExpenseApp@1 < /app/schema/backend.sql
VALIDATE $? "Setting up the transactions and schemas and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "daemon Reloading "

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enable backend"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? "start backend"


systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Restarting backend"


