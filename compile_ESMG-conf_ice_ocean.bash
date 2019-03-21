#!/bin/bash

MOM6_installdir=/home/dujuan/ESMG-configs-180731
MOM6_rundir=/t1/scratch/dujuan/ESMG/NWA

#---------------------------------------------------------------
# use new modules that point to /t1

. /usr/share/Modules/init/bash

module load gcc/4.8.2
module load netcdf/4.3.0-gcc4.8.2
module load openmpi/1.8.5_gcc4.8.2

cd $MOM6_rundir

# Create blanl env file
#rm -Rf $MOM6_rundir/build/gnu/shared/repro/
mkdir -p build/gnu/shared/repro/
echo > build/gnu/env

mkdir -p build/mkmf/templates
cp -r $MOM6_installdir/src/mkmf/bin $MOM6_rundir/build/mkmf/bin
cp $MOM6_installdir/src/mkmf.local/triton.mk $MOM6_rundir/build/mkmf/templates

compile_fms=1
compile_mom=1

if [ $compile_fms == 1 ] ; then

   rm -Rf build/gnu/shared/repro/
   mkdir -p build/gnu/shared/repro/
   (cd build/gnu/shared/repro/; rm -f path_names; \
   $MOM6_rundir/build/mkmf/bin/list_paths $MOM6_installdir/src/FMS; \
   $MOM6_rundir/build/mkmf/bin/mkmf -t $MOM6_rundir/build/mkmf/templates/triton.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF -DSPMD" path_names)
#   $MOM6_rundir/build/mkmf/bin/mkmf -t $MOM6_rundir/build/mkmf/templates/linux-gnu.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF -DSPMD" path_names)

#   (cd build/gnu/shared/repro/; source ../../env; make NETCDF=3 DEBUG=1 FC=mpif90 CC=mpicc libfms.a -j 6)
   (cd build/gnu/shared/repro/; source ../../env; make NETCDF=3 REPRO=1 FC=mpif90 CC=mpicc libfms.a -j 6)

fi


################ When compiling MOM6-SISE2 coupled model ####################

cd $MOM6_rundir

if [ $compile_mom == 1 ] ; then

    rm -Rf build/gnu/ice_ocean_SIS2/repro/
mkdir -p build/gnu/ice_ocean_SIS2/repro/
mkdir -p build/mkmf/bin/list_paths/
    (cd build/gnu/ice_ocean_SIS2/repro/; rm -f path_names; \
    $MOM6_rundir/build/mkmf/bin/list_paths ./ $MOM6_installdir/src/MOM6/config_src/{dynamic_symmetric,coupled_driver} $MOM6_installdir/src/MOM6/src/{*,*/*}/ $MOM6_installdir/src/{atmos_null,coupler,land_null,ice_ocean_extras,icebergs,SIS2,FMS/coupler,FMS/include}/)
    (cd build/gnu/ice_ocean_SIS2/repro/; \
   $MOM6_rundir/build/mkmf/bin/mkmf -t $MOM6_rundir/build/mkmf/templates/triton.mk -o '-I../../shared/repro' -p 'MOM6 -L../../shared/repro -lfms' -c '-Duse_libMPI -Duse_netCDF -DSPMD -DUSE_LOG_DIAG_FIELD_INFO -D_USE_LEGACY_LAND_ -Duse_AM3_physics' path_names )

#    (cd build/gnu/ice_ocean_SIS2/repro/; source ../../env; make NETCDF=4 DEBUG=1 MOM6 -j 6)

    (cd build/gnu/ice_ocean_SIS2/repro/; source ../../env; make NETCDF=3 REPRO=1 MOM6 -j 6)

fi


