#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: run_mpassit
#
# !DESCRIPTION:
#     Script to run the MPASSIT pos-processing of MONAN model over the forecast 
#     horizon.
#     
#     Performs the following tasks:
# 
#        o Check all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#


if [ $# -ne 4 -a $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [EXP_NAME/OP] RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv_jaci_gnu.bash

echo ""
echo "---- Run Post ----"
echo ""


# Standart directories variables:---------------------------------------
DIRHOMES=$(dirname "$(pwd)");          mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/${myDIR};        mkdir -p ${DIRHOMED}  
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------

# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024042000
FCST=${4};        #FCST=40
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
VARTABLE=".OPER"
export DIRRUN=${DIRHOMED}/run.${YYYYMMDDHHi}; rm -fr ${DIRRUN}; mkdir -p ${DIRRUN}
N_MODEL_LEV=55
NLEV=18
export maxpostpernode=10     # <------ qtde max de pos por no PODE ALTERAR!
cores=${MPASSIT_ncpexec}
MODELOUTPUTDIR=${DATAOUT}/${YYYYMMDDHHi}/Model #put your MONAN dataout dir here!
MODELOUTPUTDIR=/p/projetos/monan_adm/carlos.souza/MPASSIT/MONAN/scripts_CD-CT/dataout/2026012000/Model
#-------------------------------------------------------

# Variables for flex outpout interval from streams.atmosphere------------------------
t_strout=$(cat ${SCRIPTS}/namelists/streams.atmosphere.TEMPLATE | sed -n '/<stream name="diagnostics"/,/<\/stream>/s/.*output_interval="\([^"]*\)".*/\1/p')
t_stroutsec=$(echo ${t_strout} | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
t_strouthor=$(echo "scale=4; (${t_stroutsec}/60)/60" | bc)
t_stroutmin=$(echo "${t_stroutsec}/60" | bc)
#------------------------------------------------------------------------------------

# Format to HH:MM:SS t_strout (output_interval)
IFS=":" read -r h m s <<< "${t_strout}"
printf -v t_strout "%02d:%02d:%02d" "$h" "$m" "$s"

# Calculating default parameters for different resolutions
if [ $RES -eq 1024002 ]; then  #24Km
   NLAT=721  #180/0.25
   NLON=1441 #360/0.25
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 2621442 ]; then  #15Km
   NLAT=1201 #180/0.15
   NLON=2401 #360/0.15
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 40962 ]; then  #120Km
   NLAT=150 #180/1.2
   NLON=300 #360/1.2
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 163842 ]; then  #60Km
   NLAT=301 #180/0.6
   NLON=601 #360/0.6
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 655362 ]; then  #30Km
   NLAT=601 #180/0.3
   NLON=1201 #360/0.3
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 5898242 ]; then  #10Km
   NLAT=1801 #180/0.10 (+1)
   NLON=3601 #360/0.10 (+1)
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
elif [ $RES -eq 65536002 ]; then  #3Km
   NLAT=6001 #180/0.03 
   NLON=12001 #360/0.03 
   STARTLAT=-90.0
   STARTLON=0.0
   ENDLAT=90.0
   ENDLON=360.0
fi
#-------------------------------------------------------

# Getting info part file:
 
if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ]
then
   if [ ! -s ${DATAIN}/fixed/x1.${RES}.graph.info ]
   then
      mkdir -p ${DATAIN}/fixed   
      cd ${DATAIN}/fixed
      echo -e "${GREEN}==>${NC} downloading meshes tgz files ... \n"
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}.tar.gz
      wget https://www2.mmm.ucar.edu/projects/mpas/atmosphere_meshes/x1.${RES}_static.tar.gz
      tar -xzvf x1.${RES}.tar.gz
      tar -xzvf x1.${RES}_static.tar.gz
      chmod 755 *
   fi
   echo -e "${GREEN}==>${NC} Creating x1.${RES}.graph.info.part.${cores} ... \n"
   cd ${DATAIN}/fixed
   gpmetis -minconn -contig -niter=200 x1.${RES}.graph.info ${cores}
   rm -fr x1.${RES}.tar.gz x1.${RES}_static.tar.gz
   chmod 755 *
fi

# Get some MONAN datain files:
if [ ! -d ${DATAIN}/fixed ]
then
	echo -e  "${GREEN}==>${NC} copying and linking fixed input data ${SYSTEM_KEYC}... \n"
	mkdir -p ${DATAIN}
	rsync -rv --chmod=ugo=rw ${DIRDADOS}/MONAN_datain/datain/fixed ${DATAIN}
   chmod -R u=rwx,go=rx ${DATAIN}
fi


files_needed=("${SCRIPTS}/namelists/namelist.input.TEMPLATE" "${SCRIPTS}/namelists/varlist_2d${VARTABLE}" "${SCRIPTS}/namelists/varlist_3d${VARTABLE}" "${EXECS}/mpassit" ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores})
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done


# Searching for x1.${RES}.init.nc:
# TODO: adicionar o diretorio de dados pre do GCC aqui na busca:
# First looking into default MONAN-PRE dir:
if [ -s ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ]
then
   export INIT_FILE="${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc"
elif [ -s ${DATAIN}/fixed/x1.${RES}.init.nc ]
then
   export INIT_FILE="${DATAIN}/fixed/x1.${RES}.init.nc"
elif [ -s ${MODELOUTPUTDIR}/../Pre/x1.${RES}.init.nc ]
then
   export INIT_FILE="${MODELOUTPUTDIR}/../Pre/x1.${RES}.init.nc"
else
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] File x1.${RES}.init.nc is not available. \n"
    exit -1
fi  
echo "Using ${INIT_FILE}." 

# Captura quantos arquivos do modelo tiverem para serem pos-processados e
# quando nos serao necessarios para executar ${maxpostpernode} convert_mpas por no:
#nfiles=$(ls -l ${DATAOUT}/${YYYYMMDDHHi}/Model/MONAN*nc | wc -l)
# from streams.atmosphere.TEMPLATE in diagnostics the output_interval is flexible
output_interval=${t_strouthor}
#nfiles=FCST/output_interval + 1(time zero file)
nfiles=$(echo "$FCST/$output_interval + 1" | bc)
echo "${nfiles} post to submit."
echo "Max ${maxpostpernode} submits per nodes."
echo "${cores} cores per post."
how_many_nodes ${nfiles} ${maxpostpernode}



# Cria os diretorios e arquivos/links para cada saida do MPASSIT:
cd ${DIRRUN}

for ii in $(seq 1 ${nfiles})
do
   i=$(printf "%04d" ${ii})
   mkdir -p ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/setenv_jaci_gnu.bash ${DIRRUN}/dir.${i}
   cp -f ${SCRIPTS}/namelists/varlist_2d${VARTABLE} ${DIRRUN}/dir.${i}/varlist_2d
   cp -f ${SCRIPTS}/namelists/varlist_3d${VARTABLE} ${DIRRUN}/dir.${i}/varlist_3d
   cp -f ${EXECS}/mpassit ${DIRRUN}/dir.${i} 
   
   hh=${YYYYMMDDHHi:8:2}
   currentdate=$(date -d "${YYYYMMDDHHi:0:8} ${hh}:00:00 $(echo "(${i}-1)*${t_strout:0:2}" | bc) hours $(echo "(${i}-1)*${t_strout:3:2}" | bc) minutes $(echo "(${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name=MONAN_DIAG_G_MOD_${EXP}_${YYYYMMDDHHi}_${currentdate}.x${RES}L${N_MODEL_LEV}.nc
   #echo "$diag_name"
   
   sed -e "
      s,#INITFILE#,${INIT_FILE},g;
      s,#MODELFILE#,${MODELOUTPUTDIR}/${diag_name},g;
      s,#GRAPHINFOFILE#,${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores},g;
      s,#NLAT#,${NLAT},g;
      s,#NLON#,${NLON},g;" \
      ${SCRIPTS}/namelists/namelist.input.TEMPLATE > ${DIRRUN}/dir.${i}/namelist.input

done

cd ${DIRRUN}
chmod -R 755 ${DIRRUN}/*

# Laco para criar os arquivos de submissao com os blocos de mpassit para cada node:
node=1
inicio=1   
fim=$((maxpostpernode <= nfiles ? maxpostpernode : nfiles))

while [ ${inicio} -le ${nfiles} ]
do
   rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 
#!/bin/bash
#PBS -N MPASSIT.${node}
#PBS -q ${MPASSIT_QUEUE}
#PBS -l select=1:ncpus=${MPASSIT_ncpus}:mpiprocs=${MPASSIT_ncpn}:ompthreads=${MPASSIT_nthreads}
#PBS -l walltime=${MPASSIT_walltime}
#PBS -o ${DIRRUN/lustre/p}/PostAtmos_node.${node}.o
#PBS -e ${DIRRUN/lustre/p}/PostAtmos_node.${node}.e
#PBS -l place=scatter:excl
#PBS -V

cd ${DIRRUN}
. ${SCRIPTS}/setenv_jaci_gnu.bash
chmod 755 ${DIRRUN}/*

echo "Executing posts ${inicio} to ${fim} in node Node ${node}."

cpulist1=\$(seq -s: 0 127)
cpulist2=\$(seq -s: 128 255)

for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   echo "Executing post \${i}"
   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Model/*

   if [ \$(( ii % 2 )) -eq 0 ]; then
      cpulist=\${cpulist1}
   else
      cpulist=\${cpulist2}
   fi 
     
   echo "time mpiexec -n 128 -cpu-bind=verbose,list:\${cpulist} ./mpassit namelist.input"
   time mpiexec -n 128 -cpu-bind=list:\${cpulist} ./mpassit namelist.input &
   
   
   (( ii % 2 == 0 )) && wait
   
   
   
done
# necessario aguardar as rodadas em background
wait
   
for ii in \$(seq  ${inicio} ${fim})
do
   i=\$(printf "%04d" \${ii})
   hh=${YYYYMMDDHHi:8:2}
   currentdate=\$(date -d "${YYYYMMDDHHi:0:8} \${hh}:00:00 \$(echo "(\${i}-1)*${t_strout:0:2}" | bc) hours \$(echo "(\${i}-1)*${t_strout:3:2}" | bc) minutes \$(echo "(\${i}-1)*${t_strout:6:2}" | bc) seconds" +"%Y%m%d%H.%M.%S")
   diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_\${currentdate}.x${RES}L${N_MODEL_LEV}.nc

   cd ${DIRRUN}/dir.\${i}
   chmod 755 *
   cp monan-mpassit-output.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post} & 
   echo "monan-mpassit-output.nc  ${DATAOUT}/${YYYYMMDDHHi}/Post/\${diag_name_post}"  >> mpassit.output
   
done
 
wait




EOSH
   chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh 
   cd ${DIRRUN}
   echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh ${inicio} ${fim} \n"
   jobid[${node}]=$(qsub ${DIRRUN}/PostAtmos_node.${node}.sh  | cut -d '.' -f1)

   inicio=$((fim + 1))
   temp=$((fim + maxpostpernode))
   fim=$(( temp < nfiles ? temp : nfiles ))
   node=$((node+1))
   sleep 5
done


# Dependencias JobId:
dependency="afterok"
for job_id in "${jobid[@]}"
do
   dependency="${dependency}:${job_id}"
done



# Script final , para conferir todos os arquivos, criar o template final  e apagar o diretorio DIRRUN
node=0
diag_name_post=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_${YYYYMMDDHHi}.00.00.x${RES}L${N_MODEL_LEV}.nc
diag_name_templ=MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}_%y4%m2%d2%h2.%n2.00.x${RES}L${N_MODEL_LEV}.nc

rm -f ${DIRRUN}/PostAtmos_node.${node}.sh
cat << EOSH >> ${DIRRUN}/PostAtmos_node.${node}.sh 
#!/bin/bash
#PBS -N MPASSIT.${node}
#PBS -q ${MPASSIT_QUEUE}
#PBS -l select=1:ncpus=${MPASSIT_ncpus}:mpiprocs=${MPASSIT_ncpn}:ompthreads=${MPASSIT_nthreads}
#PBS -l walltime=${MPASSIT_walltime}
#PBS -o ${DIRRUN/lustre/p}/PostAtmos_node.${node}.o
#PBS -e ${DIRRUN/lustre/p}/PostAtmos_node.${node}.e
#PBS -l place=scatter:excl
#PBS -V


cd ${DIRRUN}
. ${SCRIPTS}/setenv_jaci_gnu.bash
chmod 755 ${DIRRUN}/*

# Making template:

cd ${DIRRUN}
chmod 755 ${DATAOUT}/${YYYYMMDDHHi}/Post/*




rm -fr ${DIRRUN}/qctlinfo.gs
cat > ${DIRRUN}/qctlinfo.gs <<EOGS
'reinit'
'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}' 
'q ctlinfo'
say result
'quit'
EOGS

grads -blc "run ${DIRRUN}/qctlinfo.gs" | awk '/dset/,/endvars/' > ${DIRRUN}/qctlinfo.ctl
chmod 755 ${DIRRUN}/qctlinfo.ctl
timectl=\$(grep tdef ${DIRRUN}/qctlinfo.ctl | cut -d" " -f4)
sed -i '3a\options template' ${DIRRUN}/qctlinfo.ctl
sed -i "/tdef/c\tdef ${nfiles} linear \${timectl} ${t_stroutmin}mn" ${DIRRUN}/qctlinfo.ctl
sed -i "/dset/c\dset ^${diag_name_templ}" ${DIRRUN}/qctlinfo.ctl

chmod 755 ${DIRRUN}/*
mv ${DIRRUN}/qctlinfo.ctl ${DATAOUT}/${YYYYMMDDHHi}/Post/${diag_name_post}.template.ctl

# Saving important files to the logs directory:
cp -f ${EXECS}/MPASSIT-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post
cp -f ${EXECS}/MPASSIT-VERSION.txt ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/dir.0001/namelist.input ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f varlist_2d ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f varlist_3d ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f ${DIRRUN}/PostAtmos_node.* ${DATAOUT}/${YYYYMMDDHHi}/Post/logs

cd ${DIRRUN}/..
rm -fr ${DIRRUN}

EOSH
chmod a+x ${DIRRUN}/PostAtmos_node.${node}.sh
echo -e  "${GREEN}==>${NC} qsub PostAtmos_node.${node}.sh \n"
cd ${DIRRUN}
#qsub -W depend=${dependency} -W block=true ${DIRRUN}/PostAtmos_node.${node}.sh
 qsub -W depend=${dependency}               ${DIRRUN}/PostAtmos_node.${node}.sh







