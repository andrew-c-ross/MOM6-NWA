#!/bin/bash

MOM6_installdir=/lustre/f2/dev/gfdl/Andrew.C.Ross/git/MOM6-examples
MOM6_rundir=/lustre/f2/dev/gfdl/Andrew.C.Ross/git/MOM6-NWA

MKMF_dir=$MOM6_installdir/src/mkmf
FMS_dir=$MOM6_installdir/src/FMS

module unload PrgEnv-pgi
module unload PrgEnv-pathscale
module unload PrgEnv-intel
module unload PrgEnv-gnu
module unload PrgEnv-cray

module load PrgEnv-intel
module swap intel intel/16.0.3.210
module unload netcdf
module load cray-netcdf
module load cray-hdf5

cd $MOM6_rundir

# Create blank env file
mkdir -p build/intel/shared/repro/
echo > build/intel/env

mkdir -p build/mkmf/templates
cp -r $MKMF_dir/bin $MOM6_rundir/build/mkmf/bin
cp $MKMF_dir/templates/ncrc-intel.mk $MOM6_rundir/build/mkmf/templates

compile_fms=1
compile_mom=1

if [ $compile_fms == 1 ] ; then
    rm -rf build/intel/shared/repro/
    mkdir -p build/intel/shared/repro/
    cd build/intel/shared/repro/
    rm -f path_names
    $MOM6_rundir/build/mkmf/bin/list_paths $FMS_dir
    $MOM6_rundir/build/mkmf/bin/mkmf -t $MOM6_rundir/build/mkmf/templates/ncrc-intel.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF -DSPMD" path_names
    source ../../env
    make NETCDF=3 REPRO=1 libfms.a -j 2
fi


################ When compiling MOM6-SISE2 coupled model ####################

cd $MOM6_rundir

if [ $compile_mom == 1 ] ; then

    rm -rf build/intel/ice_ocean_SIS2/repro/
    mkdir -p build/intel/ice_ocean_SIS2/repro/
    mkdir -p build/mkmf/bin/list_paths/
    cd build/intel/ice_ocean_SIS2/repro/
    rm -f path_names
    $MOM6_rundir/build/mkmf/bin/list_paths ./ $MOM6_installdir/src/MOM6/config_src/{dynamic_symmetric,coupled_driver} $MOM6_installdir/src/MOM6/src/{*,*/*}/ $MOM6_installdir/src/{atmos_null,coupler,land_null,ice_ocean_extras,icebergs,SIS2,FMS/coupler,FMS/include}/ 
    $MOM6_rundir/build/mkmf/bin/mkmf -t $MOM6_rundir/build/mkmf/templates/ncrc-intel.mk -o '-I../../shared/repro' -p 'MOM6 -L../../shared/repro -lfms' -c '-Duse_libMPI -Duse_netCDF -DSPMD -DUSE_LOG_DIAG_FIELD_INFO -D_USE_LEGACY_LAND_ -Duse_AM3_physics' path_names
    source ../../env
    make NETCDF=3 REPRO=1 MOM6 -j 2
fi


