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

namespace AVRCC {
  // AVR specific condition code.
  enum CondCodes {
    COND_E  = 0,  
    COND_NE = 1,  
    COND_HS = 2,  
    COND_LO = 3,  
    COND_GE = 4,
    COND_L  = 5,

    COND_INVALID = -1
  };
}

namespace llvm {
  class AVRTargetMachine;
  class FunctionPass;
  class formatted_raw_ostream;

  FunctionPass *createAVRISelDag(AVRTargetMachine &TM,
                                    CodeGenOpt::Level OptLevel);

  //FunctionPass *createAVRBranchSelectionPass();

} // end namespace llvm;

#endif
