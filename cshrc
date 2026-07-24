#User need to set <tool_installation> to user's tool path


echo "Sourcing Xcelium license"
setenv XLMHOME <tool_installation>/xcelium/2503/25.03.001

echo "Sourcing vManager license to lauch IMC tool"
setenv VMGRHOME <tool_installation>/vmanager/2503/25.03.001

echo "Sourcing Modus License"
setenv MODHOME <tool_installation>/MODUS251/25.10.000

echo "Sourcing Conformal License"
setenv CNFRLHOME <tool_installation>/CONFRML251/25.10.100

echo "Sourcing DDI221 for Genus License"
setenv DDI_GENUS  <tool_installation>/DDI251/25.10-p002_1/GENUS251

echo "Sourcing DDI221 for Innovus License"
setenv DDI_INNOVUS  <tool_installation>/DDI251/25.10-p002_1/INNOVUS251

echo "Sourcing SSVHOME License"
setenv SSVHOME  <tool_installation>/SSV251/25.10-p001_1

 set path = ($XLMHOME/tools/bin \
             $VMGRHOME/bin \
             $MODHOME/lnx86/tools.lnx86/bin   \
             $CNFRLHOME/lnx86/tools.lnx86/bin \
	     $DDI_GENUS/tools.lnx86/bin \
	     $DDI_INNOVUS/tools.lnx86/bin \
	     $SSVHOME/lnx86/tools.lnx86/bin \
             $path )

foreach t ( xrun imc modus genus lec innovus tempus) 
   echo "Found $t at `which $t`"
end

#

