#!/bin/bash

# Definição de variáveis globais
vermelho="\033[0;31m"
normal="\033[0m"
domain="@example.com"

function PrintUsage(){
        echo "Script para remover e-mails abusivos de ciaxas de usuários."
        echo 'Uso: removeAbuso.sh -r <remetente> -f <arquivo/com/os/destinatários> [-s ""Título entre aspas" -d "eexpressão de data""] -h'
        echo './removeAbuso.sh -r sandman@example.com -f "/tmp/afetados.txt" -d "after:15/11/2019"'
   exit 1
}

function Ajuda(){
echo '------------------
Uso:
------------------
./removeAbuso.sh -r <remetente> -f <arquivo/com/os/destinatários> -s "Título entre aspas" --
d "expressão de data" -h
------------------
Opções:
------------------
     -r define o usuário que enviou a mensagem (remetente). Se for no domínio interno, não é necessário o sufixo @example.com. Este campo é obrigatório.
     -f arquivo texto que contém somente os endereços dos destinatários. Este campo é obrigatório.
     -s define o cabeçalho da mensagem procurada. Este campo é opcional.
     -d define um range de datas a serem procuradas entre parenteses. Este atributo é opcional.
          Exs.:
               antes de 15 de novembro de 2019 -> "before:15/11/2019"
               depois do dia 15 de novembro: "after:15/11/2019"
               exatamente do dia 15 de novembro: "date:15/11/2019"
               entre o dia 1º e 15 de novembro: "after:1/11/2019 before:15/11/2019"
     -h Mostra um help ampliado.
------------------
Exemplo:
------------------
 ./removeAbuso.sh -r sandman@example.com -f "/tmp/afetados.txt" -d "after:15/11/2019"
'
    exit 0
}

function trataSender(){
	j=$(echo $1 | awk -F '@' '{print $2}')
	if [ -z $j ];then
		echo "$1@example.com"
	else
		echo "$1"
	fi
}

# Trata do parâmetros passados no comando
while getopts "r:s:d:f:h" OPTION;do
   case $OPTION in
      r) SENDER=$(trataSender "$OPTARG");;
      s) SUBJECT="$OPTARG";;
      d) DIA="$OPTARG";;
      f) FILE="$OPTARG";;
      h) Ajuda;;
      ?) PrintUsage;;
   esac
done

# Checa se os parâmetros obrigatórios estão presentes
if [ -z "$SENDER" ] || [ -z "$FILE" ];then
    echo "Faltam parâmetros obrigatórios!"
    PrintUsage
fi

# Checa se o arquivo com endereços existe e não está vazio
if [ ! -f "$FILE" ];then
    echo "Parece que o arquivo $FILE não existe."
    exit 1
else
    total=$(wc -l $FILE | awk '{print $1}')
    if [ $total -lt 1 ];then
        echo "Parece que o arquivo $FILE está vazio."
        exit 1
    fi
fi

# Compõe a string da pesquisa a ser passada para a mailbox
string="is:anywhere from:${SENDER}"

if [ ! -z "$DIA" ];then
    string="$string $DIA"
fi

if [ ! -z "$SUBJECT" ];then
    string="$string subject:$SUBJECT"
fi
count=1
msgCount=0
while read LINHA;do
    acct=$(trataSender $LINHA)
    echo -e "${vermelho}Conta $count/$total - ${acct}${normal}"
    echo "Buscando mensagem em $acct"
    for msg in $(/opt/zimbra/bin/zmmailbox -z -m "${acct}" s -l 999 -t message "${string}" | awk '{ if (NR!=1) {print}}' | grep -v -e Id -e "-" -e "^$" | awk '{ print $2 }');do
		echo "--->Removendo mensagem com ID ${msg} de ${acct}..."
		/opt/zimbra/bin/zmmailbox -z -m $acct dm $msg
		msgCount=$(($msgCount + 1))
	done
    count=$((count +1))
done < $FILE
echo "Apagadas $msgCount de $count mailboxes."
