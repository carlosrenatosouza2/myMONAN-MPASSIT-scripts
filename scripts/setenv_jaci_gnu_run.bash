#!/bin/bash

# Modulos - identicos aos da compilacao
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
module load ncview

# NetCDF paralelo na frente do LD_LIBRARY_PATH
export NETCDF=${NETCDF_DIR}
export LD_LIBRARY_PATH=${NETCDF_DIR}/lib:${LD_LIBRARY_PATH}

# ESMF
export ESMF_DIR=/lustre/projetos/monan_adm/carlos.souza/ESMF/esmf-8.9.1
export LD_LIBRARY_PATH=${ESMF_DIR}/lib/libO/Linux.gfortran.64.mpich2.default:${LD_LIBRARY_PATH}
