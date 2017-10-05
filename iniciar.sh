#!/bin/bash
#
# iniciar.sh

#########################################################################
# Crear Usuarios y entorno para VM en Openstack. JSJ                    #
#                                                                       #
# Version 3.0 05/10/2017                                                #
#          								#								#
# 									#
#                                                                       #
#########################################################################

echo_time() {
    date +"%d-%m-%Y  %H:%M:%S :  $*"
}

#
clear

ELIMINAR=0
SALTAR=0
echo " "
usage() { printf "Usage: $0 \n\n       [-u <usuario> ]\n       [-p <password> ]\n       [-s <sistema operativo> ]\t Valores admitidos: Windows o Ubuntu\n       [-t <tipo> ]\t Valores admitidos: Basic, Pro o Premium\n       [-n <Nombre instancia> ]\n       [-w ]\t Permite omitir la creación de usuario y contraseña y crear la instancia al usuario introducido\n\n       [-D <usuario> ]\t Elimina el usuario proporcionado\n\n       " 1>&2; exit 1; }

borrar()
{
touch /home/sistemas/usuarios/$USUARIO'_LOG'
LOG=/home/sistemas/usuarios/$USUARIO'_LOG'

echo_time " " >> $LOG
echo "Prueba para comprobar usuario y si existe, eliminarlo...!" >> $LOG
source /home/sistemas/admin_openrc
  # Comprobamos que no existe ya el usuario
  openstack user list | awk '{print $4}' > /home/sistemas/lista_usuarios.txt

if [[ "$USUARIO" =~ $(echo ^\($(paste -sd'|' /home/sistemas/lista_usuarios.txt)\)$) ]]; then
    echo "$USUARIO existe. Lo eliminamos... Pero antes eliminamos todo el entorno: INSTANCIAS, REDES, ROUTERS, etc... U know..." >> $LOG

FECHA=$(date +"%d%b%y") 

source /home/sistemas/usuarios/$USUARIO'rc'
# source /home/usuarios/admin_openrc 

for DELETE_INSTANCE_ID in $(openstack server list | grep 'ACTIVE\|SHUTOFF\|ERROR'  |awk {'print $2'})
do
openstack server delete $DELETE_INSTANCE_ID
echo_time "Instancia $DELETE_INSTANCE_ID Eliminada "  >> $LOG
done

for DELETE_ROUTER_ID in $(openstack router list | grep 'ACTIVE\|SHUTOFF\|ERROR' | awk {'print $2'})
do
openstack router delete $DELETE_ROUTER_ID
echo_time "Router $DELETE_ROUTER_ID Eliminado " >> $LOG
done

for DELETE_NETWORK_ID in $(openstack network list | grep '[1234567890]' | awk {'print $2'})
do
openstack network delete $DELETE_NETWORK_ID
echo_time "Red $DELETE_NETWORK_ID Eliminada "  >> $LOG
done

source /home/sistemas/admin_openrc

openstack project delete $USUARIO
echo_time "Proyecto Eliminado "  >> $LOG
openstack user delete $USUARIO
echo_time "Usuario Eliminado "  >> $LOG
openstack role delete $USUARIO
echo_time "Rol Eliminado "  >> $LOG
echo_time " Usuario: "$USUARIO" BORRADO" >> $LOG
mv /home/sistemas/usuarios/$USUARIO"*" /home/sistemas/usuarios/eliminados  &> /dev/null

rm /home/sistemas/lista_usuarios.txt  &> /dev/null

else
    echo "$USUARIO NO es un usuario valido. Abortamos el proceso..." >> $LOG
fi

exit 1
}


while getopts D:u:p:s:t:n:wh option
do
        case "${option}"
        in
		D) ELIMINAR=1
		   USUARIO=${OPTARG};;
                u) USUARIO=${OPTARG};;
                p) PASSWORD=${OPTARG};;
                s) SISTEMA=${OPTARG};;
                t) TIPO=${OPTARG};;
		n) INSTANCIA=${OPTARG};;
		w) SALTAR=1;;
		h) usage;;
		\?) echo "Opcion invalida: -"$OPTARG >&2 ;;
		:) echo "-"$OPTARG" requiere un argumento." >&2
            	usage;;
        esac
done

shift $((OPTIND-1))

if [ $ELIMINAR == 1 ]
then 
     borrar 
     exit 1
fi

# Comenzamos logueo

touch /home/sistemas/usuarios/$USUARIO'_LOG'
LOG=/home/sistemas/usuarios/$USUARIO'_LOG'


if [[ -z $USUARIO ]] || [[ -z $PASSWORD ]] || [[ -z $SISTEMA ]] || [[ -z $TIPO ]] || [[ -z $INSTANCIA ]]
then
     printf "Mira a ver si falta agún parámetro....paquete!\n\n"
     usage
     exit 1
fi
echo -ne '( #                                        )  (01 %)\r'

# Comprobamos SISTEMA
if [ $SISTEMA != "Windows" ] && [ $SISTEMA != "Ubuntu" ] && [ $SISTEMA != "Centos" ] && [ $SISTEMA != "windows" ] && [ $SISTEMA != "ubuntu" ] && [ $SISTEMA != "centos" ] 
then
echo "Opciones disponibles:  [Windows] o [Ubuntu] [Centos]"
echo "                        *           *        *"
echo " "
usage
exit
fi
echo -ne '( #                                        )  (02 %)\r'
# Comprobamos TIPO
if [ $TIPO != "Basic" ] && [ $TIPO != "Pro" ] && [ $TIPO != "Premium" ] && [ $TIPO != "m1.small" ]
then
echo "Opciones disponibles:  Basic, Pro y Premium"
echo "                       *      *     *"
echo " "
usage
exit
fi
echo -ne '( #                                        )  (03 %)\r'

echo -ne '( #                                        )  (04 %)\r'
echo_time " " >> $LOG
echo_time " " >> $LOG
echo_time "Datos introducidos:" >> $LOG
echo_time " " >> $LOG
echo_time "Usuario: " $USUARIO >> $LOG
echo_time "Password: " $PASSWORD >> $LOG
echo_time "Sistema: " $SISTEMA >> $LOG
echo_time "Tipo: " $TIPO  >> $LOG
echo_time "Instancia: " $INSTANCIA >> $LOG
echo_time " " >> $LOG

ROL=$USUARIO
echo -ne '( #                                        )  (05 %)\r'
#read -p "Pulsa [Enter] para continuar..."

source /home/sistemas/admin_openrc
PROYECTO=$USUARIO

if [ $SALTAR = 0 ];
  then 

  # Comprobamos que no existe ya el usuario
  openstack user list | awk '{print $4}' > /home/sistemas/lista_usuarios.txt
  grep -q $USUARIO '/home/sistemas/lista_usuarios.txt' && echo " " && echo "Usuario: "$USUARIO" YA EXISTE !!!" && echo " " && echo "CAMBIA DE USUARIO...!" && echo " " && rm /home/sistemas/lista_usuarios.txt && exit 0
echo -ne '( #                                        )  (06 %)\r'
  # Comprobamos que no existe ya el proyecto
  openstack project list | awk '{print $4}' > /home/sistemas/lista_proyectos.txt
  grep -q $PROYECTO '/home/sistemas/lista_proyectos.txt' && echo " " && echo "Proyecto: "$PROYECTO" YA EXISTE !!!" && echo " " && echo "CAMBIA DE NOMBRE DE PROYECTO...!" && echo " " && rm /home/sistemas/lista_proyectos.txt && exit 0
echo -ne '( ##                                       )  (07 %)\r'
  # Creamos Proyecto
  openstack project create --description $PROYECTO $PROYECTO &> /dev/null
  echo_time " " >> $LOG
  echo_time "Proyecto: "$PROYECTO" Creado." >> $LOG
echo -ne '( ##                                       )  (08 %)\r'
  # Creamos Usuario y Clave
  openstack user create --project $PROYECTO --password $PASSWORD $USUARIO &> /dev/null
  echo_time " " >> $LOG
  echo_time "Usuario "$USUARIO" y Clave, creados." >> $LOG
echo -ne '( ##                                       )  (09 %)\r'
  # Sacamos el ID del proyecto creado anteriormente
  PROJECTID=$(openstack project list | grep $PROYECTO | awk '{print $2}') &> /dev/null
echo -ne '( ###                                      )  (10 %)\r'
  #Creamos el ROL espeífico para ese usuario
  openstack role create $ROL &> /dev/null
echo -ne '( ###                                      )  (12 %)\r'
  # Asociamos el ID del proyecto al Usuario recien creado
  openstack role add --user $USUARIO --project $PROJECTID $ROL &> /dev/null
  echo_time " " >> $LOG
  echo_time "Usuario asociado al proyecto, ok" >> $LOG
echo -ne '( #####                                    )  (14 %)\r'
  #Generamos el fichero de credenciales del nuevo usuario
  echo_time " " >> $LOG
  echo_time "Creamos el fichero de credenciales para el usuario..." >> $LOG
  touch /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_NO_CACHE='true'" > /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_TENANT_NAME=$PROYECTO"  >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_PROJECT_NAME=$PROYECTO" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_USERNAME=$USUARIO"  >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_PASSWORD=$PASSWORD" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_AUTH_URL='http://controller:5000/'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_DEFAULT_DOMAIN='Default'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_AUTH_STRATEGY='keystone'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_REGION_NAME='RegionOne'"  >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export CINDER_ENDPOINT_TYPE='internalURL'"  >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export GLANCE_ENDPOINT_TYPE='internalURL'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export KEYSTONE_ENDPOINT_TYPE='internalURL'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export NOVA_ENDPOINT_TYPE='internalURL'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export NEUTRON_ENDPOINT_TYPE='internalURL'" >> /home/sistemas/usuarios/$USUARIO'rc'
  echo "export OS_ENDPOINT_TYPE='internalURL'" >> /home/sistemas/usuarios/$USUARIO'rc'
echo -ne '( ####                                     )  (18 %)\r'

  # exportamos las variables del nuevo usuario
  source /home/sistemas/usuarios/$USUARIO'rc'
  echo_time " " >> $LOG

  # Creamos la RED y SUBRED del nuevo usuario
  echo_time "Creamos la red: RED_"$USUARIO >> $LOG
  openstack network create RED_$USUARIO &> /dev/null
  NET_ID=$(openstack network list | grep RED_$USUARIO | awk '{print $2}')
echo -ne '( ####                                     )  (20 %)\r'  
  echo_time "Direccionamiento: 10.1.1.0/24" >> $LOG
  echo_time "DNS Público: 8.8.8.8" >> $LOG
  echo_time " " >> $LOG
  openstack subnet create SUBRED_$USUARIO --network RED_$USUARIO --subnet-range 10.0.0.0/24 --dns-nameserver 8.8.8.8 &> /dev/null
  SUBNET_ID=$(openstack subnet list | grep SUBRED_$USUARIO | awk '{print $2}')
echo -ne '( #####                                    )  (22 %)\r'
  # Creamos el ROUTER del nuevo usuario
  echo_time "Creamos router: ROUTER_"$USUARIO >> $LOG
  openstack router create ROUTER_$USUARIO &> /dev/null
  
  ROUTER_ID=$(openstack router list |grep ROUTER_$USUARIO |awk '{print $2}')
  QROUTER='qrouter-'$ROUTER_ID
echo -ne '( ######                                   )  (24 %)\r'
  echo_time " " >> $LOG
  echo_time "qrouter creado :" $QROUTER >> $LOG

  # Conectamos el router a la red publica y a la interna
  echo_time " " >> $LOG
  echo_time "Creamos Gateway y conectamos a la red Publica." >> $LOG
  openstack router set ROUTER_$USUARIO --external-gateway provider &> /dev/null
  openstack router add subnet ROUTER_$USUARIO SUBNET_$USUARIO &> /dev/null
  
  echo_time " " >> $LOG
echo -ne '( ######                                   )  (28 %)\r'

  # 
  # Buscamos la IP Publica del router
  #
  #
  source /home/sistemas/usuarios/$USUARIO'rc'
  ROUTER_IP=$(openstack router show ROUTER_$USUARIO | grep ip_address | awk '{print $12}' | cut -c 2- | sed 's/....$//')
  
  echo_time " " >> $LOG
  echo_time "IP Publica del router : " $ROUTER_IP >> $LOG
  echo_time " " >> $LOG

  #   read -p "Pulsa [Enter] para continuar..."


  # Modificamos el grupo de seguridad por defecto para el nuevo usuario. Hay que hacerlo como Admin
  source /home/sistemas/admin_openrc
  SECGROUP_ID=$(openstack security group list | grep $PROJECTID | grep default | awk '{print $2}')
echo -ne '( #####                                    )  (30 %)\r'
  echo_time "Añadimos RDP y SSH a las reglas por defecto del usuario:" >> $LOG
  echo_time " " >> $LOG
  openstack security group rule list $SECGROUP_ID | awk '{print $2}' | sed -e '1,3d' | head -n -1 > rules.txt
  while read ruleid; do
    openstack security group rule delete $ruleid
  done < /home/sistemas/rules.txt
  # rm /home/sistemas/rules.txt
echo -ne '( ######                                   )  (34 %)\r'
  # Creamos las 2 reglas básicas de entrada 22 y 3389
  openstack security group rule create --proto tcp --dst-port 3389 --src-ip 0.0.0.0/0 $SECGROUP_ID &> /dev/null
  echo_time "          Entrante: 3389 (RDP)" >> $LOG
  openstack security group rule create --proto tcp --dst-port 22 --src-ip 0.0.0.0/0 $SECGROUP_ID &> /dev/null
  echo_time "          Entrante: 22 (SSH)" >> $LOG
echo -ne '( #########                                )  (38 %)\r'
  # rm /home/sistemas/lista_usuarios.txt
  # rm /home/sistemas/lista_proyectos.txt

else
  # Al poner el parámetro -w saltamos aqui y sacamos todos los datos referentes a este usuario.
  # Tenemos que sacar: usuario, proyecto, rol, red, subred, routerid, qrouter, y publica del router, 
  echo_time " " >> $LOG
  echo_time "Parámetro -w detectado. Omitimos comprobación de usuario..." >> $LOG
  echo_time "CONTINUAMOS PARA BINGO...!" >> $LOG
  echo_time " " >> $LOG
  echo_time "Sacamos las variables necesarias..." >> $LOG
  echo_time " " >> $LOG
  echo_time "USUARIO: " $USUARIO >> $LOG
  echo_time "PASSWORD: "$PASSWORD >> $LOG
  echo_time "PROYECTO: "$PROYECTO >> $LOG
  echo_time "ROL: "$ROL >> $LOG
  echo_time "RED: " 'RED_'$USUARIO >> $LOG 
  echo_time "SUBRED: " 'SUBRED_'$USUARIO >> $LOG
  source /home/sistemas/usuarios/$USUARIO'rc'
  NET_ID=$(openstack network list | grep RED_$USUARIO | awk '{print $2}')
  echo_time "NET_ID: " $NET_ID >> $LOG
  SUBNET_ID=$(openstack subnet list | grep SUBNET_$USUARIO | awk '{print $2}')
  echo_time "SUBNET_ID: " $SUBNET_ID >> $LOG
  ROUTER_ID=$(openstack router list |grep ROUTER_$USUARIO |awk '{print $2}')
  echo_time "ROUTER_ID: " $ROUTER_ID >> $LOG
  QROUTER='qrouter-'$ROUTER_ID
  echo_time "QROUTER_ID: " $QROUTER >> $LOG
  source /home/sistemas/usuarios/$USUARIO'rc'
  ROUTER_IP=$(openstack router show $ROUTER_ID | grep ip_address | awk '{print $12}' | cut -c 2- | sed 's/....$//')
  echo_time "ROUTER IP: "$ROUTER_IP >> $LOG
  read -p "Pulsa  [Enter] para continuar: " userInput
fi

echo -ne '( #########                                )  (42 %)\r'
#--------------------------------------------------------------
#             Comenzamos a crear la instancia
#--------------------------------------------------------------
# clear

echo_time " "  >> $LOG
echo_time "Creación de la VM" >> $LOG
echo_time "-----------------" >> $LOG
echo_time " " >> $LOG
# USUARIO=$1

# read -p "Usuario que va crear la instancia...: " USUARIO
# INSTANCE_NAME=$INSTANCIA

# FLAVOR_ID=$(openstack flavor list | grep $TIPO | awk '{print $2}')

#
# CREACION DE MAQUINA WINDOWS
# ===========================

if [ $SISTEMA == "Windows" ] || [ $SISTEMA = "windows" ];
  then
    source /home/sistemas/admin_openrc
    IMAGE_ID=$(openstack image list | grep Windows | awk '{print $2}')
    echo_time "Generando Sistema: Windows Server 2012 R2"  >> $LOG
    FLAVOR_ID=$(openstack flavor list | grep $TIPO | awk '{print $2}')
    source /home/sistemas/usuarios/$USUARIO'rc'
echo -ne '( #############                            )  (45 %)\r'
openstack server create --flavor $FLAVOR_ID --image $IMAGE_ID --nic net-id=$NET_ID --security-group default $INSTANCIA &> /dev/null
 
echo -ne '( ###############                          )  (48 %)\r'
#   FLOATING_IP=$(nova floating-ip-create | awk '{print $4}' | sed -e '1,3d' | head -n -1)
    INSTANCE_ID=$(openstack server list | grep $INSTANCIA | awk '{print $2}')
#   nova floating-ip-associate $INSTANCE_ID $FLOATING_IP &> /dev/null
    echo_time "Máquina : " $INSTANCIA ", CREADA...!" >> $LOG
    echo_time " " >> $LOG

    sleep 2
echo -ne '( ###########################              )  (52 %)\r'
    #
    #--------
    #  Sacamos el interfaz del router desde el nodo que lo gestiona
    #--------

    # ROUTER_IFACE=$(ip netns exec $QROUTER ip a |grep qg- | awk '{print $2}' | sed 's/.$//')
    ROUTER_IFACE=$(ip netns exec $QROUTER ip a |grep qg- | grep -v "scope global" | awk '{print $2}' | sed 's/.$//')
echo -ne '( ############################             )  (58 %)\r'
    #
    #-------
    #  Sacamos la IP de la máquina virtual recien creada 
    #-------

    #source /home/sistemas/admin_openrc
    VMIP=$(openstack server show $INSTANCE_ID | grep RED_$USUARIO | awk {'print $4'} | sed 's/^.*=//')
    LAST_OCTET=$(echo $ROUTER_IP | cut -d"." -f4)
echo -ne '( ################################         )  (64 %)\r'
    #
    #--------
    #  Ejecutamos las reglas en los routers
    #--------
    echo_time "===================================" >> $LOG
    echo_time "Revisamos VARIABLES:" >> $LOG
    echo_time " " >> $LOG
    echo_time "==================================="  >> $LOG
    echo_time " "  >> $LOG
    echo_time "USUARIO: " $USUARIO  >> $LOG
    echo_time " " >> $LOG
    echo_time "INSTANCIA: " $INSTANCIA  >> $LOG
    echo_time " " >> $LOG
    echo_time "IP Instancia: " $VMIP >> $LOG
    echo_time " " >> $LOG
    echo_time "Router completo: " $QROUTER  >> $LOG
    echo_time " " >> $LOG
    echo_time "Router IP: " $ROUTER_IP  >> $LOG
    echo_time " "  >> $LOG
    echo_time " "  >> $LOG
    echo_time "Router Interface: " $ROUTER_IFACE  >> $LOG
    echo_time " " >> $LOG
    echo_time "IP Pública: 194.30.84."$LAST_OCTET >> $LOG
    echo_time " " >> $LOG
    echo_time " " >> $LOG
    echo_time "====================================" >> $LOG
echo -ne '( ###################################      )  (75 %)\r'
    sleep 20
echo -ne '( ######################################## )  (95 %)\r'

    echo_time " " >> $LOG
    echo_time " Reglas Iptables creadas en el Router " >> $LOG
    echo_time "--------------------------------------" >> $LOG
echo -ne '(                OK                        )  (100 %)\r'
#
# CREAMOS MAQUINA UBUNTU
# ======================

  elif [ $SISTEMA == "Ubuntu" ] || [ $SISTEMA == "ubuntu" ];
  then
    source /home/sistemas/admin_openrc
    IMAGE_ID=$(openstack image list | grep "Ubuntu 16" | awk '{print $2}')
    echo_time "Generando Sistema: Ubuntu Server 16.04 x64" >> $LOG
    FLAVOR_ID=$(openstack flavor list | grep $TIPO | awk '{print $2}')
    source /home/sistemas/usuarios/$USUARIO'rc'
    nova keypair-add $USUARIO'_ubuntu_key' >> /home/sistemas/usuarios/$USUARIO'_ubuntu_key_'$FECHA'.pem'
    chmod 600 /home/sistemas/usuarios/$USUARIO'_ubuntu_key_'$FECHA'.pem'
    #openstack server create --flavor $FLAVOR_ID --image $IMAGE_ID --nic net-id=$NET_ID --security-group default --key-name $USUARIO'_ubuntu_key' $INSTANCIA &> /dev/null
openstack server create --flavor $FLAVOR_ID --image $IMAGE_ID --nic net-id=$NET_ID --security-group default --key-name $USUARIO'_ubuntu_key' $INSTANCIA
    INSTANCE_ID=$(openstack server list | grep $INSTANCIA | awk '{print $2}')
    echo_time "Máquina " $INSTANCIA " creada..!" >> $LOG
    echo_time " " >> $LOG

#  Esperamos 10 segundos para que nos asigne el DHCP la IP privada
    sleep 10

#  Sacamos el interfaz del router desde el nodo que lo gestiona
    ROUTER_IFACE=$(ip netns exec $QROUTER ip a |grep qg- | grep -v "scope global" | awk '{print $2}' | sed 's/.$//')

#  Sacamos la IP de la máquina virtual recien creada
    #source /home/sistemas/admin_openrc
    VMIP=$(openstack server show $INSTANCE_ID | grep RED_$USUARIO | awk {'print $4'} | sed 's/^.*=//')
    LAST_OCTET=$(echo $ROUTER_IP | cut -d"." -f4)

echo_time "===================================" >> $LOG
echo_time "Revisamos VARIABLES:" >> $LOG
echo_time " " >> $LOG
echo_time "==================================="  >> $LOG
echo_time " "  >> $LOG
echo_time "USUARIO: " $USUARIO  >> $LOG
echo_time " " >> $LOG
echo_time "INSTANCIA: " $INSTANCIA  >> $LOG
echo_time " " >> $LOG
echo_time "IP Instancia: " $VMIP >> $LOG
echo_time " " >> $LOG
echo_time "Router completo: " $QROUTER  >> $LOG
echo_time " " >> $LOG
echo_time "Router IP: " $ROUTER_IP  >> $LOG
echo_time " "  >> $LOG
echo_time " "  >> $LOG
echo_time "Router Interface: " $ROUTER_IFACE  >> $LOG
echo_time " " >> $LOG
echo_time " " >> $LOG
echo_time "IP Pública resultante....: 194.30.84."$LAST_OCTET >> $LOG
echo_time " " >> $LOG
echo_time "====================================" >> $LOG

#Creamos las reglas para permitir al puerto 22

#ssh node-1 "ip netns exec $QROUTER iptables -t nat -I PREROUTING -i $ROUTER_IFACE -p tcp --dport 22 -j DNAT --to-destination $VM_IP" &> /dev/null  
#ssh node-2 "ip netns exec $QROUTER iptables -t nat -I PREROUTING -i $ROUTER_IFACE -p tcp --dport 22 -j DNAT --to-destination $VM_IP" &> /dev/null

echo_time " " >> $LOG
echo_time " Reglas Iptables creadas en el Router " >> $LOG
echo_time " " >> $LOG


#
# CREAMOS MAQUINA CENTOS
# ======================

  elif [ $SISTEMA == "Centos" ] || [ $SISTEMA == "centos" ];
  then
    source /home/sistemas/admin_openrc
    IMAGE_ID=$(openstack image list | grep "CentOS7" | awk '{print $2}')
    echo_time "Generando Sistema: Ubuntu Server 16.04 x64" >> $LOG
    FLAVOR_ID=$(openstack flavor list | grep $TIPO | awk '{print $2}')
    source /home/sistemas/usuarios/$USUARIO'rc'
    nova keypair-add $USUARIO'_centos_key' >> /home/sistemas/usuarios/$USUARIO'_centos_key_'$FECHA'.pem'
    chmod 600 /home/sistemas/usuarios/$USUARIO'_centos_key_'$FECHA'.pem'
    #openstack server create --flavor $TIPOID --image $SISTEMA_ID --key-name $USUARIO'_centos_key' $INSTANCIA &> /dev/null
openstack server create --flavor $FLAVOR_ID --image $IMAGE_ID --nic net-id=$NET_ID --security-group default --key-name $USUARIO'_ubuntu_key' $INSTANCIA >> $LOG
INSTANCE_ID=$(openstack server list | grep $INSTANCIA | awk '{print $2}')
    echo_time "Máquina " $INSTANCIA " creada..!" >> $LOG
    echo_time " " >> $LOG

#  Esperamos 10 segundos para que nos asigne el DHCP la IP privada
    sleep 10

#  Sacamos el interfaz del router desde el nodo que lo gestiona
    ROUTER_IFACE=$(ip netns exec $QROUTER ip a |grep qg- | grep -v "scope global" | awk '{print $2}' | sed 's/.$//')
   
#  Sacamos la IP de la máquina virtual recien creada
    source /home/sistemas/admin_openrc
    VMIP=$(openstack server show $INSTANCE_ID | grep RED_$USUARIO | awk {'print $4'} | sed 's/^.*=//')
    LAST_OCTET=$(echo $ROUTER_IP | cut -d"." -f4)

#  Ejecutamos las reglas en los routers

echo_time "===================================" >> $LOG
echo_time "Revisamos VARIABLES:" >> $LOG
echo_time " " >> $LOG
echo_time "==================================="  >> $LOG
echo_time " "  >> $LOG
echo_time "USUARIO: " $USUARIO  >> $LOG
echo_time " " >> $LOG
echo_time "INSTANCIA: " $INSTANCIA  >> $LOG
echo_time " " >> $LOG
echo_time "IP Instancia: " $VMIP >> $LOG
echo_time " " >> $LOG
echo_time "Router completo: " $QROUTER  >> $LOG
echo_time " " >> $LOG
echo_time "Router IP: " $ROUTER_IP  >> $LOG
echo_time " "  >> $LOG
echo_time " "  >> $LOG
echo_time "Router Interface: " $ROUTER_IFACE  >> $LOG
echo_time " " >> $LOG
echo_time " " >> $LOG
echo_time "IP Pública resultante....: 194.30.84."$LAST_OCTET >> $LOG
echo_time " " >> $LOG
echo_time "====================================" >> $LOG

# Creamos las reglas para permitir al puerto 22

#ssh node-1 "ip netns exec $QROUTER iptables -t nat -I PREROUTING -i $ROUTER_IFACE -p tcp --dport 22 -j DNAT --to-destination $VM_IP" &> /dev/null  
#ssh node-2 "ip netns exec $QROUTER iptables -t nat -I PREROUTING -i $ROUTER_IFACE -p tcp --dport 22 -j DNAT --to-destination $VM_IP" &> /dev/null

echo_time " " >> $LOG
echo_time " Reglas Iptables creadas en el Router " >> $LOG
echo_time " " >> $LOG

    elif [ $SISTEMA <> "1" ] || [ $SISTEMA <> "2" ];
    then
        echo "No entiendo el SISTEMA. Vuelve a leer las instrucciones..."
        exit 0
fi
echo -ne '( ######################################## )  (100 %)\r'
echo " "
echo_time " " >> $LOG
echo_time "Proceso Terminado" >> $LOG
echo_time "=================" >> $LOG
echo_time "=================" >> $LOG
echo_time "=================" >> $LOG
echo_time " " >> $LOG
echo_time " " >> $LOG
echo_time " " >> $LOG

rm /home/sistemas/lista_usuarios.txt  &> /dev/null
rm /home/sistemas/lista_proyectos.txt  &> /dev/null
