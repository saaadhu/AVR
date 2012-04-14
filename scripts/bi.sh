clear
export PATH=~/Code/binutils-2.22/install/bin/:$PATH
echo "Source"
echo "------"
cat test.c
echo "------"
rm test.elf test.s test.o test.ll
~/Code/llvm/Debug+Asserts/bin/clang -ccc-host-triple avr-pc-linux-gnu -S test.c -o test.ll -v -mavrxmega5 -O4 
echo "Running llc"
echo "------"
~/Code/llvm/Debug+Asserts/bin/llc -march=avr -mtriple=avr test.ll -o test.s 
avr-as test.s -o test.o -mmcu=atxmega128a1
avr-ld test.o -o test.elf -mavrxmega7 -e test
echo "Disassembly"
echo "----------"
echo avr-objdump -d test.elf
avr-objdump -d test.elf
echo "----------"
cp test.elf ~/llvmoutput
