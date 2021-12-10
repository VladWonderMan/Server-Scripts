#!/bin/bash
to="mymail@email.com"
mail="mail.rezerv"
path="/backup"
 find $path -type f -mtime +15 -exec rm {} \;
 mysqldump -h localhost -uroot -ppassword -B DataBase > $path/DataBase_$(date +%d-%m-%Y).sql
 tar -zcpf  $path/DataBase_$(date +%d-%m-%Y).tar.gz /var/www>/dev/null 2>&1

  if [[ -f  $path/DataBase_$(date +%d-%m-%Y).tar.gz &&  -f  $path/DataBase_$(date +%d-%m-%Y).sql ]]; then
		echo $(date +%d.%m.%Y" "%H:%M:%S)" Backup Successful" >>/var/log/scripts.log
		hping3 -c 1 google.com>/dev/null 2>&1
			if [ $? -eq 0 ]; then
				#preparing report and sending email
				echo "To: <"$to">" >>$mail
				echo "From: FromMail <FromMail@email.com>" >>$mail
				echo "Subject: Backup Successful" >>$mail
				echo "Mime-Version: 1.0" >>$mail
				echo "Content-Type: text/plain; charset=koi8-r" >>$mail
				echo "Content-Transfer-Encoding: 8bit" >>$mail
				echo "Backup Successful" >>$mail

					if [ -f $mail ]; then
						cat $mail|msmtp -C /etc/msmtprc $to
						rm -rf $mail
					fi
			fi
    else
     echo $(date +%d.%m.%Y" "%H:%M:%S)" Backup Failed. Files Not Found" >>/var/log/scripts.log
     hping3 -c 1 google.com>/dev/null 2>&1
     if [ $? -eq 0 ]; then
        #preparing report and sending email
         echo "To: <"$to">" >>$mail
         echo "From: FromMail <FromMail@email.com" >>$mail
         echo "Subject: Backup Failed" >>$mail
         echo "Mime-Version: 1.0" >>$mail
         echo "Content-Type: text/plain; charset=koi8-r" >>$mail
         echo "Content-Transfer-Encoding: 8bit" >>$mail
         echo "Backup Failed. Files Not Found" >>$mail

             if [ -f $mail ]; then
               cat $mail|msmtp -C /etc/msmtprc $to
               rm -rf $mail
             fi
	    fi

  fi
