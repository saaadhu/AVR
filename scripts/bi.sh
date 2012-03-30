clear
export PATH=~/Code/binutils-2.22/install/bin/:$PATH
echo "Source"
echo "------"
cat test.c
echo "------"
rm test.elf test.s
~/Code/llvm/Debug+Asserts/bin/clang -ccc-host-triple avr-pc-linux-gnu test.c -o test.elf -v -mavrxmega5 -o test.ll -O3
cat test.ll
