clear
export PATH=~/Code/binutils-2.22/install/bin/:$PATH
echo "Source"
echo "------"
cat $1
echo "------"
rm test.elf test.s
~/Code/llvm/Debug+Asserts/bin/llc -march=avr -mtriple=avr $1  -print-after-all -view-dag-combine1-dags -view-isel-dags -o test.s
avr-as test.s -o test.o -mmcu=atxmega128a1
avr-ld test.o -o test.elf -mavrxmega7 -e main
echo "Disassembly"
echo "----------"
echo avr-objdump -d test.elf
avr-objdump -d test.elf
echo "----------"
cp test.elf ~/llvmoutput

#/home/saaadhu/Code/llvm/Debug+Asserts/bin/llc test.ll -march=avr -mtriple=avr -print-after-all -view-dag-combine1-dags 2>&1 > op
#/home/saaadhu/Code/llvm/Debug+Asserts/bin/llc test.ll -march=avr -mtriple=avr 2>&1 > op
#cat op
#/home/saaadhu/Code/binutils-2.22/install/bin/avr-as test.s -o test.elf
#

