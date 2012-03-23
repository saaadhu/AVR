#Checkout LLVM
git clone http://llvm.org/git/llvm.git
cd llvm
git checkout -f 859c645310f37f4b5e93a9802ee4ffd0d6bb58f2

#Checkout clang
cd tools
git clone http://llvm.org/git/clang.git
cd clang
git checkout -f dd4b35

cd ../../lib/Target

#Checkout the AVR port
git clone git@github.com:saaadhu/AVR.git

cd ../../
# Patch llvm
patch -p1 < lib/Target/AVR/patch.diff

cd tools/clang
# Patch clang
patch -p1 < ../../lib/Target/AVR/clang_patch.diff


#Download GNU binutils for AVR
wget http://ftp.gnu.org/gnu/binutils/binutils-2.22.tar.bz2

#Extract binutils and build
tar -xvf binutils-2.22.tar.bz2 -C .
cd binutils-2.22
mkdir build install
cd build
../configure --prefix=`pwd`/../install --target=avr --disable-nls
make && make install
