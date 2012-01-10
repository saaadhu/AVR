//==-- AVR.h - Top-level interface for AVR representation --*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM AVR backend.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TARGET_AVR_H
#define LLVM_TARGET_AVR_H

#include "MCTargetDesc/AVRMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
  class AVRTargetMachine;
  class FunctionPass;
  class formatted_raw_ostream;

  //FunctionPass *createMSP430ISelDag(MSP430TargetMachine &TM,
  //                                  CodeGenOpt::Level OptLevel);

  //FunctionPass *createMSP430BranchSelectionPass();

} // end namespace llvm;

#endif
