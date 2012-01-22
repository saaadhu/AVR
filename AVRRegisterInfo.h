//===- AVRRegisterInfo.h - AVR Register Information Impl --*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the AVR implementation of the MRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TARGET_AVRREGISTERINFO_H
#define LLVM_TARGET_AVRREGISTERINFO_H

#include "llvm/Target/TargetRegisterInfo.h"

#define GET_REGINFO_HEADER
#include "AVRGenRegisterInfo.inc"

namespace llvm {

class TargetInstrInfo;
class AVRTargetMachine;

struct AVRRegisterInfo : public AVRGenRegisterInfo {
private:
  AVRTargetMachine &TM;
  const TargetInstrInfo &TII;

  /// StackAlign - Default stack alignment.
  ///
  unsigned StackAlign;
public:
  AVRRegisterInfo(AVRTargetMachine &tm, const TargetInstrInfo &tii);

  /// Code Generation virtual methods...
  const unsigned *getCalleeSavedRegs(const MachineFunction *MF = 0) const;

  BitVector getReservedRegs(const MachineFunction &MF) const;
  const TargetRegisterClass* getPointerRegClass(unsigned Kind = 0) const;

  void eliminateCallFramePseudoInstr(MachineFunction &MF,
                                     MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator I) const;

  void eliminateFrameIndex(MachineBasicBlock::iterator II,
                           int SPAdj, RegScavenger *RS = NULL) const;

  void processFunctionBeforeFrameFinalized(MachineFunction &MF) const;

  // Debug information queries.
  unsigned getFrameRegister(const MachineFunction &MF) const;
};

} // end namespace llvm

#endif // LLVM_TARGET_AVRREGISTERINFO_H
