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


# Colors:
#
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
export BLUE='\033[01;34m'  # Blue
