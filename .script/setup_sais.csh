#User need to set <tool_installation> to user's tool path


echo "Sourcing Xcelium license"
setenv XLMHOME /grid/avs/install/xcelium/2503/25.03.001

echo "Sourcing vManager license to lauch IMC tool"
setenv VMGRHOME /grid/avs/install/vmanager/2503/25.03.001

echo "Sourcing Modus License"
setenv MODHOME /icd/flow/MODUS/MODUS251/25.10.000

echo "Sourcing Conformal License"
setenv CNFRLHOME /icd/flow/CONFRML/CONFRML251/25.10.100

echo "Sourcing DDI Genus License"
setenv DDIGENUS /icd/flow/DDI/DDI251/25.10-p002_1/GENUS251
 
echo "Sourcing DDI Innovus License"
setenv DDIINV /icd/flow/DDI/DDI251/25.10-p002_1/INNOVUS251

echo "Sourcing SSVHOME License"
setenv SSVHOME /icd/flow/SSV/SSV251/25.10-p001_1

set path = ( $XLMHOME/tools/bin \
             $VMGRHOME/bin \
             $MODHOME/lnx86/tools.lnx86/bin   \
             $CNFRLHOME/lnx86/tools.lnx86/bin \
	     $DDIGENUS/tools.lnx86/bin \
	     $DDIINV/tools.lnx86/bin \
	     $SSVHOME/lnx86/tools.lnx86/bin \
             $path )

foreach t ( xrun imc modus genus lec innovus tempus) 
   echo "Found $t at `which $t`"
end

#

