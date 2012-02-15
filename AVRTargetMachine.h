//==-- AVRTargetMachine.h - Define TargetMachine for AVR ---*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the AVR specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//


#ifndef LLVM_TARGET_AVR__TARGETMACHINE_H
#define LLVM_TARGET_AVR_TARGETMACHINE_H

#include "AVRInstrInfo.h"
#include "AVRISelLowering.h"
#include "AVRFrameLowering.h"
//#include "AVRSelectionDAGInfo.h"
#include "AVRRegisterInfo.h"
#include "AVRSubtarget.h"
#include "llvm/Target/TargetData.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class AVRTargetMachine : public LLVMTargetMachine {
  AVRSubtarget		 Subtarget;
  const TargetData       DataLayout;       // Calculates type size & alignment
  AVRInstrInfo		 InstrInfo;
  AVRTargetLowering	 TLInfo;
  //AVRSelectionDAGInfo	 TSInfo;
  AVRFrameLowering	 FrameLowering;

public:
  AVRTargetMachine(const Target &T, StringRef TT,
                      StringRef CPU, StringRef FS, const TargetOptions &Options,
                      Reloc::Model RM, CodeModel::Model CM,
                      CodeGenOpt::Level OL);

  virtual const TargetFrameLowering *getFrameLowering() const {
    return &FrameLowering;
  }

  virtual const AVRInstrInfo* getInstrInfo() const  { return &InstrInfo; }
  virtual const TargetData *getTargetData() const     { return &DataLayout;}
  virtual const AVRSubtarget *getSubtargetImpl() const { return &Subtarget; }
  virtual const TargetRegisterInfo *getRegisterInfo() const {
    return &InstrInfo.getRegisterInfo();
  }
  virtual const AVRTargetLowering* getTargetLowering() const {
    return &TLInfo;
  }

  /*
  virtual const AVRSelectionDAGInfo* getSelectionDAGInfo() const {
    return &TSInfo;
  }
  */


  virtual bool addInstSelector(PassManagerBase &PM);
}; 
} // end namespace llvm

#endif // LLVM_TARGET_MSP431_TARGETMACHINE_H
