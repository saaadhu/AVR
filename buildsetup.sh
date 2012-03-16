#Checkout LLVM
git clone http://llvm.org/git/llvm.git
cd llvm
git checkout 859c645310f37f4b5e93a9802ee4ffd0d6bb58f2

#Checkout clang
cd tools
git clone http://llvm.org/git/clang.git
git checkout dd4b350143c26c030a482f091908a2e077503411O

cd ../lib/Target

#Checkout the AVR port
git clone git@github.com:saaadhu/AVR.git

cd ../../
# Patch llvm
patch -p1 < lib/Target/AVR/patch.diff

# Patch clang
patch -p1 < lib/Target/AVR/clang_patch.diff


