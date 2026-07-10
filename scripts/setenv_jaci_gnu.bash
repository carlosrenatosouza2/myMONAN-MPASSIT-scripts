#! /bin/bash -x
#
# Author: CRS

# Load modules
module purge
module load PrgEnv-gnu
module load craype-x86-turin
module load cray-hdf5-parallel/1.14.3.3
module load cray-netcdf-hdf5parallel/4.9.0.15
module load cray-parallel-netcdf/1.12.3.15
module load xpmem/0.2.119-1.3_gef379be13330
module load cray-pals
module load METIS/5.1.0
module load grads


# NetCDF paralelo - NETCDF_DIR eh definido pelo modulo cray-netcdf-hdf5parallel
export NETCDF=${NETCDF_DIR}
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${LD_LIBRARY_PATH}

# Compiladores Cray
export CMAKE_C_COMPILER=cc
export CMAKE_Fortran_COMPILER=ftn

# ESMF compilado com NetCDF paralelo
export ESMF_DIR=/lustre/projetos/monan_adm/carlos.souza/ESMF/esmf-8.9.1
export ESMF_INCDIR=${ESMF_DIR}/src/include
export ESMF_LIBDIR=${ESMF_DIR}/lib/libO/Linux.gfortran.64.mpich2.default
export ESMF_MODDIR=${ESMF_DIR}/mod/modO/Linux.gfortran.64.mpich2.default
export ESMFMKFILE=${ESMF_DIR}/lib/libO/Linux.gfortran.64.mpich2.default/esmf.mk
export LIBRARY_PATH=${LIBRARY_PATH}:${ESMF_DIR}/lib/libO/Linux.gfortran.64.mpich2.default
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${ESMF_DIR}/lib/libO/Linux.gfortran.64.mpich2.default:${LD_LIBRARY_PATH}
export PATH=${PATH}:${ESMF_DIR}/apps/appsO/Linux.gfortran.64.mpich2.default

export ESMF_FFLAGS="-I${ESMF_MODDIR} -I${ESMF_INCDIR}"
export ESMF_LDFLAGS="-L${ESMF_LIBDIR} -lesmf"
export ESMF_COMPILER="gfortran"
export ESMF_F90COMPILER=ftn
export ESMF_CXXCOMPILER=CC
export ESMF_CCCOMPILER=cc
export ESMF_F90LINKER=ftn

# Confirma que NETCDF_DIR aponta para o paralelo
echo "NETCDF_DIR = ${NETCDF_DIR}"
echo -n "NETCDF_DIR paralelo? "
nc-config --has-parallel4




# MONAN-suite install root directories:
# Put your directories:
export DIR_SCRIPTS=$(dirname $(dirname $(pwd)))
export DIR_DADOS=${DIR_SCRIPTS}
export MPASSIT_DIR=/lustre/projetos/monan_adm/carlos.souza/MPASSIT/myMPASSIT/myMONAN-MPASSIT-scripts/sources/MPASSIT_feature/mpassit-mod2scripts-80
export myDIR=$(basename $(dirname $(pwd)))
export DIRDADOS=/p/projetos/monan_adm/monan/dados/MPASSIT_v0.1.x

# Colors:
#
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
export BLUE='\033[01;34m'  # Blue



# MPASSIT Post phase:
export MPASSIT_QUEUE="pesqextra"
export MPASSIT_ncores=256
export MPASSIT_nnodes=1
export MPASSIT_ncpus=256
export MPASSIT_ncpn=256
export MPASSIT_nthreads=1
export MPASSIT_ncpexec=128  # <------ qtde cores por mpassit NAO ALTERAR!
export MPASSIT_jobname="Post.MPASSIT"
export MPASSIT_walltime="8:00:00"





# Functions: ======================================================================================================

how_many_nodes () { 
   nume=${1}   
   deno=${2}
   num=$(echo "${nume}/${deno}" | bc -l)  
   how_many_nodes_int=$(echo "${num}/1" | bc)
   dif=$(echo "scale=0; (${num}-${how_many_nodes_int})*100/1" | bc)
   rest=$(echo "scale=0; (((${num}-${how_many_nodes_int})*${deno})+0.5)/1" | bc -l)
   if [ ${dif} -eq 0 ]; then how_many_nodes_left=0; else how_many_nodes_left=1; fi
   if [ ${how_many_nodes_int} -eq 0 ]; then how_many_nodes_int=1; how_many_nodes_left=0; rest=0; fi
   how_many_nodes=$(echo "${how_many_nodes_int}+${how_many_nodes_left}" | bc )
   #echo "INT number of nodes needed: \${how_many_nodes_int}  = ${how_many_nodes_int}"
   #echo "number of nodes left:       \${how_many_nodes_left} = ${how_many_nodes_left}"
   echo "The number of nodes needed: \${how_many_nodes}  = ${how_many_nodes}"
   echo ""
}



core_distribution() {
   # Gera a distribuicao de cores por execucao
   # $1 = total de cores do no
   # $2 = numero de cores por execucao
   
   local total_cores=$1
   local cores_per_exec=$2

   if (( total_cores % cores_per_exec != 0 )); then
      echo "ERRO: total_cores (${total_cores}) nao eh divisivel por cores_per_exec (${cores_per_exec})" >&2
      return 1
   fi

   local nexec=$(( total_cores / cores_per_exec ))

   for (( slot=0; slot<nexec; slot++ )); do
      start=$(( slot * cores_per_exec ))
      end=$(( start + cores_per_exec - 1 ))
      echo "${start} ${end}"
   done
}



#----------------------------------------------------------------------------------------------


