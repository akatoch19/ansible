#!/bin/bash

export ANSIBLE_FORCE_COLOR=true
export ANSIBLE_HOST_KEY_CHECKING=False

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

# Change to directory for Deployment
DEPLOYMENT_HOME=${1}
DOMAIN_NAME=${2}

echo -e "Creating Temp Certificate Directory\n"
CERT_PATH="${DEPLOYMENT_HOME}/cert"
mkdir ${CERT_PATH}


echo -e "Retreive all the details related to domain certificate\n"

echo -e "Copying CSR and KEY to Temp directory - ${CERT_PATH}\n"
csr_dir="${DEPLOYMENT_HOME}/dashboard/csr-key"
for i in `ls -lt ${csr_dir} | grep -i ${DOMAIN_NAME} | tail -2 | awk '{print $NF}'` ; do cd ${csr_dir};  cp $i ${CERT_PATH} ; done

QUERY="select docfile from dashboard_document where domain_name='${DOMAIN_NAME}' ORDER BY id DESC LIMIT 1"
zip=$(mysql -h devops.birdeye.internal -u devops -pAdSR3cAtyW -D devops -e "begin;$QUERY;commit")
if [[ ( $? -ne 0 ) || ( "$zip" = "" ) ]]; 
then
  echo "${red}Domain name ${DOMAIN_NAME} entered not exist in our record!!\nKindly try agian with correct Domain name\n"
  exit 1
else
  zip_file=`echo $zip | awk '{print $NF}'`
  echo -e "\n${green}File : $zip_file \n" ${reset}
fi

QUERY="select tldr_name from dashboard_document where domain_name='${DOMAIN_NAME}' ORDER BY id DESC LIMIT 1"
host_name=$(mysql -h devops.birdeye.internal -u devops -pAdSR3cAtyW -D devops -e "begin;$QUERY;commit") 
tldr_name=`echo $host_name | awk '{print $NF}'`
if [[ ( $? -ne 0 ) || ( "$tldr_name" = "" ) ]];
then
  echo "${red}Hostname for domain ${DOMAIN_NAME} not found in our record!!" ${reset}
  exit 1
fi 

echo -e "\n${green}Hostname : ${tldr_name} \n" ${reset}

QUERY="select admin_emailid from dashboard_csrrequest where domain_name='${DOMAIN_NAME}' ORDER BY id DESC LIMIT 1"
ADMIN_EMAIL=$(mysql -h devops.birdeye.internal -u devops -pAdSR3cAtyW -D devops -e "begin;$QUERY;commit")
if [[ ( $? -ne 0 ) || ( "$ADMIN_EMAIL" = "" ) ]];
then
  echo -e "${red}Admin Email Address not found in record kindly check we are setting it to default address: admin@birdeye.com\n" ${reset}
  ADMIN_EMAIL='admin@birdeye.com'
else
  email=`echo $ADMIN_EMAIL | awk {'print $2'}`
  ADMIN_EMAIL=$email
  echo -e "\n${green}Admin Email: ${ADMIN_EMAIL}\n" ${reset}
fi 

echo -e "Copying zip file to temp cert path\n"
cp -p ${DEPLOYMENT_HOME}/dashboard/devops/media/${zip_file} ${CERT_PATH}

cd ${CERT_PATH}
echo -e "Extract zip file and rename certificate files\n"
unzip -j *.zip
echo -e "\nDeleting zip file" 
rm  -f *.zip
#Running a check for file name with whitespace and removing it	
for f in *\ *; do mv "$f" "${f// /_}"; done
ls -1

#For comodo only
if ls -1 | grep -iq COMODO ; then
  cat ${CERT_PATH}/COMODORSADomainValidationSecureServerCA.crt > "${DOMAIN_NAME}_ca.crt"
  cat ${CERT_PATH}/COMODORSAAddTrustCA.crt >> "${DOMAIN_NAME}_ca.crt"
  rm -f COMODORSADomainValidationSecureServerCA.crt COMODORSAAddTrustCA.crt AddTrustExternalCARoot.crt
  cabundlefile="${DOMAIN_NAME}_ca.crt"
fi

for i in `ls -1`; do
  echo -e "\nLoop evaluating file : $i\n"
  if echo $i | grep -iqF gd_bundle-g2 ;  then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  elif echo $i | grep -iqF Intermediate ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt 
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  elif echo $i | grep -iqF '_ca.crt' ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  elif echo $i | grep -iqF 'bundle' ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  elif echo $i | grep -iqF 'inter.crt' ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  elif echo $i | grep -iqF 'starfield' ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
    mv  $i ${DOMAIN_NAME}_ca.crt
    cabundlefile="${DOMAIN_NAME}_ca.crt"
  else
    if echo $i | grep -iqF DigiCertCA.crt ; then
      echo -e "\nMoving ${i} to ${DOMAIN_NAME}_ca.crt\n"
      mv  $i ${DOMAIN_NAME}_ca.crt
      cabundlefile="${DOMAIN_NAME}_ca.crt"
    fi
  fi

  if echo $i |grep -iE "pem|cert|\.crt|\.cert" |  grep -ivE "gd_bundle|Intermediate|_ca.crt|ca.crt|comodo|positive|trustca|ca-bundle|bundle";  then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}.crt\n"
    mv  $i ${DOMAIN_NAME}.crt
    certfile="${DOMAIN_NAME}.crt"
  fi

  if echo $i |grep "\.key" ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}.key\n"
    mv  $i ${DOMAIN_NAME}.key
    keyfile="${DOMAIN_NAME}.key"
  fi

  if echo $i |grep "\.csr" ; then
    echo -e "\nMoving ${i} to ${DOMAIN_NAME}.csr\n"
    mv  $i ${DOMAIN_NAME}.csr
    CsrFile="${DOMAIN_NAME}.csr"
  fi  
done

#Check if cabundle file found
  if [[ ! -z "$cabundlefile" ]]
  then
    echo -e "\ncabundlefile=$cabundlefile"
  else
    echo -e "\nCA Bundle file missing\nExiting execution\n"
#    exit 1
  fi

ls -1
echo -e "\nCheck if CRT and CSR matches\n" 
cd ${CERT_PATH}
CRT_HASH=`openssl x509 -noout -modulus -in ${certfile}  | openssl md5 | awk {'print $2'}`

KEY_HASH=`openssl rsa -noout -modulus -in ${keyfile} | openssl md5 | awk {'print $2'}`

CSR_HASH=`openssl req -noout -modulus -in ${CsrFile} | openssl md5 | awk {'print $2'}`

echo -e "\ncertfile=$certfile, keyfile=$keyfile CsrFile=$CsrFile\n"
echo -e "\n\nCRT_HASH=$CRT_HASH, KEY_HASH=$KEY_HASH, CSR_HASH=$CSR_HASH\n\n"

if [[ ${CRT_HASH} == ${KEY_HASH} ]] ; then # [[ && ${CRT_HASH} == ${CSR_HASH} ]] ; then
  echo -e "${green}KEY CRT is valid for domain ${DOMAIN_NAME}\n"
else
  echo -e "${red}Invalid Certifiace uploaded for domain : ${DOMAIN_NAME}\n" ${reset}
  exit 1
fi

cd $DEPLOYMENT_HOME

failed()
{
  Failed=true;
}

# Delete inventory , script will recreate fresh inventory.
cd $DEPLOYMENT_HOME/ansible/ansible/apache-playbook
if [ ! -d $DEPLOYMENT_HOME/ansible/ansible/apache-playbook/inventory ]
then
    mkdir $DEPLOYMENT_HOME/ansible/ansible/apache-playbook/inventory
fi
   
rm -rf inventory/*;


echo -e "${green}Creating host inventory\n"${reset}
/usr/bin/fab -f release.py set_hosts_from_elbs;

if [ $? -ne 0 ]
then
   echo -n "${red}Inventory population failed\n" ${reset}
   failed
   exit 1
fi

echo -e '\n50.18.123.174' >> $DEPLOYMENT_HOME/ansible/ansible/apache-playbook/inventory/ProdUILB

echo -e "${green}\n...................Deploying SSL Certificate on hosts for domain ${DOMAIN_NAME}.......................... \n"
echo -e "\n${green}Keep Patience.Job is being executed in background and connsole will be updated in a a while , if job seems taking more than usual, contact devops team"


echo "${green}Started Build at " `date` ${reset}

cd "${DEPLOYMENT_HOME}/ansible/ansible/apache-playbook"
#Invoke ansible with the aropriate parameters
/usr/bin/ansible-playbook paidui.yml --private-key=/var/lib/jenkins/ssh-keys/ProductionUI -u bitnami -i inventory --extra-vars "domain=${DOMAIN_NAME} adminemail=${ADMIN_EMAIL} sslhostname=${tldr_name} cert_path=${CERT_PATH} certfile=${certfile} keyfile=${keyfile} cabundlefile=${cabundlefile} Account='PAID_PROD_TERRAFORM' Region='us-west-1'"


if [ $? -ne 0 ]
then
	echo "${red}Build failed , Check build logs" ${reset}
        exit 1
else
	echo "${green}Finished Build at " `date` ${reset}
fi
