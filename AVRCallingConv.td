//==- AVRCallingConv.td - Calling Conventions for AVR -*- tablegen -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for AVR architecture.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// AVR Return Value Calling Convention
//===----------------------------------------------------------------------===//
def RetCC_AVR : CallingConv<[
  CCIfType<[i8], CCPromoteToType<i16>>,

  // i16 are returned in registers R25, R24
  CCIfType<[i16], CCAssignToReg<[R24, R25]>>,

  // i32 are returned in registers R25, R24, R23, R22
  CCIfType<[i32], CCAssignToReg<[R22, R23, R24, R25]>>,

  // i64 are returned in registers R25, R24, R23, R22, R21, R20, R19, R18
  CCIfType<[i32], CCAssignToReg<[R18, R19, R20, R21, R22, R23, R24, R25]>>
]>;

//===----------------------------------------------------------------------===//
// AVR Argument Calling Conventions
//===----------------------------------------------------------------------===//
def CC_AVR : CallingConv<[
  // Promote i8 arguments to i16.
  CCIfType<[i8], CCPromoteToType<i16>>,

  // The first 4 integer arguments of non-varargs functions are passed in
  // integer registers.
  CCIfNotVarArg<CCIfType<[i16], CCAssignToReg<[R25, R24]>>>,

  // Integer values get stored in stack slots that are 2 bytes in
  // size and 2-byte aligned.
  CCIfType<[i16], CCAssignToStack<2, 2>>
]>;
