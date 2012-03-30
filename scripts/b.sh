clear
export PATH=~/Code/binutils-2.22/install/bin/:$PATH
echo "Source"
echo "------"
cat test.c
echo "------"
rm test.elf test.s
~/Code/llvm/Debug+Asserts/bin/clang -ccc-host-triple avr-pc-linux-gnu test.c -o test.elf -v -mavrxmega5 -O4
echo "Disassembly"
echo "----------"
echo avr-objdump -d test.elf
avr-objdump -d test.elf
echo "----------"

#/home/saaadhu/Code/llvm/Debug+Asserts/bin/llc test.ll -march=avr -mtriple=avr -print-after-all -view-dag-combine1-dags 2>&1 > op
#/home/saaadhu/Code/llvm/Debug+Asserts/bin/llc test.ll -march=avr -mtriple=avr 2>&1 > op
#cat op
#/home/saaadhu/Code/binutils-2.22/install/bin/avr-as test.s -o test.elf
#/home/saaadhu/Code/binutils-2.22/install/bin/avr-objdump -d test.elf
~
~
~
~
~

