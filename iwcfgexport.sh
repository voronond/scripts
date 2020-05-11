cfgExportFile=/root/cfgexport.cf
rm -f "${cfgExportFile}"
orderId="$(/opt/icewarp/tool.sh get system C_License | egrep -o "<header><purchaseid>(.*)</purchaseid>" | sed -r 's|<header><purchaseid>(.*)</purchaseid>|\1|')"
superPass="$(/opt/icewarp/tool.sh get system C_Accounts_Policies_SuperUserPassword | awk '{print $2}')"
gwSuperPass="$(/opt/icewarp/tool.sh get system C_GW_SuperPass | awk '{print $2}')"
accStorageMode="$(/opt/icewarp/tool.sh get system C_System_Storage_Accounts_StorageMode | awk '{print $2}')"
mailPath="$(/opt/icewarp/tool.sh get system C_System_Storage_Dir_MailPath | awk '{print $2}')"
archivePath="$(/opt/icewarp/tool.sh get system C_System_Tools_AutoArchive_Path | awk '{print $2}')"
accDbConn="$(/opt/icewarp/tool.sh get system c_system_storage_accounts_odbcconnstring | awk '{print $2}')"
dcDbConn="$(/opt/icewarp/tool.sh get system c_accounts_global_accounts_directorycacheconnectionstring | awk '{print $2}')"
gwDbConn="$(/opt/icewarp/tool.sh get system c_gw_connectionstring | awk '{print $2}')"
asDbConn="$(/opt/icewarp/tool.sh get system c_as_challenge_connectionstring | awk '{print $2}')"
for I in orderId superPass gwSuperPass accStorageMode mailPath archivePath accDbConn dcDbConn gwDbConn asDbConn;
  do
    eval ref=\$${I};
    echo -e "${I} ${ref}" >> ${cfgExportFile};
    echo -e "${I} ${ref}";
  done
  
